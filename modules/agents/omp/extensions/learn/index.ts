import { readFile } from 'node:fs/promises';

import type { ExtensionAPI } from '@oh-my-pi/pi-coding-agent';

import { createGraphSchemas, readKnowledgeGraph } from './graph';
import { formatKnowledgeGraphMermaid } from './graph-mermaid';
import { learningToolNames, registerLearningTools } from './learning-tools';
import { practiceToolNames, registerPracticeTools } from './practice-tools';
import { getSessionState, saveSessionState } from './runtime';
import {
  createLearningState,
  createPracticeState,
  createStateSchemas,
  formatStateForPrompt,
  formatStatus,
  type LearningSessionState,
} from './state';

const learningDoctrine = readFile(
  new URL('./prompts/learn.md', import.meta.url),
  'utf8',
);
const practiceDoctrine = readFile(
  new URL('./prompts/practice.md', import.meta.url),
  'utf8',
);
const workflowToolNames = new Set<string>([
  ...learningToolNames,
  ...practiceToolNames,
]);

export default function learningExtension(pi: ExtensionAPI): void {
  const stateSchemas = createStateSchemas(pi.arktype);
  const graphSchemas = createGraphSchemas(pi.arktype);
  registerLearningTools(pi, stateSchemas, graphSchemas);
  registerPracticeTools(pi, stateSchemas, graphSchemas);

  pi.registerCommand('learn', {
    description:
      'Start learning, show status, render /learn graph, or use /learn new <goal>',
    handler: async (args, ctx) => {
      if (args.trim() === 'graph') {
        const graph = await readKnowledgeGraph(graphSchemas);
        if (graph.nodes.length === 0) {
          ctx.ui.notify('The knowledge graph is empty.', 'info');
          return;
        }
        pi.sendMessage(
          {
            customType: 'learning-knowledge-graph',
            content: formatKnowledgeGraphMermaid(graph),
            display: true,
          },
          { triggerTurn: false },
        );
        return;
      }
      const command = parseWorkflowArguments(args);
      const current = getSessionState(ctx, stateSchemas);
      if (command.action === 'status') {
        ctx.ui.notify(
          current?.kind === 'learn'
            ? formatStatus(current)
            : 'No active lesson. Use /learn <goal>.',
          'info',
        );
        return;
      }
      if (current !== undefined && !command.replace) {
        ctx.ui.notify(
          'This session already has a workflow. Use /learn new <goal> to replace it.',
          'warning',
        );
        return;
      }
      if (command.value.length === 0) {
        ctx.ui.notify(
          'A learning goal is required: /learn new <goal>',
          'error',
        );
        return;
      }
      const state = createLearningState(
        command.value,
        new Date().toISOString(),
      );
      saveSessionState(pi, state);
      await syncActiveTools(pi, state);
      ctx.ui.notify(
        'Adaptive lesson started. Probing your goal and current understanding.',
        'info',
      );
      pi.sendUserMessage(`Start adaptive teaching. My goal is: ${state.goal}`);
    },
  });

  pi.registerCommand('practice', {
    description:
      'Start adaptive practice, show its status, or use /practice new <topic>',
    handler: async (args, ctx) => {
      const command = parseWorkflowArguments(args);
      const current = getSessionState(ctx, stateSchemas);
      if (command.action === 'status') {
        ctx.ui.notify(
          current?.kind === 'practice'
            ? formatStatus(current)
            : 'No active practice session. Use /practice <topic>.',
          'info',
        );
        return;
      }
      if (current !== undefined && !command.replace) {
        ctx.ui.notify(
          'This session already has a workflow. Use /practice new <topic> to replace it.',
          'warning',
        );
        return;
      }
      if (command.value.length === 0) {
        ctx.ui.notify(
          'A practice topic is required: /practice new <topic>',
          'error',
        );
        return;
      }
      const state = createPracticeState(
        command.value,
        new Date().toISOString(),
      );
      saveSessionState(pi, state);
      await syncActiveTools(pi, state);
      ctx.ui.notify('Adaptive practice started.', 'info');
      pi.sendUserMessage(
        `Start adaptive practice on: ${state.topic}. Use relevant persistent knowledge when available.`,
      );
    },
  });

  pi.on('before_agent_start', async (event, ctx) => {
    const state = getSessionState(ctx, stateSchemas);
    if (state === undefined) return;
    const doctrine =
      state.kind === 'learn' ? await learningDoctrine : await practiceDoctrine;
    return {
      systemPrompt: [
        ...event.systemPrompt,
        doctrine,
        `Current adaptive-learning state (authoritative):\n${formatStateForPrompt(state)}`,
      ],
    };
  });

  pi.on('session_start', async (_event, ctx) => {
    await syncActiveTools(pi, getSessionState(ctx, stateSchemas));
  });
  pi.on('session_switch', async (_event, ctx) => {
    await syncActiveTools(pi, getSessionState(ctx, stateSchemas));
  });
  pi.on('session_branch', async (_event, ctx) => {
    await syncActiveTools(pi, getSessionState(ctx, stateSchemas));
  });
  pi.on('session_tree', async (_event, ctx) => {
    await syncActiveTools(pi, getSessionState(ctx, stateSchemas));
  });
}

function parseWorkflowArguments(
  args: string,
): { action: 'status' } | { action: 'start'; value: string; replace: boolean } {
  const input = args.trim();
  if (input.length === 0 || input === 'status') return { action: 'status' };
  if (input === 'new') return { action: 'start', value: '', replace: true };
  if (input.startsWith('new ')) {
    return { action: 'start', value: input.slice(4).trim(), replace: true };
  }
  return { action: 'start', value: input, replace: false };
}

async function syncActiveTools(
  pi: ExtensionAPI,
  state: LearningSessionState | undefined,
): Promise<void> {
  const required =
    state?.kind === 'learn'
      ? learningToolNames
      : state?.kind === 'practice'
        ? [...practiceToolNames, 'learning_graph_search']
        : [];
  const preserved = pi
    .getActiveTools()
    .filter((name) => !workflowToolNames.has(name));
  await pi.setActiveTools([...preserved, ...required]);
}
