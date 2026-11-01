/**
 * Prewalk target resolution: steered prompts and pure model-selection
 * helpers. Deliberately free of pi-tui imports so the workspace tests can
 * exercise this module directly.
 *
 * Ported from oh-my-pi (github.com/can1357/oh-my-pi) by way of Architect's
 * extension. Nightshade difference: there is no preconfigured fast provider —
 * an unspecified arm falls back to the cheapest available model other than
 * the active one, and says so.
 */

import type { Api, Model } from "@earendil-works/pi-ai";

/** Hidden plan nudge; scrubbed from the LLM context once the switch happens. */
export const PREWALK_PLAN_MESSAGE_TYPE = "prewalk-plan";
/** Hidden safety-net nudge forcing one more turn after a text-only reply. */
export const PREWALK_CONTINUE_MESSAGE_TYPE = "prewalk-continue";
/** Hidden "verify before finishing" checklist steered in at the switch. */
export const PREWALK_CHECKLIST_MESSAGE_TYPE = "prewalk-checklist";

export const PREWALK_PLAN_PROMPT = `Stop and write the complete plan in your NEXT reply — before any further exploration. You have already seen enough to commit to a plan; do not defer this.

First, state the plan itself, explicitly and comprehensively:

- Every remaining step in execution order, with the exact files, symbols, commands, and checks involved.
- Known risks, edge cases, and how you will verify each step actually landed (specific commands, expected outputs). Never modify tests or verification assets to make checks pass.
- What is already done, stated briefly, so no step gets repeated.

Be thorough and concrete — this plan is the reference for the remainder of the run. You may verify details with tools after the plan is written, never before.

Then, only once the plan above is complete, in the SAME reply, capture it as a todo list (the todo tool): 5-9 items, one per MEANINGFUL step, each naming its concrete target and its verification. Only steps that change or verify code belong on the list — no reporting, bookkeeping, cleanup-ceremony, or release-note items. The todo list serves the task, never the reverse: when reality disagrees with an item, fix the actual problem rather than working the checklist.

This is a checkpoint, not a final answer: do not end your turn on the plan alone — after recording the todo list, continue the task; do not stop here.`;

export const PREWALK_CONTINUE_PROMPT = `Continue the task now — do not end your turn here.`;

export const PREWALK_CHECKLIST_PROMPT = `Before you consider this task finished, verify:

- Consistency: if you changed a pattern, signature, or check in one place, grep for every other call site or duplicate copy that needs the identical change. A fix applied to only some of the matching sites is still a failure.
- Scope: if your diff does more than the minimal change needed to resolve the issue, confirm you have not altered behavior for any case outside the reported issue. Prefer the smallest correct diff over a broader rewrite.
- Verification: run the full test module or file the issue lives in, not just the one test you expect to flip. A change that breaks a sibling test is not a fix.

Do not claim the task is complete until you have done these three checks.`;

export type ThinkingLevel =
  "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

export function modelLabel(model: Model<Api>): string {
  return `${model.provider}/${model.id}`;
}

export function modelsAreEqual(
  a: Model<Api> | undefined,
  b: Model<Api>,
): boolean {
  return a !== undefined && a.provider === b.provider && a.id === b.id;
}

function totalCost(model: Model<Api>): number {
  return (model.cost?.input ?? 0) + (model.cost?.output ?? 0);
}

/** Cheapest first; break ties on output cost (implementation is output-heavy). */
function byCost(a: Model<Api>, b: Model<Api>): number {
  return (
    totalCost(a) - totalCost(b) || (a.cost?.output ?? 0) - (b.cost?.output ?? 0)
  );
}

export interface TargetResolution {
  readonly model?: Model<Api>;
  readonly error?: string;
  readonly warning?: string;
}

/**
 * Resolve the target model. With a spec (`provider/id` or a bare `id`) find
 * the matching available model. Without a spec, choose the cheapest available
 * model other than the active one, preferring models with a known non-zero
 * price so a mispriced or free stub is not chosen ahead of a real cheap model.
 */
export function resolveTarget(
  available: readonly Model<Api>[],
  current: Model<Api> | undefined,
  spec: string | undefined,
): TargetResolution {
  if (available.length === 0) {
    return { error: "No models with configured API keys are available" };
  }

  if (spec !== undefined && spec.trim().length > 0) {
    return resolveSpecTarget(available, spec.trim());
  }

  const candidates = available.filter(
    (model) => !modelsAreEqual(current, model),
  );

  if (candidates.length === 0) {
    return {
      error:
        "No available model to prewalk into (only the current model has a configured key)",
    };
  }

  const priced = candidates
    .filter((model) => totalCost(model) > 0)
    .sort(byCost);

  const chosen = priced[0] ?? [...candidates].sort(byCost)[0];

  if (chosen === undefined) {
    return {
      error:
        "No available model to prewalk into (only the current model has a configured key)",
    };
  }

  const warning = `No prewalk target was specified; using the cheapest available model ${modelLabel(chosen)}.`;

  return { model: chosen, warning };
}

function resolveSpecTarget(
  available: readonly Model<Api>[],
  query: string,
): TargetResolution {
  const normalized = query.toLowerCase();
  let match: Model<Api> | undefined;

  if (normalized.includes("/")) {
    const slash = normalized.indexOf("/");
    const provider = normalized.slice(0, slash);
    const id = normalized.slice(slash + 1);

    // Model ids can themselves contain slashes (e.g. "zai-org/GLM-5.2"), so
    // fall back to matching the whole query as a bare id.
    match =
      available.find(
        (model) =>
          model.provider.toLowerCase() === provider &&
          model.id.toLowerCase() === id,
      ) ?? available.find((model) => model.id.toLowerCase() === normalized);
  } else {
    match =
      available.find((model) => model.id.toLowerCase() === normalized) ??
      available.find((model) => model.id.toLowerCase().includes(normalized));
  }

  if (match === undefined) {
    return { error: `No available model matches "${query}"` };
  }

  return { model: match };
}
