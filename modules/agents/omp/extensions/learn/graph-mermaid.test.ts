import { describe, expect, it } from 'bun:test';

import { formatKnowledgeGraphMermaid } from './graph-mermaid';
import type { GraphNode, KnowledgeGraph } from './graph';

const now = '2026-11-01T00:00:00.000Z';

describe('Mermaid knowledge graph rendering', () => {
  it('renders direct and multi-premise reasoning chains with escaped labels', () => {
    const graph: KnowledgeGraph = {
      nodes: [
        graphNode('n_a', 'Functions map values.'),
        graphNode('n_b', 'Composition chains functions.'),
        graphNode('n_c', 'Unsafe " ] --> injected[" & <text>'),
      ],
      chains: [
        {
          id: 'arg_direct',
          premises: ['n_a'],
          conclusion: 'n_b',
          sources: ['session:lesson'],
          createdAt: now,
        },
        {
          id: 'arg_multi',
          premises: ['n_a', 'n_b'],
          conclusion: 'n_c',
          sources: ['session:lesson'],
          createdAt: now,
        },
      ],
    };

    const rendered = formatKnowledgeGraphMermaid(graph);

    expect(rendered).toContain('```mermaid\nflowchart LR');
    expect(rendered).toContain('n_0 --> n_1');
    expect(rendered).toContain('n_0 --> arg_1');
    expect(rendered).toContain('n_1 --> arg_1');
    expect(rendered).toContain('arg_1 --> n_2');
    expect(rendered).toContain('&quot;');
    expect(rendered).toContain('&amp;');
    expect(rendered).toContain('&lt;text&gt;');
    expect(rendered).not.toContain('Unsafe " ] --> injected["');
  });

  it('bounds large graphs and reports the omission', () => {
    const graph: KnowledgeGraph = {
      nodes: Array.from({ length: 101 }, (_, index) =>
        graphNode(`n_${index}`, `Fact ${index}`),
      ),
      chains: [],
    };

    const rendered = formatKnowledgeGraphMermaid(graph);

    expect(rendered).toContain('n_99["Fact 99"]');
    expect(rendered).not.toContain('n_100["Fact 100"]');
    expect(rendered).toContain('first 100 of 101 propositions');
  });
});

function graphNode(id: string, text: string): GraphNode {
  return { id, texts: [text], sources: ['session:lesson'], createdAt: now };
}
