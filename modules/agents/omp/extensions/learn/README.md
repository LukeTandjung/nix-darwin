# Adaptive learning for OMP

A Pi-native learning workflow inspired by LearnHarness. OMP supplies the agent, session history, model providers, tool UI, compaction, and terminal interface; this extension adds only the learning state and persistent knowledge.

## Commands

```text
/learn <goal>             Start a lesson in the current OMP session
/learn status             Show phase, plan, and check status
/learn graph              Render the current knowledge graph as Mermaid
/learn new <goal>         Replace the current workflow explicitly

/practice <topic>         Start conversational retrieval practice
/practice status          Show active problem and outcome count
/practice new <topic>     Replace the current workflow explicitly
```

A lesson proceeds through probing, a validated dependency plan, and one checked reasoning step at a time. Each check commits its answer before the question is shown. A lesson can complete only when every plan node’s latest check is `held`.

Practice commits the solution before posing each problem. Concluding reveals the solution and records the diagnosis, then waits for an explicit request for another problem.

Lesson and practice state uses OMP’s branch-aware custom session entries. It therefore follows normal session resume and branch navigation. Learning tools are inactive in ordinary coding sessions and activate only for these workflows.

## Persistent knowledge

`learning_remember` stores objective propositions and reasoning chains during teaching. `learning_graph_search` retrieves them in later lessons and practice sessions. Identical normalized text is deduplicated; `sameAs` explicitly merges another phrasing into an existing identity. `/learn graph` deterministically renders the stored propositions and complete reasoning chains as Mermaid without starting an agent turn. Large displays are limited to the first 100 propositions.

The default storage location is:

```text
${XDG_STATE_HOME:-~/.local/state}/omp/learn/
├── nodes.jsonl
├── chains.jsonl
└── .write-lock.sqlite
```

Set `OMP_LEARN_DIR` to override that directory. Assertions carry the OMP session ID and lesson ID as provenance. A SQLite transaction serializes read–merge–append writes across OMP processes and releases automatically if a writer exits. Graph extraction is model-driven during teaching; there is no separate background extraction or identity-auditing service.

## Verification

From the repository root:

```bash
nix shell nixpkgs#bun -c bun test \
  modules/agents/omp/extensions/learn/state.test.ts \
  modules/agents/omp/extensions/learn/graph.test.ts \
  modules/agents/omp/extensions/learn/graph-mermaid.test.ts
```

The tests have no package-install or network requirement.
