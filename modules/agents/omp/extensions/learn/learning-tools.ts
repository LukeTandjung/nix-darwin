import type { ExtensionAPI } from '@oh-my-pi/pi-coding-agent';
import { Text } from '@oh-my-pi/pi-tui';

import {
  formatGraphSearch,
  readKnowledgeGraph,
  rememberFindings,
  searchGraph,
  type GraphSchemas,
} from './graph';
import {
  getSessionState,
  runTool,
  saveSessionState,
  sessionSource,
} from './runtime';
import {
  beginCheck,
  completeLearning,
  finishProbe,
  resolveCheck,
  writePlan,
  type StateSchemas,
} from './state';

export const learningToolNames = [
  'learning_probe_done',
  'learning_plan',
  'learning_check',
  'learning_resolve_check',
  'learning_remember',
  'learning_graph_search',
  'learning_complete',
] as const;

export function registerLearningTools(
  pi: ExtensionAPI,
  stateSchemas: StateSchemas,
  graphSchemas: GraphSchemas,
): void {
  const { arktype: type } = pi;

  pi.registerTool({
    name: 'learning_probe_done',
    label: 'Finish learning probe',
    description:
      'Finish the probe only after the goal is concrete and every dependency strand has a known floor and ceiling. Record evidence, not a generic summary.',
    parameters: type({
      strands: stateSchemas.probeStrands,
    }),
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) =>
      runTool(() => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'learn')
          throw new Error('Start a /learn session first.');
        saveSessionState(
          pi,
          finishProbe(state, params.strands, new Date().toISOString()),
        );
        return 'Probe recorded. Build the minimal dependency plan with learning_plan.';
      }),
  });

  pi.registerTool({
    name: 'learning_plan',
    label: 'Write lesson plan',
    description:
      'Write the minimal dependency DAG from the learner’s current understanding to the goal. Use stable lowercase node IDs and list every prerequisite in dependsOn.',
    parameters: type({
      nodes: stateSchemas.planNodes,
    }),
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) =>
      runTool(() => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'learn')
          throw new Error('Start a /learn session first.');
        const next = writePlan(state, params.nodes, new Date().toISOString());
        saveSessionState(pi, next);
        return `Plan saved with ${next.plan?.length ?? 0} nodes. Present it concisely, then wait for the learner’s go-ahead.`;
      }),
  });

  pi.registerTool({
    name: 'learning_check',
    label: 'Commit teaching check',
    description:
      'Commit one free-recall teaching check and its full correct answer before showing the question. Ask the question after this tool returns, then end the turn. Never reveal committedAnswer during the attempt.',
    parameters: type({
      nodeId: 'string > 0',
      question: 'string > 0',
      committedAnswer: 'string > 0',
    }),
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) =>
      runTool(() => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'learn')
          throw new Error('Start a /learn session first.');
        saveSessionState(
          pi,
          beginCheck(state, params, new Date().toISOString()),
        );
        return `Ask this question verbatim and end the turn: ${params.question}`;
      }),
    renderCall: (args, _options, theme) =>
      new Text(
        theme.fg('accent', `Check ${args.nodeId}: ${args.question}`),
        0,
        0,
      ),
  });

  pi.registerTool({
    name: 'learning_resolve_check',
    label: 'Resolve teaching check',
    description:
      'Judge the learner’s latest answer strictly against the active committedAnswer. Use held for a sound answer, fragile for incomplete or uncertain understanding, and gap for a misconception or missing step.',
    parameters: type({
      verdict: type("'held' | 'fragile' | 'gap'"),
      diagnosis: type('string > 0').describe(
        'Specific evidence and the next repair or teaching step',
      ),
    }),
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) =>
      runTool(() => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'learn')
          throw new Error('Start a /learn session first.');
        const next = resolveCheck(state, params, new Date().toISOString());
        saveSessionState(pi, next);
        return params.verdict === 'held'
          ? 'Check resolved as held. Continue with the next single reasoning step.'
          : 'Check recorded as unresolved. Repair this exact weakness before building on it.';
      }),
  });

  pi.registerTool({
    name: 'learning_remember',
    label: 'Update knowledge graph',
    description:
      'Extract objective propositions and jointly-entailing reasoning chains from taught material. Keys are local to this call. Use an existing graph ID in sameAs for an identical idea; chains reference local keys or graph IDs.',
    parameters: graphSchemas.remember,
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) =>
      runTool(async () => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'learn')
          throw new Error('Knowledge extraction requires a /learn session.');
        if (params.propositions.length === 0 && params.chains.length === 0) {
          throw new Error(
            'Provide at least one proposition or reasoning chain.',
          );
        }
        const result = await rememberFindings(graphSchemas, {
          source: sessionSource(ctx, state),
          propositions: params.propositions,
          chains: params.chains,
        });
        return `Knowledge graph updated: ${result.addedNodes} node assertions and ${result.addedChains} chain assertions appended.`;
      }),
  });

  pi.registerTool({
    name: 'learning_graph_search',
    label: 'Search knowledge graph',
    description:
      'Search persistent propositions by literal text and return their IDs, sources, and connected reasoning chains. Use an empty query for the first page of all knowledge.',
    parameters: type({
      query: 'string',
      'limit?': '1 <= number.integer <= 50',
    }),
    approval: 'read',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, params) =>
      runTool(async () => {
        const graph = await readKnowledgeGraph(graphSchemas);
        return formatGraphSearch(
          searchGraph(graph, params.query, params.limit),
        );
      }),
  });

  pi.registerTool({
    name: 'learning_complete',
    label: 'Complete lesson',
    description:
      'Complete the lesson only when every plan node’s latest check is held and the goal feels self-evident to the learner.',
    parameters: type({}),
    approval: 'write',
    loadMode: 'essential',
    defaultInactive: true,
    execute: async (_toolCallId, _params, _signal, _onUpdate, ctx) =>
      runTool(() => {
        const state = getSessionState(ctx, stateSchemas);
        if (state?.kind !== 'learn')
          throw new Error('Start a /learn session first.');
        saveSessionState(pi, completeLearning(state, new Date().toISOString()));
        return 'Lesson marked complete. Summarize the reasoning structure without adding new material.';
      }),
  });
}
