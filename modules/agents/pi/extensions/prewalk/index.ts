/**
 * Prewalk extension.
 *
 * Prewalk lets a strong model do the planning and then hands the mechanical
 * implementation off to a fast/cheap model. It is a one-way switch, armed
 * either at startup (`--prewalk` / `--prewalk-into <model>`) or mid-session
 * via the `/prewalk` command, and it fires at the first `edit`/`write` once a
 * todo list exists (the "todo gate").
 *
 * How it works, per assistant turn boundary (`turn_end`):
 *   1. A hidden deep-plan nudge is steered in so the strong model commits to a
 *      complete plan and seeds a todo list before touching code.
 *   2. A safety-net "continue" nudge re-arms one extra turn after a text-only
 *      reply so a plan-only turn never ends the run with no code written.
 *   3. Once the todo list exists AND the model makes its first edit/write, the
 *      session switches to the fast target model and a verification checklist
 *      is steered in. The plan nudge is scrubbed from the LLM context at the
 *      switch (the fast model inherits the plan, not the nudge).
 *
 * Bash is deliberately NOT a trigger tool (it doubles as exploration), and the
 * `todo` call itself is deliberately NOT a trigger (firing there hands the fast
 * model the whole implementation cold).
 *
 * The switch only runs when explicitly armed; it never changes model routing
 * on its own. Target selection lives in ./target (pure, unit-tested).
 *
 * Usage:
 *   pi --prewalk                     # arm at startup, cheapest available target
 *   pi --prewalk-into provider/model # arm at startup, explicit target
 *   /prewalk                         # searchable picker for the target model
 *   /prewalk <provider/model|model>  # arm now, explicit target
 *   /prewalk off                     # disarm
 *   /prewalk status                  # show current state
 */

import type { Api, Model } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  Theme,
} from "@earendil-works/pi-coding-agent";
import type {
  Component,
  Focusable,
  KeybindingsManager,
  TUI,
} from "@earendil-works/pi-tui";
import {
  Container,
  fuzzyFilter,
  Input,
  Spacer,
  Text,
} from "@earendil-works/pi-tui";
import {
  PREWALK_CHECKLIST_MESSAGE_TYPE,
  PREWALK_CHECKLIST_PROMPT,
  PREWALK_CONTINUE_MESSAGE_TYPE,
  PREWALK_CONTINUE_PROMPT,
  PREWALK_PLAN_MESSAGE_TYPE,
  PREWALK_PLAN_PROMPT,
  modelsAreEqual,
  modelLabel,
  resolveTarget,
  type ThinkingLevel,
} from "./target";

/** Tools whose first successful call triggers the switch — once the todo gate
 * is open. Bash is excluded (it doubles as exploration and fires turn-1
 * switches in practice). `todo` is NOT a trigger: firing at todo init hands
 * the fast model 100% of the implementation with zero started work. */
const PREWALK_ACTION_TOOLS = new Set(["edit", "write"]);

const PREWALK_PICKER_MAX_VISIBLE = 12;

interface MessageContext {
  readonly messages: readonly unknown[];
}

interface ArmedPrewalk {
  readonly target: Model<Api>;
  readonly thinkingLevel?: ThinkingLevel;
}

interface TurnEndEvent {
  readonly message?: { readonly role?: string };
  readonly toolResults?: readonly {
    readonly isError?: boolean;
    readonly toolName: string;
  }[];
}

interface PrewalkPickerEntry {
  readonly model: Model<Api>;
  readonly label: string;
}

/**
 * Searchable model picker for a bare `/prewalk` — `ctx.ui.select` is
 * arrow-keys-only, so this is a custom component: type to fuzzy-filter,
 * arrows to move, enter to confirm, esc to cancel. Modelled on pi's own
 * model selector (Input + fuzzyFilter over a windowed list).
 */
class PrewalkModelPicker extends Container implements Focusable {
  private readonly searchInput = new Input();
  private readonly listContainer = new Container();
  private filtered: readonly PrewalkPickerEntry[];
  private selectedIndex = 0;
  private _focused = false;

  // Focusable: the TUI sets this; the search input needs it for cursor/IME.
  get focused(): boolean {
    return this._focused;
  }
  set focused(value: boolean) {
    this._focused = value;
    this.searchInput.focused = value;
  }

  constructor(
    private readonly entries: readonly PrewalkPickerEntry[],
    private readonly theme: Theme,
    private readonly tui: TUI,
    private readonly keybindings: KeybindingsManager,
    private readonly done: (model: Model<Api> | undefined) => void,
  ) {
    super();
    this.filtered = entries;

    this.addChild(
      new Text(theme.fg("accent", "Prewalk into which model?"), 1, 0),
    );

    this.addChild(this.searchInput);
    this.addChild(new Spacer(1));
    this.addChild(this.listContainer);
    this.addChild(new Spacer(1));

    this.addChild(
      new Text(
        theme.fg(
          "dim",
          "type to filter · ↑↓ navigate · enter select · esc cancel",
        ),
        1,
        0,
      ),
    );

    this.renderList();
  }

  handleInput(data: string): void {
    if (this.keybindings.matches(data, "tui.select.up")) {
      this.moveSelection(-1);

      return;
    }

    if (this.keybindings.matches(data, "tui.select.down")) {
      this.moveSelection(1);

      return;
    }

    if (this.keybindings.matches(data, "tui.select.confirm")) {
      const chosen = this.filtered[this.selectedIndex];

      if (chosen) {
        this.done(chosen.model);
      }

      return;
    }

    if (this.keybindings.matches(data, "tui.select.cancel")) {
      this.done(undefined);

      return;
    }

    // Everything else is search text.
    this.searchInput.handleInput(data);
    this.applyFilter();
  }

  private moveSelection(direction: -1 | 1): void {
    if (this.filtered.length === 0) {
      return;
    }

    const last = this.filtered.length - 1;

    this.selectedIndex =
      direction === -1
        ? this.selectedIndex <= 0
          ? last
          : this.selectedIndex - 1
        : this.selectedIndex >= last
          ? 0
          : this.selectedIndex + 1;

    this.renderList();
  }

  private applyFilter(): void {
    const query = this.searchInput.getValue().trim();

    this.filtered =
      query.length === 0
        ? this.entries
        : fuzzyFilter([...this.entries], query, (entry) => entry.label);

    this.selectedIndex = 0;
    this.renderList();
  }

  private renderList(): void {
    this.listContainer.clear();

    if (this.filtered.length === 0) {
      this.listContainer.addChild(
        new Text(this.theme.fg("dim", "  no matching models"), 1, 0),
      );
    } else {
      this.renderVisible();
    }

    this.tui.requestRender();
  }

  private renderVisible(): void {
    const half = Math.floor(PREWALK_PICKER_MAX_VISIBLE / 2);
    const start = Math.max(
      0,
      Math.min(
        this.selectedIndex - half,
        this.filtered.length - PREWALK_PICKER_MAX_VISIBLE,
      ),
    );

    const visible = this.filtered.slice(
      start,
      start + PREWALK_PICKER_MAX_VISIBLE,
    );

    for (const [index, entry] of visible.entries()) {
      const isSelected = start + index === this.selectedIndex;
      const text = isSelected
        ? this.theme.fg("accent", `→ ${entry.label}`)
        : this.theme.fg("text", `  ${entry.label}`);

      this.listContainer.addChild(new Text(text, 1, 0));
    }

    if (this.filtered.length > PREWALK_PICKER_MAX_VISIBLE) {
      this.listContainer.addChild(
        new Text(
          this.theme.fg(
            "dim",
            `  (${this.selectedIndex + 1}/${this.filtered.length})`,
          ),
          1,
          0,
        ),
      );
    }
  }
}

/** Per-session prewalk state and the steered-nudge lifecycle around it. */
class PrewalkSession {
  private armed: ArmedPrewalk | undefined;
  private planInjected = false;
  private continuePending = false;
  private todoSeen = false;

  constructor(private readonly pi: ExtensionAPI) {}

  reset(): void {
    this.armed = undefined;
    this.planInjected = false;
    this.continuePending = false;
    this.todoSeen = false;
  }

  /** Arm prewalk and immediately steer the plan nudge — an explicit arm means
   * "start this now". A no-op with a notice when already armed. */
  arm(
    target: Model<Api>,
    thinkingLevel: ThinkingLevel | undefined,
    ctx: ExtensionContext,
  ): void {
    if (this.armed) {
      ctx.ui.notify(
        `Prewalk: already armed for ${modelLabel(this.armed.target)}, waiting for the first edit/write.`,
        "info",
      );

      return;
    }

    this.armed = { target, thinkingLevel };
    this.planInjected = true;
    this.continuePending = true;
    this.steer(PREWALK_PLAN_MESSAGE_TYPE, PREWALK_PLAN_PROMPT);

    ctx.ui.notify(
      `Prewalk: armed for ${modelLabel(target)} — will switch at the first edit/write once the todo list exists.`,
      "info",
    );
  }

  disarm(ctx: ExtensionContext): void {
    if (!this.armed) {
      ctx.ui.notify("Prewalk: not armed.", "info");

      return;
    }

    this.armed = undefined;
    this.continuePending = false;
    this.planInjected = false;
    ctx.ui.notify("Prewalk: disarmed.", "info");
  }

  statusLine(): string {
    return this.armed
      ? `Prewalk: armed for ${modelLabel(this.armed.target)} (todo seen: ${this.todoSeen}).`
      : "Prewalk: not armed.";
  }

  /** Resolve and arm from the --prewalk / --prewalk-into startup flags. */
  async armFromFlags(ctx: ExtensionContext): Promise<void> {
    const into = this.pi.getFlag("prewalk-into");
    const enabled =
      this.pi.getFlag("prewalk") === true ||
      (typeof into === "string" && into.length > 0);

    if (!enabled) {
      return;
    }

    const spec = typeof into === "string" && into.length > 0 ? into : undefined;
    const available = await this.availableModels(ctx);
    const resolved = resolveTarget(
      available,
      ctx.model as Model<Api> | undefined,
      spec,
    );

    if (resolved.error || !resolved.model) {
      ctx.ui.notify(
        `Prewalk: ${resolved.error ?? "could not resolve target model"}`,
        "warning",
      );

      return;
    }

    if (resolved.warning) {
      ctx.ui.notify(`Prewalk: ${resolved.warning}`, "warning");
    }

    this.arm(resolved.model, undefined, ctx);
  }

  /** Advance the one-way switch at each completed assistant-turn boundary. */
  async handleTurnEnd(
    event: TurnEndEvent,
    ctx: ExtensionContext,
  ): Promise<void> {
    if (!this.armed) {
      return;
    }

    const message = event.message;

    if (!message || message.role !== "assistant") {
      return;
    }

    const toolResults = event.toolResults ?? [];

    if (
      toolResults.some(
        (result) => !result.isError && result.toolName === "todo",
      )
    ) {
      this.todoSeen = true;
    }

    this.advanceContinuation(toolResults.length > 0);

    const action = this.actionTrigger(toolResults);

    if (!action) {
      this.ensurePlanNudge(ctx);

      return;
    }

    await this.switchToTarget(action, ctx);
  }

  /** Scrub the plan and continue nudges once the switch has fired or prewalk
   * stands down; the model inherits the plan they produced, not the nudges
   * themselves. The verification checklist is deliberately left in place.
   * Keying off `armed` keeps the scrub durable across session reloads. */
  scrubContext(event: MessageContext): MessageContext {
    if (this.armed) {
      return event;
    }

    const messages = event.messages.filter(
      (message) =>
        !(
          isCustomMessage(message) &&
          (message.customType === PREWALK_PLAN_MESSAGE_TYPE ||
            message.customType === PREWALK_CONTINUE_MESSAGE_TYPE)
        ),
    );

    if (messages.length === event.messages.length) {
      return event;
    }

    return { messages };
  }

  private steer(customType: string, content: string): void {
    this.pi.sendMessage(
      { customType, content, display: false },
      { deliverAs: "steer" },
    );
  }

  private async availableModels(
    ctx: ExtensionContext,
  ): Promise<readonly Model<Api>[]> {
    return (await ctx.modelRegistry.getAvailable()) as Model<Api>[];
  }

  /** The plan nudge asks for a prose plan before implementation, but the
   * agent loop treats each text-only reply as terminal. Tool progress re-arms
   * one continuation so split flows survive; two consecutive text-only replies
   * end naturally. */
  private advanceContinuation(hasToolResults: boolean): void {
    if (this.planInjected && hasToolResults) {
      this.continuePending = true;
    } else if (this.continuePending) {
      this.continuePending = false;
      this.steer(PREWALK_CONTINUE_MESSAGE_TYPE, PREWALK_CONTINUE_PROMPT);
    }
  }

  /** Todo gate: wait until a todo list exists AND the model actually starts
   * implementing (first edit/write). If the todo tool is not even active, the
   * gate is considered open so the switch cannot deadlock. */
  private actionTrigger(
    toolResults: readonly {
      readonly isError?: boolean;
      readonly toolName: string;
    }[],
  ): string | undefined {
    const todoGateOpen =
      this.todoSeen || !this.pi.getActiveTools().includes("todo");

    if (!todoGateOpen) {
      return undefined;
    }

    const action = toolResults.find(
      (result) => !result.isError && PREWALK_ACTION_TOOLS.has(result.toolName),
    );

    return action?.toolName;
  }

  private ensurePlanNudge(ctx: ExtensionContext): void {
    if (this.planInjected) {
      return;
    }

    this.planInjected = true;
    this.continuePending = true;
    this.steer(PREWALK_PLAN_MESSAGE_TYPE, PREWALK_PLAN_PROMPT);
    ctx.ui.notify("Prewalk: injected deep-plan nudge.", "info");
  }

  private async switchToTarget(
    toolName: string,
    ctx: ExtensionContext,
  ): Promise<void> {
    const armed = this.armed;

    if (!armed) {
      return;
    }

    if (modelsAreEqual(ctx.model as Model<Api> | undefined, armed.target)) {
      this.standDown();

      return;
    }

    const switched = await this.pi.setModel(armed.target);

    if (!switched) {
      ctx.ui.notify(
        `Prewalk: no API key for ${modelLabel(armed.target)}; staying on current model.`,
        "warning",
      );

      this.standDown();

      return;
    }

    if (armed.thinkingLevel) {
      this.pi.setThinkingLevel(armed.thinkingLevel);
    }

    this.standDown();

    ctx.ui.notify(
      `Prewalk: switched to ${modelLabel(armed.target)} after first ${toolName} call.`,
      "info",
    );

    this.steer(PREWALK_CHECKLIST_MESSAGE_TYPE, PREWALK_CHECKLIST_PROMPT);
  }

  private standDown(): void {
    this.armed = undefined;
    this.continuePending = false;
  }
}

interface CustomMessage {
  readonly customType?: string;
}

function isCustomMessage(message: unknown): message is CustomMessage {
  return (
    typeof message === "object" &&
    message !== null &&
    (message as { role?: unknown }).role === "custom"
  );
}

/**
 * Interactive target selection for a bare `/prewalk`: every available model
 * except the active one, cheapest first, fuzzy-searchable. Returns undefined
 * when the user cancels or the picker cannot run.
 */
async function pickTargetInteractively(
  ctx: ExtensionContext,
): Promise<Model<Api> | undefined> {
  const available = (await ctx.modelRegistry.getAvailable()) as Model<Api>[];
  const current = ctx.model as Model<Api> | undefined;
  const candidates = available.filter(
    (model) => !modelsAreEqual(current, model),
  );

  if (candidates.length === 0) {
    ctx.ui.notify(
      "Prewalk: no other model with a configured key is available.",
      "warning",
    );

    return undefined;
  }

  const entries: PrewalkPickerEntry[] = candidates.map((model) => ({
    model,
    label: modelLabel(model),
  }));

  try {
    return await ctx.ui.custom<Model<Api> | undefined>(
      (tui, theme, keybindings, done) => {
        const picker: Component & Focusable = new PrewalkModelPicker(
          entries,
          theme,
          tui,
          keybindings,
          done,
        );

        return picker;
      },
    );
  } catch {
    // Non-interactive session (print/rpc mode): no picker possible.
    return undefined;
  }
}

export default function prewalkExtension(pi: ExtensionAPI) {
  const session = new PrewalkSession(pi);

  pi.registerFlag("prewalk", {
    description:
      "Arm prewalk: switch to a fast/cheap model at the first edit/write (todo-gated)",
    type: "boolean",
    default: false,
  });

  pi.registerFlag("prewalk-into", {
    description: "Arm prewalk into a specific model (provider/id or id)",
    type: "string",
  });

  pi.on("session_start", async (_event, ctx) => {
    session.reset();
    await session.armFromFlags(ctx);
  });

  pi.registerCommand("prewalk", {
    description:
      "Switch to a fast/cheap model at the first edit/write (todo-gated)",
    handler: async (args, ctx) => {
      const arg = args?.trim() ?? "";

      if (arg === "off" || arg === "disable") {
        session.disarm(ctx);

        return;
      }

      if (arg === "status") {
        ctx.ui.notify(session.statusLine(), "info");

        return;
      }

      if (arg.length === 0) {
        // Bare /prewalk: let the user pick the implementation model.
        const picked = await pickTargetInteractively(ctx);

        if (!picked) {
          ctx.ui.notify(
            "Prewalk: not armed (no model selected). Pass one explicitly: /prewalk <provider/id>.",
            "info",
          );

          return;
        }

        session.arm(picked, undefined, ctx);

        return;
      }

      const available =
        (await ctx.modelRegistry.getAvailable()) as Model<Api>[];

      const resolved = resolveTarget(
        available,
        ctx.model as Model<Api> | undefined,
        arg,
      );

      if (resolved.error || !resolved.model) {
        ctx.ui.notify(
          `Prewalk: ${resolved.error ?? "could not resolve target model"}`,
          "error",
        );

        return;
      }

      if (resolved.warning) {
        ctx.ui.notify(`Prewalk: ${resolved.warning}`, "warning");
      }

      session.arm(resolved.model, undefined, ctx);
    },
  });

  pi.on("turn_end", async (event, ctx) => {
    await session.handleTurnEnd(event as TurnEndEvent, ctx);
  });

  pi.on("context", async (event) => {
    return session.scrubContext(event) as typeof event;
  });
}
