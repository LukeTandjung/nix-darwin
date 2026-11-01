import type { ExtensionAPI } from '@oh-my-pi/pi-coding-agent';
import { Text } from '@oh-my-pi/pi-tui';

import { readKnowledgeGraph, type GraphSchemas } from './graph';
import { getSessionState, runTool, saveSessionState } from './runtime';
import { beginProblem, concludeProblem, type StateSchemas } from './state';

export const practiceToolNames = [
  'practice_problem',
  'practice_conclude',
] as const;

export function registerPracticeTools(
  pi: ExtensionAPI,
  stateSchemas: StateSchemas,
  graphSchemas: GraphSchemas,
): void {
  const { arktype: type } = pi;

  pi.registerTool({
    name: 'practice_problem',
    label: 'Commit practice problem',
    description:
      'Commit one varied practice problem and its full solution before showing the statement. Target graph IDs when relevant. Show only the statement, request reasoning, and end the turn.',
    parameters: type({
      statement: 'string > 0',
      solution: 'string > 0',
      'targetNodeIds?': type('string > 0').array().atMostLength(20),
    }),
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) =>
      runTool(async () => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'practice')
          throw new Error('Start a /practice session first.');
        const targetNodeIds = params.targetNodeIds ?? [];
        const graph = await readKnowledgeGraph(graphSchemas);
        for (const id of targetNodeIds) {
          if (!graph.nodes.some((node) => node.id === id)) {
            throw new Error(`Unknown target proposition ID: ${id}`);
          }
        }
        saveSessionState(
          pi,
          beginProblem(
            state,
            { ...params, targetNodeIds },
            new Date().toISOString(),
          ),
        );
        return `Pose this problem without revealing the solution, then end the turn: ${params.statement}`;
      }),
    renderCall: (args, _options, theme) =>
      new Text(theme.fg('accent', `Practice problem: ${args.statement}`), 0, 0),
  });

  pi.registerTool({
    name: 'practice_conclude',
    label: 'Conclude practice problem',
    description:
      'Conclude the active problem after judging the learner’s reasoning against the committed solution. Record the diagnostic evidence, reveal the solution, then wait for an explicit request for another problem.',
    parameters: type({
      outcome: type("'correct' | 'partial' | 'incorrect' | 'dismissed'"),
      diagnosis: type('string > 0').describe(
        'Reasoning evidence, misconception, and useful next step',
      ),
    }),
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) =>
      runTool(() => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'practice')
          throw new Error('Start a /practice session first.');
        const next = concludeProblem(state, params, new Date().toISOString());
        saveSessionState(pi, next);
        return 'Outcome recorded. Reveal and explain the committed solution, then wait for the learner to request another problem.';
      }),
  });
}
