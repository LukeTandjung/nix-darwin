# Canonical layouts

Read when scaffolding, moving files, or checking module ownership. Map external
examples into these ranks and folders; respect an existing repository's naming
conventions (for example `public.ts` + `internal/` in legacy trees) unless a
layout migration is requested.

## Workspace topology

Every file path encodes two facts: its **workspace rank** (outer folder) and its
**architectural role** (reserved inner folder).

### TypeScript workspace

```text
repo-root/
├── migrations/                 # Single linear migration history per physical database
└── workspaces/ (or src/)
    ├── infra/                  # Deploy layer: Alchemy (alchemy.run.ts, stacks/) / IaC
    │   └── ...                 #   provisions cloud resources & bundles bin/; never imported by runtime
    ├── bin/                    # Rank 0: process entrypoints (main.ts, worker.ts, migrate.ts)
    ├── app/                    # Rank 0: ONLY composition root (HTTP/MCP mount, queues, bridges)
    ├── services/               # Rank 1: isolated vertical product surfaces & workers
    │   └── <service>/
    │       ├── index.ts        # sole cross-module public barrel
    │       ├── core/           # pure types, branded IDs, state unions, real decisions
    │       ├── ports/          # [optional] >=2 impls, external/paid stubs, or sibling callbacks
    │       ├── adapters/       # owned schema.ts, SQL/ORM queries, HTTP clients, outbox writers
    │       ├── app/            # use-case orchestration & recovery policy
    │       ├── http/           # [optional] HTTP/MCP/RPC routes, wire DTO codecs, status mapping
    │       ├── queue/          # [optional] inbound queue consumer handlers & ack/retry mapping
    │       ├── workflows/      # [optional] deterministic workflow definitions (separate index.ts)
    │       └── tests/
    ├── domain/                 # Rank 2: small, deep domain modules shared by 2+ services
    │   └── <capability>/
    │       ├── index.ts        # small, deep public API
    │       ├── core/           # pure domain models, parsers, matching/pricing algorithms
    │       ├── ports/          # [rare] only when multiple providers exist
    │       ├── adapters/       # [optional] owned schema.ts, domain queries, or provider readers
    │       ├── app/            # [optional] multi-step domain orchestration
    │       └── tests/
    └── platform/               # Rank 3: generic technical & vendor anti-corruption modules
        └── <mechanism>/
            ├── index.ts        # clean technical capability API
            ├── core/           # [optional] pure config schemas, wire parsers, backoff math
            ├── adapters/       # SDK client, DB pool, rate limiter, telemetry, queue driver
            └── tests/
```

### Rust Cargo workspace

Favour small, deep crates grouped into the same workspace layers (`infra` when
Rust IaC/deploy tooling exists, `apps`, `services`, `domain`, `platform`).
Enforce inner layer boundaries with private `mod` declarations inside
`src/lib.rs`, never by splitting one feature into separate `-core`, `-ports`,
`-adapters`, or `-api` crates.

```text
repo-root/
├── migrations/
├── Cargo.toml
└── crates/
    ├── infra/                  # [optional] Deploy layer crate (never imported by runtime crates)
    ├── apps/                   # Rank 0: binary crates (src/main.rs + composition root)
    │   └── <binary>/
    ├── services/               # Rank 1: vertical service crates
    │   └── <service>/
    │       ├── Cargo.toml
    │       ├── src/
    │       │   ├── lib.rs      # private `mod`s + selective `pub use` barrel
    │       │   ├── core/
    │       │   ├── ports/      # [optional]
    │       │   ├── adapters/
    │       │   ├── app/
    │       │   ├── http/       # [optional]
    │       │   ├── queue/      # [optional]
    │       │   └── workflows/  # [optional]
    │       └── tests/
    ├── domain/                 # Rank 2: shared deep domain crates
    │   └── <capability>/
    │       ├── Cargo.toml
    │       ├── src/
    │       │   ├── lib.rs
    │       │   ├── core/
    │       │   └── adapters/   # [optional]
    │       └── tests/
    └── platform/               # Rank 3: technical & vendor crates
        └── <mechanism>/
            ├── Cargo.toml
            ├── src/
            │   ├── lib.rs
            │   └── adapters/
            └── tests/
```

## Allowed inner folders by rank

| Rank | Job | Allowed inner folders | Never contains |
| --- | --- | --- | --- |
| `infra/` (Deploy layer) | Cloud resources, IaC stacks, build/deploy wiring | Stack/resource files, `tests` | Runtime business logic (standalone HCL like Terraform may sit at repo root) |
| `bin/` + `app/` (Rank 0) | Process entrypoints & single composition root | Entry files, route/worker mounts, cross-service bridges | Domain rules, raw SQL queries |
| `services/*` (Rank 1) | Isolated user-facing features & background workers | `core`, optional `ports`, `adapters`, `app`, optional `http`/`queue`/`workflows`, `tests` | Imports from sibling `services/*` |
| `domain/*` (Rank 2) | Deep, caller-agnostic domain capabilities | `core`, optional `ports`/`adapters`/`app`, rare `workflows`, `tests` | `http/`, `queue/`, product-surface policies |
| `platform/*` (Rank 3) | Technical plumbing & vendor wrappers | Optional `core`, `adapters`, `tests` | `app/`, `http/`, `queue/`, `workflows/`, domain concepts |

## Folder hygiene and barrel safety

- **Omit unused inner folders.** A pure `domain/locale` module needs only
  `index.ts`, `core/`, and `tests/`. Do not create empty folders, `main/`
  subdirectories, or per-layer `test/` folders.
- **Never invent catch-all buckets.** Avoid `helpers/`, `utils/`, `common/`,
  `managers/`, `handlers/`, `commands/`, `queries/`, `api/`, or per-module
  `impl/` (`impls/`). Name files after domain concepts and intent-specific
  actions (`archiveInvoice`, `classifyProduct`, `listPaidIds`).
- **Three barrel rules:**
  1. **No self-root imports:** files inside `<rank>/<module>/*` import sibling
     layer barrels (`../core`, `../ports`), never their own root `index.ts` (prevents
     circular ESM initialization).
  2. **Pure re-exports only:** `index.ts` barrels contain `export { ... } from './...'`
     and `export type { ... } from './...'` with zero top-level side effects so
     bundlers tree-shake cleanly.
  3. **Separate workflow entry:** when `workflows/` exists, expose
     `workflows/index.ts` separately from root `index.ts` so deterministic
     workflow bundles never pull in Node, database, or HTTP adapters.
- **Keep tests at module root (`tests/`).** Rust production files under `src/`
  contain no inline `#[cfg(test)] mod tests` blocks.
