import type { ExtensionAPI, ExtensionContext } from '@oh-my-pi/pi-coding-agent';

import type { LearningSessionState, StateSchemas } from './state';

const STATE_ENTRY_TYPE = 'adaptive-learning-state';

export function getSessionState(
  ctx: ExtensionContext,
  schemas: StateSchemas,
): LearningSessionState | undefined {
  let found = false;
  let data: unknown;
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type === 'custom' && entry.customType === STATE_ENTRY_TYPE) {
      found = true;
      data = entry.data;
    }
  }
  return found ? schemas.session.assert(data) : undefined;
}

export function saveSessionState(
  pi: ExtensionAPI,
  state: LearningSessionState,
): void {
  pi.appendEntry(STATE_ENTRY_TYPE, state);
}

export function sessionSource(
  ctx: ExtensionContext,
  state: LearningSessionState,
): string {
  return `${ctx.sessionManager.getSessionId()}:${state.id}`;
}

export function textResult(text: string, isError = false) {
  return {
    content: [{ type: 'text' as const, text }],
    ...(isError ? { isError: true } : {}),
  };
}

export async function runTool(operation: () => Promise<string> | string) {
  try {
    return textResult(await operation());
  } catch (error) {
    return textResult(
      error instanceof Error ? error.message : String(error),
      true,
    );
  }
}
