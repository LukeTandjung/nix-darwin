import { randomUUID } from 'node:crypto';
import { mkdir } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';

import type { Type } from '@oh-my-pi/omptype';
import type { ExtensionAPI } from '@oh-my-pi/pi-coding-agent';

import {
  appendPayload,
  createAssertionPayload,
  readJsonLines,
  withGraphLock,
  type LedgerSnapshot,
} from './graph-storage';
import type { Schema } from './schema';

const DEFAULT_SEARCH_LIMIT = 20;

export interface PropositionInput {
  key: string;
  text: string;
  sameAs?: string;
}

export interface ReasoningChainInput {
  premises: Array<string>;
  conclusion: string;
}

export interface RememberInput {
  propositions: Array<PropositionInput>;
  chains: Array<ReasoningChainInput>;
}

interface NodeAssertion {
  version: 1;
  id: string;
  text: string;
  source: string;
  createdAt: string;
}

interface ChainAssertion {
  version: 1;
  id: string;
  premises: Array<string>;
  conclusion: string;
  source: string;
  createdAt: string;
}

export interface GraphStoreSchemas {
  nodeAssertion: Schema<NodeAssertion>;
  chainAssertion: Schema<ChainAssertion>;
}

export interface GraphSchemas extends GraphStoreSchemas {
  remember: Type<RememberInput>;
}

export function createGraphSchemas(
  type: ExtensionAPI['arktype'],
): GraphSchemas {
  const proposition = type({
    key: 'string > 0',
    text: 'string > 0',
    'sameAs?': 'string > 0',
  });
  const reasoningChain = type({
    premises: type('string > 0').array().atLeastLength(1),
    conclusion: 'string > 0',
  });
  return {
    remember: type({
      propositions: proposition.array().atMostLength(100),
      chains: reasoningChain.array().atMostLength(100),
    }),
    nodeAssertion: type({
      version: '1',
      id: 'string > 0',
      text: 'string > 0',
      source: 'string > 0',
      createdAt: 'string > 0',
    }),
    chainAssertion: type({
      version: '1',
      id: 'string > 0',
      premises: type('string > 0').array().atLeastLength(1),
      conclusion: 'string > 0',
      source: 'string > 0',
      createdAt: 'string > 0',
    }),
  };
}

export interface GraphNode {
  readonly id: string;
  readonly texts: Array<string>;
  readonly sources: Array<string>;
  readonly createdAt: string;
}

export interface GraphChain {
  readonly id: string;
  readonly premises: Array<string>;
  readonly conclusion: string;
  readonly sources: Array<string>;
  readonly createdAt: string;
}

export interface KnowledgeGraph {
  readonly nodes: Array<GraphNode>;
  readonly chains: Array<GraphChain>;
}

export interface GraphSearchResult {
  readonly nodes: Array<GraphNode>;
  readonly chains: Array<GraphChain>;
  readonly totalMatches: number;
}

interface GraphStorageSnapshot {
  readonly graph: KnowledgeGraph;
  readonly nodes: LedgerSnapshot;
  readonly chains: LedgerSnapshot;
}

export function defaultLearningDirectory(): string {
  const stateHome =
    process.env.XDG_STATE_HOME ?? join(homedir(), '.local', 'state');
  return process.env.OMP_LEARN_DIR ?? join(stateHome, 'omp', 'learn');
}

export async function readKnowledgeGraph(
  schemas: GraphStoreSchemas,
  root = defaultLearningDirectory(),
): Promise<KnowledgeGraph> {
  return (await readGraphStorageSnapshot(schemas, root)).graph;
}

export async function rememberFindings(
  schemas: GraphStoreSchemas,
  options: {
    root?: string;
    source: string;
    propositions: Array<PropositionInput>;
    chains: Array<ReasoningChainInput>;
  },
): Promise<{ addedNodes: number; addedChains: number }> {
  const root = options.root ?? defaultLearningDirectory();
  await mkdir(root, { recursive: true });
  return withGraphLock(root, async () => {
    const snapshot = await readGraphStorageSnapshot(schemas, root);
    const prepared = prepareFindings(
      snapshot.graph,
      options,
      new Date().toISOString(),
    );
    const nodePath = join(root, 'nodes.jsonl');
    const chainPath = join(root, 'chains.jsonl');
    const nodePayload = createAssertionPayload(
      nodePath,
      prepared.nodes,
      snapshot.nodes,
    );
    const chainPayload = createAssertionPayload(
      chainPath,
      prepared.chains,
      snapshot.chains,
    );
    await appendPayload(nodePath, nodePayload);
    await appendPayload(chainPath, chainPayload);
    return {
      addedNodes: prepared.nodes.length,
      addedChains: prepared.chains.length,
    };
  });
}

async function readGraphStorageSnapshot(
  schemas: GraphStoreSchemas,
  root: string,
): Promise<GraphStorageSnapshot> {
  const [nodes, chains] = await Promise.all([
    readJsonLines(join(root, 'nodes.jsonl')),
    readJsonLines(join(root, 'chains.jsonl')),
  ]);
  const nodeAssertions = nodes.values.map((line) =>
    schemas.nodeAssertion.assert(line),
  );
  const chainAssertions = chains.values.map((line) =>
    schemas.chainAssertion.assert(line),
  );
  return {
    graph: {
      nodes: foldNodes(nodeAssertions),
      chains: foldChains(chainAssertions),
    },
    nodes,
    chains,
  };
}

export function searchGraph(
  graph: KnowledgeGraph,
  query: string,
  limit = DEFAULT_SEARCH_LIMIT,
): GraphSearchResult {
  const normalizedQuery = normalizeText(query);
  const matches = graph.nodes.filter(
    (node) =>
      normalizedQuery.length === 0 ||
      node.texts.some((text) => normalizeText(text).includes(normalizedQuery)),
  );
  const nodes = matches.slice(0, limit);
  const selectedIds = new Set(nodes.map((node) => node.id));
  const chains = graph.chains.filter(
    (chain) =>
      selectedIds.has(chain.conclusion) ||
      chain.premises.some((id) => selectedIds.has(id)),
  );
  return { nodes, chains, totalMatches: matches.length };
}

export function formatGraphSearch(result: GraphSearchResult): string {
  if (result.nodes.length === 0) return 'No matching propositions.';
  const labels = new Map(
    result.nodes.map((node) => [node.id, node.texts[0] ?? node.id]),
  );
  const propositionLines = result.nodes.map(
    (node) =>
      `${node.id}: ${node.texts.join(' | ')} [sources: ${node.sources.join(', ')}]`,
  );
  const chainLines = result.chains.map((chain) => {
    const premises = chain.premises.map(
      (id) => `${id} (${labels.get(id) ?? 'see graph'})`,
    );
    return `${chain.id}: ${premises.join(' + ')} -> ${chain.conclusion} (${labels.get(chain.conclusion) ?? 'see graph'})`;
  });
  return [
    `Showing ${result.nodes.length} of ${result.totalMatches} matching propositions.`,
    ...propositionLines,
    ...(chainLines.length > 0 ? ['Reasoning chains:', ...chainLines] : []),
  ].join('\n');
}

function prepareFindings(
  graph: KnowledgeGraph,
  input: {
    source: string;
    propositions: Array<PropositionInput>;
    chains: Array<ReasoningChainInput>;
  },
  createdAt: string,
): { nodes: Array<NodeAssertion>; chains: Array<ChainAssertion> } {
  const nodes = [...graph.nodes];
  const chains = [...graph.chains];
  const newNodes: Array<NodeAssertion> = [];
  const newChains: Array<ChainAssertion> = [];
  const localIds = new Map<string, string>();
  for (const proposition of input.propositions) {
    const key = proposition.key.trim();
    if (localIds.has(key)) throw new Error(`Duplicate proposition key: ${key}`);
    const existing = resolveProposition(nodes, proposition);
    const id = existing?.id ?? newId('n_');
    localIds.set(key, id);
    const assertion: NodeAssertion = {
      version: 1,
      id,
      text: proposition.text.trim(),
      source: input.source,
      createdAt,
    };
    const needsAssertion =
      existing === undefined ||
      !existing.texts.includes(assertion.text) ||
      !existing.sources.includes(assertion.source);
    if (existing === undefined) {
      nodes.push({
        id: assertion.id,
        texts: [assertion.text],
        sources: [assertion.source],
        createdAt: assertion.createdAt,
      });
    } else if (needsAssertion) {
      const existingIndex = nodes.indexOf(existing);
      nodes[existingIndex] = {
        ...existing,
        texts: [...new Set([...existing.texts, assertion.text])],
        sources: [...new Set([...existing.sources, assertion.source])],
      };
    }
    if (needsAssertion) newNodes.push(assertion);
  }
  for (const chain of input.chains) {
    const premises = chain.premises.map((ref) =>
      resolveReference(ref, localIds, nodes),
    );
    const conclusion = resolveReference(chain.conclusion, localIds, nodes);
    if (premises.includes(conclusion))
      throw new Error('A conclusion cannot be its own premise.');
    const existing = chains.find(
      (candidate) =>
        chainKey(candidate.premises, candidate.conclusion) ===
        chainKey(premises, conclusion),
    );
    const assertion: ChainAssertion = {
      version: 1,
      id: existing?.id ?? newId('arg_'),
      premises,
      conclusion,
      source: input.source,
      createdAt,
    };
    if (existing === undefined) {
      chains.push({
        id: assertion.id,
        premises: assertion.premises,
        conclusion: assertion.conclusion,
        sources: [assertion.source],
        createdAt: assertion.createdAt,
      });
    }
    if (existing === undefined || !existing.sources.includes(input.source))
      newChains.push(assertion);
  }
  return { nodes: newNodes, chains: newChains };
}

function resolveProposition(
  nodes: Array<GraphNode>,
  proposition: PropositionInput,
): GraphNode | undefined {
  const normalized = normalizeText(proposition.text);
  if (proposition.sameAs !== undefined) {
    const match = nodes.find((node) => node.id === proposition.sameAs);
    if (match === undefined)
      throw new Error(`Unknown sameAs proposition ID: ${proposition.sameAs}`);
    const conflict = nodes.find(
      (node) =>
        node.id !== match.id &&
        node.texts.some((text) => normalizeText(text) === normalized),
    );
    if (conflict !== undefined) {
      throw new Error(
        `Phrasing already belongs to ${conflict.id}; cannot also link it to ${match.id}.`,
      );
    }
    return match;
  }
  return nodes.find((node) =>
    node.texts.some((text) => normalizeText(text) === normalized),
  );
}

function resolveReference(
  reference: string,
  localIds: ReadonlyMap<string, string>,
  nodes: Array<GraphNode>,
): string {
  const trimmed = reference.trim();
  const local = localIds.get(trimmed);
  if (local !== undefined) return local;
  if (nodes.some((node) => node.id === trimmed)) return trimmed;
  throw new Error(`Unknown proposition reference: ${trimmed}`);
}

function foldNodes(assertions: Array<NodeAssertion>): Array<GraphNode> {
  const folded = new Map<
    string,
    { texts: Set<string>; sources: Set<string>; createdAt: string }
  >();
  for (const assertion of assertions) {
    const current = folded.get(assertion.id) ?? {
      texts: new Set<string>(),
      sources: new Set<string>(),
      createdAt: assertion.createdAt,
    };
    current.texts.add(assertion.text);
    current.sources.add(assertion.source);
    folded.set(assertion.id, current);
  }
  return Array.from(folded, ([id, value]) => ({
    id,
    texts: [...value.texts],
    sources: [...value.sources],
    createdAt: value.createdAt,
  }));
}

function foldChains(assertions: Array<ChainAssertion>): Array<GraphChain> {
  const folded = new Map<
    string,
    {
      id: string;
      premises: Array<string>;
      conclusion: string;
      sources: Set<string>;
      createdAt: string;
    }
  >();
  for (const assertion of assertions) {
    const key = chainKey(assertion.premises, assertion.conclusion);
    const current = folded.get(key) ?? {
      id: assertion.id,
      premises: assertion.premises,
      conclusion: assertion.conclusion,
      sources: new Set<string>(),
      createdAt: assertion.createdAt,
    };
    current.sources.add(assertion.source);
    folded.set(key, current);
  }
  return Array.from(folded.values(), (chain) => ({
    ...chain,
    sources: [...chain.sources],
  }));
}

function chainKey(premises: Array<string>, conclusion: string): string {
  return `${[...premises].sort().join('+')}>${conclusion}`;
}

function normalizeText(text: string): string {
  return text.trim().toLocaleLowerCase().replace(/\s+/g, ' ');
}

function newId(prefix: string): string {
  return `${prefix}${randomUUID().replaceAll('-', '').slice(0, 12)}`;
}
