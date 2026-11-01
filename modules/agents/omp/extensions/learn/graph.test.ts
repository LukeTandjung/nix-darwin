import { afterEach, describe, expect, it } from 'bun:test';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import {
  readKnowledgeGraph,
  rememberFindings,
  searchGraph,
  type GraphStoreSchemas,
} from './graph';

// Persistence behavior is independent of OMP's production ArkType validators.
const identitySchema = { assert: <T>(data: T): T => data };
const schemas: GraphStoreSchemas = {
  nodeAssertion: identitySchema,
  chainAssertion: identitySchema,
};
const temporaryDirectories: Array<string> = [];

afterEach(async () => {
  await Promise.all(
    temporaryDirectories
      .splice(0)
      .map((path) => rm(path, { recursive: true, force: true })),
  );
});

describe('knowledge graph persistence', () => {
  it('deduplicates repeated propositions and structurally identical chains', async () => {
    const root = await temporaryGraphDirectory();
    const input = {
      source: 'session:lesson',
      propositions: [
        { key: 'a', text: 'A function maps inputs to outputs.' },
        {
          key: 'b',
          text: 'Composition applies one function to another’s output.',
        },
      ],
      chains: [{ premises: ['a'], conclusion: 'b' }],
    };

    await rememberFindings(schemas, { ...input, root });
    const repeated = await rememberFindings(schemas, {
      ...input,
      chains: [{ premises: ['a'], conclusion: 'b' }],
      root,
    });
    const graph = await readKnowledgeGraph(schemas, root);

    expect(repeated).toEqual({ addedNodes: 0, addedChains: 0 });
    expect(graph.nodes).toHaveLength(2);
    expect(graph.chains).toHaveLength(1);
    expect(graph.chains[0]?.premises).toEqual([graph.nodes[0]?.id]);
  });

  it('merges an explicitly identical phrasing without creating another identity', async () => {
    const root = await temporaryGraphDirectory();
    await rememberFindings(schemas, {
      root,
      source: 'session:one',
      propositions: [{ key: 'fact', text: 'Composition chains functions.' }],
      chains: [],
    });
    const graph = await readKnowledgeGraph(schemas, root);
    const id = graph.nodes[0]?.id;
    if (id === undefined)
      throw new Error('Expected the first proposition to be stored.');

    await rememberFindings(schemas, {
      root,
      source: 'session:two',
      propositions: [
        { key: 'alias', text: 'Functions compose by chaining.', sameAs: id },
      ],
      chains: [],
    });
    const merged = await readKnowledgeGraph(schemas, root);

    expect(merged.nodes).toHaveLength(1);
    expect(merged.nodes[0]?.texts).toContain('Functions compose by chaining.');
    expect(merged.nodes[0]?.sources).toEqual(['session:one', 'session:two']);
  });

  it('returns reasoning chains connected to matching propositions', async () => {
    const root = await temporaryGraphDirectory();
    await rememberFindings(schemas, {
      root,
      source: 'session:lesson',
      propositions: [
        { key: 'fact', text: 'Functions map values.' },
        { key: 'result', text: 'Composition chains functions.' },
      ],
      chains: [{ premises: ['fact'], conclusion: 'result' }],
    });
    const graph = await readKnowledgeGraph(schemas, root);

    const result = searchGraph(graph, 'composition');

    expect(result.totalMatches).toBe(1);
    expect(result.chains).toHaveLength(1);
  });

  it('rejects a chain that references unknown knowledge', async () => {
    const root = await temporaryGraphDirectory();

    await expect(
      rememberFindings(schemas, {
        root,
        source: 'session:lesson',
        propositions: [],
        chains: [{ premises: ['n_missing'], conclusion: 'n_also_missing' }],
      }),
    ).rejects.toThrow('Unknown proposition reference');
  });

  it('serializes concurrent writers before deduplicating', async () => {
    const root = await temporaryGraphDirectory();
    const input = {
      root,
      source: 'session:lesson',
      propositions: [
        { key: 'a', text: 'Functions map values.' },
        { key: 'b', text: 'Composition chains functions.' },
      ],
      chains: [{ premises: ['a'], conclusion: 'b' }],
    };

    const results = await Promise.all(
      Array.from({ length: 10 }, () => rememberFindings(schemas, input)),
    );
    const graph = await readKnowledgeGraph(schemas, root);

    expect(
      results.reduce((total, result) => total + result.addedNodes, 0),
    ).toBe(2);
    expect(
      results.reduce((total, result) => total + result.addedChains, 0),
    ).toBe(1);
    expect(graph.nodes).toHaveLength(2);
    expect(graph.chains).toHaveLength(1);
  });

  it('rejects an alias that already belongs to another identity', async () => {
    const root = await temporaryGraphDirectory();
    await rememberFindings(schemas, {
      root,
      source: 'session:lesson',
      propositions: [
        { key: 'a', text: 'First proposition.' },
        { key: 'b', text: 'Second proposition.' },
      ],
      chains: [],
    });
    const graph = await readKnowledgeGraph(schemas, root);
    const firstId = graph.nodes[0]?.id;
    if (firstId === undefined)
      throw new Error('Expected two stored identities.');

    await expect(
      rememberFindings(schemas, {
        root,
        source: 'session:other',
        propositions: [
          { key: 'conflict', text: 'Second proposition.', sameAs: firstId },
        ],
        chains: [],
      }),
    ).rejects.toThrow('already belongs');
  });

  it('refuses an append that would make the ledger exceed its line limit', async () => {
    const root = await temporaryGraphDirectory();
    const assertion = {
      version: 1,
      id: 'n_repeated',
      text: 'Repeated proposition.',
      source: 'session:seed',
      createdAt: '2026-11-01T00:00:00.000Z',
    };
    const content = `${Array.from({ length: 20_000 }, () => JSON.stringify(assertion)).join('\n')}\n`;
    await writeFile(join(root, 'nodes.jsonl'), content, 'utf8');

    await expect(
      rememberFindings(schemas, {
        root,
        source: 'session:lesson',
        propositions: [{ key: 'new', text: 'A new proposition.' }],
        chains: [],
      }),
    ).rejects.toThrow('line limit');
    const graph = await readKnowledgeGraph(schemas, root);
    expect(graph.nodes).toHaveLength(1);
  });

  it('rejects duplicate aliases within one extraction call', async () => {
    const root = await temporaryGraphDirectory();
    await rememberFindings(schemas, {
      root,
      source: 'session:lesson',
      propositions: [
        { key: 'a', text: 'First proposition.' },
        { key: 'b', text: 'Second proposition.' },
      ],
      chains: [],
    });
    const graph = await readKnowledgeGraph(schemas, root);
    const firstId = graph.nodes[0]?.id;
    const secondId = graph.nodes[1]?.id;
    if (firstId === undefined || secondId === undefined) {
      throw new Error('Expected two stored identities.');
    }

    await expect(
      rememberFindings(schemas, {
        root,
        source: 'session:other',
        propositions: [
          { key: 'alias-a', text: 'Shared alias.', sameAs: firstId },
          { key: 'alias-b', text: 'Shared alias.', sameAs: secondId },
        ],
        chains: [],
      }),
    ).rejects.toThrow('already belongs');
    const unchanged = await readKnowledgeGraph(schemas, root);
    expect(
      unchanged.nodes.every((node) => !node.texts.includes('Shared alias.')),
    ).toBe(true);
  });

  it('preflights chains before appending any nodes in a mixed batch', async () => {
    const root = await temporaryGraphDirectory();
    await rememberFindings(schemas, {
      root,
      source: 'session:seed',
      propositions: [
        { key: 'a', text: 'Premise.' },
        { key: 'b', text: 'Conclusion.' },
      ],
      chains: [],
    });
    const seeded = await readKnowledgeGraph(schemas, root);
    const premiseId = seeded.nodes[0]?.id;
    const conclusionId = seeded.nodes[1]?.id;
    if (premiseId === undefined || conclusionId === undefined) {
      throw new Error('Expected seeded proposition identities.');
    }
    const assertion = {
      version: 1,
      id: 'arg_repeated',
      premises: [premiseId],
      conclusion: conclusionId,
      source: 'session:seed',
      createdAt: '2026-11-01T00:00:00.000Z',
    };
    const content = `${Array.from({ length: 20_000 }, () => JSON.stringify(assertion)).join('\n')}\n`;
    await writeFile(join(root, 'chains.jsonl'), content, 'utf8');

    await expect(
      rememberFindings(schemas, {
        root,
        source: 'session:lesson',
        propositions: [{ key: 'new', text: 'New premise.' }],
        chains: [{ premises: ['new'], conclusion: conclusionId }],
      }),
    ).rejects.toThrow('line limit');
    const unchanged = await readKnowledgeGraph(schemas, root);
    expect(unchanged.nodes).toHaveLength(2);
  });

  it('releases the graph lock when a writer exits without cleanup', async () => {
    const root = await temporaryGraphDirectory();
    const writer = Bun.spawn({
      cmd: [
        process.execPath,
        '-e',
        `import { Database } from 'bun:sqlite';
         const path = process.env.OMP_LEARN_TEST_LOCK;
         if (path === undefined) throw new Error('Missing lock path');
         const database = new Database(path);
         database.exec('BEGIN IMMEDIATE');
         process.exit(0);`,
      ],
      env: {
        ...process.env,
        OMP_LEARN_TEST_LOCK: join(root, '.write-lock.sqlite'),
      },
      stdout: 'ignore',
      stderr: 'inherit',
    });
    expect(await writer.exited).toBe(0);

    await rememberFindings(schemas, {
      root,
      source: 'session:lesson',
      propositions: [{ key: 'fact', text: 'Writing still works.' }],
      chains: [],
    });
    const graph = await readKnowledgeGraph(schemas, root);
    expect(graph.nodes).toHaveLength(1);
  });
});

async function temporaryGraphDirectory(): Promise<string> {
  const path = await mkdtemp(join(tmpdir(), 'omp-learn-graph-'));
  temporaryDirectories.push(path);
  return path;
}
