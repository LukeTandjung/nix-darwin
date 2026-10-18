(in-package #:autolith)

;; One-way prewalk, adapted from https://github.com/lukeramsden/pi-prewalk.
;; Autolith's plan.update and resource.edit replace Pi's todo and edit/write.
;; This extension adds methods; it does not replace the native planner or tools.

(defparameter *prewalk-default-executor* "glm-5.3-fast")
(defvar *prewalk-states* (make-hash-table :test #'eq :weakness :key))
(defvar *prewalk-lock* (make-lock "Prewalk session states"))
;; Optional startup arming: AUTOLITH_PREWALK_INTO=glm-5.3-fast autolith.
(defparameter *prewalk-startup-checked-p* nil)

(defstruct prewalk-state
  "One conversation's handoff. APPLICATION is weak so closed sessions can die."
  application target (phase :armed) (plan-seen-p nil)
  (plan-injected-p nil) (continue-p t))

(defparameter *prewalk-plan-prompt*
  "Before changing code, write a concrete plan covering the remaining steps, exact targets, risks and verification. Record it with plan.update if that tool is available, then make the first implementation edit with resource.edit. The executor will inherit your plan and first edit. Stay within the user's request and ordinary permission rules. Do not modify verification assets to manufacture a pass.")
(defparameter *prewalk-continue-prompt*
  "Continue the requested implementation and verification if work remains. Do not stop at a plan alone. Respect any user pause, cancellation or approval boundary.")
(defparameter *prewalk-checklist-prompt*
  "Prewalk handoff: continue from the existing plan and first edit, without repeating completed work. Before finishing, check related call sites for consistency, keep the diff within the requested scope, and run the complete relevant test module. Report checks that could not run. This handoff grants no additional permissions.")

(defun prewalk--state (conversation)
  (with-lock-held (*prewalk-lock*)
    (gethash conversation *prewalk-states*)))

(defun prewalk--nudge (conversation text)
  "Use native next-response context: hidden nudges never enter durable history."
  (conversation-append-provider-item
   conversation (user-message-item text) :persistence :next-response))

(defun prewalk--target (agent target)
  "Prepare the selected provider without changing session or global defaults."
  (unless (and (stringp target) (plusp (length target))
               (provider-registration-for-model target))
    (error 'configuration-error :message "Prewalk requires a registered model identifier."))
  (let* ((configuration (configuration-copy (agent-configuration agent) :model target))
         (provider (provider-create configuration
                                    :registration (provider-registration-for-model target))))
    (when (and (typep provider 'openai-compatible-provider)
               (not (api-key-credential-available-p (provider-credential-manager provider))))
      (error 'configuration-error
             :message "Authenticate the prewalk executor first; no fallback model will be selected."))
    (values configuration provider)))

(defun prewalk-arm (application &optional (target *prewalk-default-executor*))
  "Arm this conversation only; the current model remains its planner."
  (let* ((agent (application-agent application))
         (conversation (agent-conversation agent))
         (existing (prewalk--state conversation)))
    (when (and existing (member (prewalk-state-phase existing) '(:armed :pending)))
      (return-from prewalk-arm existing))
    (when (planner-enabled-p (planner-settings conversation))
      (error 'configuration-error :message "Turn /planner off before arming one-way prewalk."))
    (when (equal target (config :model (agent-configuration agent)))
      (error 'configuration-error :message "The prewalk executor is already the current model."))
    (prewalk--target agent target)
    (let ((state (make-prewalk-state :application (sb-ext:make-weak-pointer application)
                                     :target target)))
      (with-lock-held (*prewalk-lock*)
        (setf (gethash conversation *prewalk-states*) state))
      state)))

(defun prewalk-disarm (conversation)
  (with-lock-held (*prewalk-lock*)
    (let ((state (gethash conversation *prewalk-states*)))
      (when state
        (setf (prewalk-state-phase state) :off)))))

(defun prewalk--note-tool (agent details)
  "Observe completed, persisted tool results, never proposed or failed edits."
  (let ((state (prewalk--state (agent-conversation agent))))
    (when (and state (eq (prewalk-state-phase state) :armed)
               (getf details :success-p))
      (let ((name (getf details :tool)))
        (cond
          ((member name '("plan.list" "plan.update") :test #'equal)
           (let ((plan (plan-load (agent-configuration agent))))
             (setf (prewalk-state-plan-seen-p state)
                   (and plan (not (null (workspace-plan-steps plan)))))))
          ((and (equal name "resource.edit")
                (or (prewalk-state-plan-seen-p state)
                    (null (tool-registry-find (agent-tool-registry agent) "plan" "update"))))
           (setf (prewalk-state-phase state) :pending)))))))

(defmethod agent-observer-status :after
    ((observer agent-observer) (status (eql :tool-call-completed)) details)
  "Completions run in wire order on the provider-loop thread after tool workers join."
  (declare (ignore observer status))
  (when (boundp '*task-unfinished-work-agent*)
    (let ((agent (symbol-value '*task-unfinished-work-agent*)))
      (when (typep agent 'agent)
        (prewalk--note-tool agent details)))))

(defun prewalk--switch (agent state)
  "Switch at the next request boundary, retaining conversation and tool results."
  (let* ((application (sb-ext:weak-pointer-value (prewalk-state-application state)))
         (conversation (agent-conversation agent)))
    (unless (and application (eq conversation (application-conversation application)))
      (setf (prewalk-state-phase state) :off)
      (return-from prewalk--switch nil))
    (multiple-value-bind (configuration provider)
        (handler-case (prewalk--target agent (prewalk-state-target state))
          (error (condition)
            (declare (ignore condition))
            ;; Stop before another paid request, preserving the planner selection.
            (setf (prewalk-state-phase state) :off)
            (error 'configuration-error
                   :message "Prewalk executor unavailable. Check authentication and /model; no fallback was selected.")))
          ;; Persist only this conversation's selection, not global preferences.
          (conversation-set-model-selection conversation
                                            (config :model configuration)
                                            (config :reasoning-effort configuration))
          (setf (agent-configuration agent) configuration
                (agent-provider agent) provider
                (application-configuration application) configuration
                (application-provider application) provider
                (application-agent application) agent
                (prewalk-state-phase state) :switched
                (prewalk-state-continue-p state) nil)
          (conversation-append-provider-item
           conversation (user-message-item *prewalk-checklist-prompt*))
          (application-refresh-context-meter application)
          (application-present application
                               (format nil "Prewalk: switched to ~A after the first successful edit."
                                       (prewalk-state-target state))))))

(defmethod agent-before-provider-request :around
    ((agent agent) (observer agent-observer))
  "Prepare the one-way handoff without replacing native planner/admission hooks."
  (when (and (not *prewalk-startup-checked-p*) *active-application*
             (eq (agent-conversation agent) (application-conversation *active-application*)))
    (setf *prewalk-startup-checked-p* t)
    (let ((target (uiop:getenv "AUTOLITH_PREWALK_INTO")))
      (when (and target (plusp (length target))
                 (null (prewalk--state (agent-conversation agent))))
        (prewalk-arm *active-application* target))))
  (let* ((conversation (agent-conversation agent))
         (state (prewalk--state conversation)))
    (when (and state (member (prewalk-state-phase state) '(:armed :pending)))
      (cond
        ((planner-enabled-p (planner-settings conversation))
         (prewalk-disarm conversation)
         (error 'configuration-error :message "Prewalk and continuous /planner cannot run together."))
        ((eq (prewalk-state-phase state) :pending)
         (prewalk--switch agent state))
        ((not (prewalk-state-plan-injected-p state))
         (prewalk--nudge conversation *prewalk-plan-prompt*)
         (setf (prewalk-state-plan-injected-p state) t)))))
  (call-next-method))

(defmethod agent-turn-complete-p :around ((agent agent) (result provider-result))
  "Allow one extra text-only reply; tool progress renews that allowance."
  (let* ((complete-p (call-next-method))
         (conversation (agent-conversation agent))
         (state (prewalk--state conversation)))
    (cond
      ((or (null state) (not (eq (prewalk-state-phase state) :armed))) complete-p)
      ((or (provider-result-tool-calls result) (provider-result-tool-search-calls result))
       (setf (prewalk-state-continue-p state) t)
       complete-p)
      ((and complete-p (prewalk-state-continue-p state))
       (setf (prewalk-state-continue-p state) nil)
       (prewalk--nudge conversation *prewalk-continue-prompt*)
       nil)
      (t complete-p))))

(define-application-command application--prewalk-command
    (:name "/prewalk"
     :argument "[MODEL|off|status]"
     :description "plan and make the first edit, then switch to the executor"
     :tip "Defaults to glm-5.3-fast. Manual, one-way, per conversation; shell commands do not trigger it."
     :busy-behavior :apply
     :terminal-behavior :shared
     :callable t)
    (application &optional (argument *prewalk-default-executor*))
  (let ((conversation (application-conversation application)))
    (cond
      ((string-equal (string argument) "off")
       (prewalk-disarm conversation))
      ((string-equal (string argument) "status"))
      (t (prewalk-arm application argument)))
    (let ((state (prewalk--state conversation)))
      (application-present application
                           (if state
                               (format nil "Prewalk: ~(~A~), executor ~A."
                                       (prewalk-state-phase state) (prewalk-state-target state))
                               "Prewalk: not armed."))))
  :continue)
