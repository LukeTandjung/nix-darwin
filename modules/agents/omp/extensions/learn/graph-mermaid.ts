import { searchGraph, type GraphChain, type KnowledgeGraph } from './graph';

const MAX_MERMAID_NODE_COUNT = 100;
const MAX_LABEL_CHARACTER_COUNT = 120;

export function formatKnowledgeGraphMermaid(graph: KnowledgeGraph): string {
  const result = searchGraph(graph, '', MAX_MERMAID_NODE_COUNT);
  const nodeIds = new Map(
    result.nodes.map((node, index) => [node.id, `n_${index}`]),
  );
  const selectedIds = new Set(nodeIds.keys());
  const lines = ['```mermaid', 'flowchart LR'];
  for (const node of result.nodes) {
    const id = nodeIds.get(node.id);
    if (id === undefined) throw new Error(`Missing Mermaid ID for ${node.id}`);
    lines.push(`  ${id}["${mermaidLabel(node.texts[0] ?? node.id)}"]`);
  }
  const chains = result.chains.filter(
    (chain) =>
      selectedIds.has(chain.conclusion) &&
      chain.premises.every((id) => selectedIds.has(id)),
  );
  chains.forEach((chain, index) => appendChain(lines, chain, nodeIds, index));
  lines.push('```');
  if (result.totalMatches > result.nodes.length) {
    lines.push(
      '',
      `Showing the first ${result.nodes.length} of ${result.totalMatches} propositions; only complete reasoning chains are shown.`,
    );
  }
  return lines.join('\n');
}

function appendChain(
  lines: Array<string>,
  chain: GraphChain,
  nodeIds: ReadonlyMap<string, string>,
  index: number,
): void {
  const conclusion = nodeIds.get(chain.conclusion);
  if (conclusion === undefined)
    throw new Error(`Missing conclusion ID for ${chain.id}`);
  if (chain.premises.length === 1) {
    const premise = nodeIds.get(chain.premises[0] ?? '');
    if (premise === undefined)
      throw new Error(`Missing premise ID for ${chain.id}`);
    lines.push(`  ${premise} --> ${conclusion}`);
    return;
  }
  const junction = `arg_${index}`;
  lines.push(`  ${junction}(["reasoning"])`);
  for (const premiseId of chain.premises) {
    const premise = nodeIds.get(premiseId);
    if (premise === undefined)
      throw new Error(`Missing premise ID for ${chain.id}`);
    lines.push(`  ${premise} --> ${junction}`);
  }
  lines.push(`  ${junction} --> ${conclusion}`);
}

function mermaidLabel(text: string): string {
  const truncated =
    text.length <= MAX_LABEL_CHARACTER_COUNT
      ? text
      : `${text.slice(0, MAX_LABEL_CHARACTER_COUNT - 1)}…`;
  return truncated
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replace(/\r?\n/g, '<br/>');
}
