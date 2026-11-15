# Boundary rules

Read for rank placement, DDD boundaries, ownership decisions, or dependency
reviews. For directory trees use [layouts](layout.md); for Effect code select
the [Effect recipes](typescript-effect.md).

## Strategic DDD: ranks, deep modules, and language

- **Sink shared capabilities downward (Ousterhout + Rust crate granularity):**
  separate general-purpose mechanisms and shared domain capabilities from
  product-surface orchestration. When two `services/*` need the same capability
  (for example, resilient product-page reading, price math, or rate-limited API
  calls), extract one deep `domain/*` or `platform/*` module with a narrow
  public interface instead of duplicating shallow versions inside each service.
- **One Ubiquitous Language, context-shaped types:** use exact domain terms
  consistently across the codebase (`business` vs `tenant`, `candidate` vs
  `canonical`), while keeping each module's types narrow and specific to its
  bounded responsibility. Do not pass one repo-wide god-entity across every
  module or reuse HTTP/queue DTOs as internal domain models.
- **Deploy plane vs runtime plane:** keep `infra/` (deploy time) strictly above
  and separate from `platform/` (request/job time).

## Vocabulary

- **Inbound trigger (`http/`, `queue/`, `workflows/`):** protocol entry that
  decodes external input, calls `app/`, and maps results/failures to wire output.
- **Use case (`app/`):** orchestration that loads facts, asks `core/` to decide
  when rules branch, invokes `ports/` or `adapters/`, and owns recovery policy.
- **Port (`ports/`):** an application-owned contract for an external, stubbable,
  or cross-service capability.
- **Adapter (`adapters/`):** concrete I/O implementation (SQL/ORM, HTTP client,
  outbound queue producer/outbox writer, or in-memory test fixture).
- **Composition root (Rank 0 `app/`):** process-level wiring that mounts inbound
  triggers, supplies pools/Layers/transactions, and bridges sibling services.

Prefer functions, records, and discriminated unions. Service/tag classes declare
Effect runtime capabilities; Rust structs/traits express data and contracts, not
object-oriented entity hierarchies.

## Who owns what?

| Concern | Owner | Not here |
| --- | --- | --- |
| Cloud resources, IaC stacks, build/deploy | `infra/` | `platform/`, runtime modules |
| Process startup, pools, sibling-service bridges | Rank 0 `bin/` + `app/` | Business rules, raw SQL |
| Wire DTO decode/encode, status codes, acks | `http/` or `queue/` | `core/`, `app/`, `adapters/` |
| Deterministic durable step sequencing | `workflows/` | Direct DB/HTTP I/O, complex branching rules |
| Validated IDs, pure schemas, invariants, decisions | `core/` | Clock reads, I/O, logging, `process.env` |
| Multi-impl / stubbable / sibling capability contract | `ports/` | SQL, SDK clients, concrete Layers, 1-impl wrappers |
| Loading facts, orchestrating steps, recovery policy | Module `app/` | Vendor SDKs, SQL queries, HTTP status codes |
| Co-located `schema.ts`, SQL queries, HTTP/queue I/O | `adapters/` | Separate repository layer, cross-module table writes |

### Deploy plane (`infra/`) vs runtime `platform/`

Use a 2-second test to separate them:

- **`platform/` runs at request/job time** inside the live process (opening a
  Postgres pool, checking a Redis rate limit, calling a third-party HTTP API).
- **`infra/` runs at deploy time** (`alchemy deploy`, `terraform apply`) to
  provision cloud resources (databases, queues, buckets, secrets) and bundle or
  deploy `bin/` entrypoints.

`infra/` lives inside the workspace (`workspaces/infra/`, `src/infra/`, or
`crates/infra/`) so it shares typechecking, linting, and tests—never inside
`platform/`. Because `infra/` points **downward** at `bin/` entrypoints,
`migrations/`, and shared env/queue-name contracts in `platform/config`, placing
IaC inside Rank 3 `platform/` would invert the dependency graph and risk leaking
deploy-only SDKs or cloud-admin credentials into production bundles.

- **Zero upward imports:** runtime code (`bin/`, `app/`, `services/`, `domain/`,
  `platform/`) never imports `infra/`. The application runs identically under
  Alchemy, Terraform, Docker Compose, or a test runner.
- **Crossing the boundary at `bin/`:**
  - **Node / Docker / ECS:** `infra/` injects `process.env` and secrets; `bin/`
    parses them once at startup via `platform/config` before calling `app/`.
  - **Cloudflare Workers (Alchemy):** `infra/` binds queues, R2, D1, or
    Hyperdrive onto the Worker `env`; `bin/worker.ts` receives `env` at the
    outer handler, wraps raw bindings through `platform/*` adapters, and passes
    clean capabilities into `app/` and `services/*`.

### Inbound triggers (`http/`, `queue/`, `workflows/`)

`http/`, `queue/`, and `workflows/` are strictly inbound into module `app/`.
Decode untrusted input at the edge, map explicitly to `app/` inputs, and project
unresolved failures to intentional public codes/statuses or queue ack/retry
decisions without leaking raw internal causes.

**Prevent inbound/outbound queue cycles:** `queue/` contains **inbound consumers
only** (decoding messages and calling `app/`). Outbound queue producers and
outbox writers live in `adapters/`, and shared message payload schemas live in
`core/` (or `domain/*` when published by one service and consumed by another).
`app/` never imports `http/`, `queue/`, or `workflows/`.

### Core, app, and earning inner layers

```text
request + loaded facts + runtime values
                 |
                 v
      pure core decision (when rules branch)
                 |
                 v
     app executes & owns recovery policy
```

- Put genuine branching decisions, invariants, parsers, and state transitions in
  `core/`. Receive time, generated IDs, and actor permissions as explicit data.
- When an operation has no pure branching rule (for example, a bounded read or
  straightforward write), do not invent a pass-through `decide*` function in
  `core/` just to satisfy ceremony.
- Define intent-specific operations (`archiveInvoice`), not generic CRUD update
  bags. Aggregate `catchTag`/`catchTags` recovery at `app/` composition rather
  than catching and rethrowing in every helper.

### When does a capability need `ports/`?

```text
Multiple implementations, paid/external API stub,  -> port in ports/ + impls in adapters/
sibling-service callback, or rich app unit fixture?

Module-owned SQL tested against real Postgres,     -> concrete functions/Layer in adapters/
or shared Rank 2/3 module (`domain/*`, `platform/*`)?  (no pass-through port needed)

Pure in-process library (parser, math, codec)?     -> import directly in the owning layer
```

- Bundle port methods by cohesive capability; avoid both one-method tags and god ports.
- Describe absence, ordering, limits, consistency, conflicts, and replay guarantees.
- Stateful modules co-locate their table definitions (`adapters/schema.ts`),
  re-exported so migration tooling, foreign keys, and cross-module read `JOIN`s
  work on the shared `public` database namespace without N+1 wrapper ceremony
  (sink shared tables to `domain/*` so Rank 1 `services/*` import them downward).
  **Writes remain strictly single-owner:** never `INSERT`, `UPDATE`, or `DELETE`
  another module's tables directly.
- Adapters decode rows (including branded IDs) and translate vendor errors into
  module-owned error types. There is no separate repository layer.
- Adapter state belongs to an instance/Layer construction, never a module-global `Map`.

### Sibling-service decoupling and preventing Rank 0 `app/` bloat

- `services/A` must never import `services/B`. When `A` must trigger `B`
  synchronously, `services/A/ports/` defines a narrow callback contract in `A`'s
  language and Rank 0 `app/` bridges it to `services/B`. When communication is
  asynchronous, move the shared event schema to `domain/*`.
- Keep Rank 0 `app/` thin: each module exposes cohesive public operations,
  constructors, or Layers from its root barrel (`index.ts` / `lib.rs`) so Rank 0
  `app/` wires shared pools, credentials, transactions, and cross-service
  bridges—not internal module helpers.

## Path-based dependency rules

| Path scope | May import | Must not import |
| --- | --- | --- |
| `infra/**` | `platform/config`, `bin/*` entrypoints | Runtime internals for execution |
| Outside `<rank>/<mod>/` | `<rank>/<mod>` root barrel (`<rank>/<mod>/workflows` for workers) | `<rank>/<mod>/{core,ports,adapters,app,http,queue}/*` |
| `bin/**`, `app/**` (Rank 0) | `services/*`, `domain/*`, `platform/*` | `infra/`, module internals bypassing root barrels |
| `services/<A>/**` (Rank 1) | `domain/*`, `platform/*` | `services/<B>/**`, `app/`, `bin/`, `infra/` |
| `domain/<A>/**` (Rank 2) | Lower `domain/<B>` (acyclic), `platform/*` | `services/*`, `app/`, `bin/`, `infra/` |
| `platform/<A>/**` (Rank 3) | Lower `platform/<B>` (acyclic) | `domain/*`, `services/*`, `app/`, `bin/`, `infra/` |
| Inside `<rank>/<mod>/` | `{http,queue,workflows} -> app -> {ports,adapters} -> core` | Reverse arrows; `core/` importing I/O or runtime services |

Enforce these rules mechanically with path-based lint or Cargo workspace checks,
testing both allowed and forbidden imports (including re-exports).

## Types retain their evidence

The module owning an entity owns its branded ID schema/newtype and re-exports it
from its root barrel; consumers reuse that contract rather than inventing
duplicate brands. Parse untrusted HTTP, queue, RPC, and DB inputs once at the
boundary. Do not widen validated values to `unknown`, reparse them internally,
or cast lost types back into place. Map fields explicitly across representation
boundaries; spreads are fine within a layer when invariants hold.

## Incremental migration

1. Sink duplicated cross-service logic into deep `domain/*` or `platform/*` modules.
2. Collapse unnecessary `api/`, per-module `impl/`, `main/`, and repository
   wrappers behind a clean root barrel (`index.ts` / `lib.rs`).
3. Extract pure branching decisions and branded types into `core/`.
4. Move SQL/row decoding and external clients into `adapters/`; keep `ports/`
   only where multiple implementations or stubs earn their keep.
5. Separate inbound `queue/` consumers from outbound `adapters/` producers.
6. Move process composition and transaction/bridge wiring to Rank 0 `app/`.
