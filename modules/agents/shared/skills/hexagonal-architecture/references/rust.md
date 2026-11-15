# Rust adaptation

When assisting a learner, explain the direction, relevant traits/types, and
documentation rather than supplying a finished implementation. The snippets here
communicate boundaries only.

## Ranked workspace and crate layout

Favour small, deep crates arranged into the workspace layers inside `crates/`:
optional `crates/infra/*` (deploy/IaC tooling), `crates/apps/*` (Rank 0 binaries
& composition root), `crates/services/*` (Rank 1 vertical features),
`crates/domain/*` (Rank 2 shared domain capabilities), and `crates/platform/*`
(Rank 3 technical & vendor mechanisms).

Never split a single capability into separate `-core`, `-ports`, `-adapters`,
or `-api` crates merely to enforce dependency direction. Enforce inner layer
boundaries with private `mod` declarations inside `src/lib.rs`, selectively
re-exporting only the crate's public surface (`pub use`).

```text
crates/services/{service}/
├── Cargo.toml
├── src/
│   ├── lib.rs          # private `mod`s + selective `pub use` barrel
│   ├── core/           # pure types, newtypes, enums, decisions
│   ├── ports/          # [optional] narrow traits for external/stubbable capabilities
│   ├── adapters/       # SQL/HTTP/queue implementations & test fixtures
│   ├── app/            # use-case functions & recovery policy
│   ├── http/           # [optional] route handlers & wire DTOs
│   ├── queue/          # [optional] inbound message consumers
│   └── workflows/      # [optional] durable workflow definitions
└── tests/              # integration & layer tests (no inline tests in src/)
```

`domain/*` and `platform/*` crates omit unused inner modules (for example, a
pure domain crate contains only `src/lib.rs`, `src/core/`, and `tests/`). Note
that naming an internal module `mod core;` works inside `src/lib.rs`; if macro
expansions inside that crate ever need Rust's built-in `no_std` crate, refer to
`::core::...` (or `std::...`).

Keep production code and tests physically separate: production modules under
`src/` must not contain inline `#[cfg(test)] mod tests` blocks. Put tests under
`tests/` at the crate root.

## Mapping

| Architecture | Rust representation |
| --- | --- |
| Public module surface | `src/lib.rs` with private inner `mod`s and narrow `pub use` |
| Core | Pure functions, state enums, validated newtypes |
| Port (when needed) | Application-owned trait in `ports/` |
| Adapter | Concrete struct/functions in `adapters/` (implements port when one exists) |
| Use case | Function (or cohesive service struct) in `app/` |
| Composition root | Binary crate in `crates/apps/*` wiring pools, routes, and bridges |
| Expected error | Explicit `Result<T, E>` with crate-owned error enum |
| Broken invariant | `panic!` / `assert!` only for programmer defects |

## Libraries and capability boundaries

A Cargo dependency is not automatically an external architectural capability.
A layer may directly import in-process parsers, compilers, UI libraries, codecs,
algorithms, and similar libraries when that layer owns the responsibility. Do
not create shallow port/adapter wrappers merely because implementation code
comes from another crate.

Use an application-owned port when the application needs to invert an external
capability or runtime effect: clocks, filesystem access, system clipboard,
network/RPC, databases, randomness or ID generation, environment access,
queues, or workflow runtimes. Adapters implement those ports.

Statements such as “App depends only on core and ports” describe architectural
module direction; they do not prohibit ordinary Cargo library dependencies
appropriate to that layer. For example:

- Typst parsing or compilation needs no port solely because it uses Typst
  crates.
- GPUI rendering needs no port solely because it uses GPUI.
- GPUI-backed system clipboard access crosses an application-owned clipboard
  port because the clipboard is an external runtime capability.
- Reading monotonic time crosses a `Clock` port. A `SystemClock` adapter may use
  `Instant::now()`, while core receives the resulting timestamp explicitly.

## Crate boundary (`src/lib.rs`) — no `api/` + `impls/` ceremony

Do **not** create separate `api/` traits (`pub trait EditorApi`) and `impls/`
structs (`pub struct EditorApiImpl`) for single-implementation crates. Rust's
module privacy (`mod` vs `pub use`) enforces encapsulation directly without
double indirection:

```rust
// crates/domain/editor/src/lib.rs
mod adapters;
mod app;
mod core;
mod ports;

pub use app::{create_editor, CreateEditorError};
pub use core::{DocumentId, EditorConfig, EditorSession};
pub use ports::Clipboard;
```

Callers outside the crate see only the types, traits, and constructors/functions
re-exported from `src/lib.rs`. Internal adapter structs, SQL row helpers, and
private state remain unreachable by compiler visibility rules. Reserve public
traits for genuine polymorphism (multiple implementations, external runtime
ports like `Clipboard`/`Clock`, or cross-service callbacks wired in `crates/apps/*`).

## Core

Core depends only on core data. Use enums for alternative decisions and newtypes
for validated identifiers.

```rust
pub enum ScheduleDecision {
    Schedule(PendingRun),
    AlreadyRunning(RunId),
}

pub fn decide_schedule(
    input: ScheduleInput,
    current: Option<&AgentRun>,
) -> ScheduleDecision {
    // Pure decision only; time and IDs are already in input.
}
```

Do not read system time, generate randomness, access environment variables,
spawn tasks, or perform I/O in core. In particular, core must not call
`Instant::now()` or otherwise read runtime time; a `Clock` port and
`SystemClock` adapter provide an explicit time value to core.

## Ports (when polymorphism is earned)

Add a trait in `ports/` when the crate must invert an external runtime effect,
swap providers, stub a paid/network API in tests, or callback into a sibling
service from `crates/apps/*`. Do not add 1-to-1 pass-through traits around
in-process `domain/*` crates or single-implementation SQL tested directly
against PostgreSQL unless unit-level `app/` branching tests earn the seam.

```rust
pub trait AgentRunStore {
    type Error;

    async fn find_active(
        &self,
        tx: &mut TransactionContext,
        agent_id: &AgentId,
    ) -> Result<Option<AgentRun>, Self::Error>;

    async fn insert(
        &self,
        tx: &mut TransactionContext,
        run: PendingRun,
    ) -> Result<AgentRun, Self::Error>;
}
```

Choose static dispatch (`impl Trait`/generics) by default. Use `dyn Trait` when
runtime adapter selection or heterogeneous storage is a real requirement. Do not
add `Arc`, `Box`, `Send`, or `Sync` reflexively; add them where
runtime/concurrency boundaries require them.

## Use cases

Use cases are functions over the narrow traits they need. They load, call pure
decisions, and persist state plus outbox within one real transaction.

```rust
pub async fn schedule_agent<S, C, I>(
    store: &S,
    clock: &C,
    ids: &I,
    tx: &mut TransactionContext,
    input: ScheduleAgentInput,
) -> Result<AgentRun, ScheduleAgentError>
where
    S: AgentRunStore,
    C: Clock,
    I: IdGenerator,
{
    // load -> decide -> write state and outbox
}
```

This is an architectural signature, not a mandate to accumulate many generic
parameters. If the dependency list grows, define one cohesive
application-dependencies record only when it lowers cognitive load.

## Persistence ports and adapters

There is no separate repository layer. Application-owned port traits describe
cohesive storage capabilities. Postgres adapters implement them directly and own
SQL/query bindings, transaction-executor use, row decoding, and database-specific
types. Query helpers stay private inside the adapter; driver shapes must not
define app contracts.

- Postgres adapters own SQL/driver knowledge and map rows into core/application
  types.
- Translate driver errors into adapter/service-owned error types at the
  boundary.
- RPC/HTTP/queue adapters translate transport shapes; internal layers never use
  transport DTOs as domain types.
- In-memory adapters implement the same traits and own state per test instance.
- Avoid global mutable state.

## Errors

- Expected outcomes are enums or `Result` variants.
- Port errors are associated or concrete service-owned error types.
- Adapter internals may retain source errors for diagnostics without exposing
  vendor APIs throughout app code.
- Do not use `unwrap`/`expect` in request paths for recoverable conditions.
- Panic only for impossible states or programmer defects.

## Transactions and outbox

Use the actual transaction type directly or hide it behind one concrete opaque
context understood by Postgres adapters. Do not build a generic unit-of-work
framework. Do not open one transaction per port operation when a use case
requires atomicity.

Cross-process effects follow the same persisted outbox policy as TypeScript
services. The processor must claim safely, preserve idempotency keys, and
tolerate at-least-once delivery.

## Async and concurrency

- Keep core synchronous and deterministic.
- Async belongs in app orchestration, adapters, and wiring.
- Spawn tasks only in wiring/process-management code unless task ownership and
  shutdown semantics are explicit.
- Cancellation, resource ownership, and graceful shutdown are wiring concerns.
- Do not hold a database transaction across arbitrary external network calls;
  commit an outbox event instead.

## Composition root (`crates/apps/*`) and queue/outbox ownership

Binary crates in `crates/apps/*` are the Rank 0 composition root: they parse
startup config once via `platform/config`, construct pools and concrete
adapters, open transactions around multi-step operations, mount `http/`,
`queue/`, and `workflows/` surfaces, bridge sibling `services/*` crates, and own
task lifecycles and graceful shutdown.

- `core/` (or a shared `domain/*` crate) owns persisted outbox event variants
  and queue message schemas.
- `adapters/` writes outbox rows in the state transaction and implements
  outbound queue publishers.
- `queue/` implements inbound queue consumers calling `app/`, avoiding
  producer/consumer cycles.
- `workflows/` contains only deterministic durable-runtime sequencing.
- Spawned outbox and worker tasks are owned, cancelled, and drained by the
  binary's composition root; detached background tasks are forbidden.

## Testing

All tests live under the crate-level `tests/` directory, never inline with
production modules under `src/`. Choose the smallest honest test level:

- Pure `core/` rules and parsers: table-driven and property tests.
- Rich `app/` branching/recovery: fast tests over in-memory port implementations
  with deterministic `Clock`/`IdGenerator` adapters.
- `adapters/` and SQL-backed flows: integration tests against real PostgreSQL
  and real protocol boundaries.
- `crates/apps/*`: critical composition and E2E paths only.

Use valid newtype identifiers. Test in-process libraries directly in the owning
crate rather than inventing a port merely to mock a Cargo dependency. Keep
`src/lib.rs` narrow; do not make adapter internals `pub` solely for trivial
forwarding tests.

## Rust-specific checks

- [ ] Crates are small, deep, and placed in the right workspace rank
      (`apps/`, `services/`, `domain/`, `platform/`) with zero sibling-service imports.
- [ ] Inner layers are private `mod`s in `src/lib.rs`, not separate per-layer crates
      and not `api/` + `impls/` trait-forwarding boilerplate.
- [ ] Tests live under `tests/`; production modules under `src/` contain no inline
      `#[cfg(test)]` modules.
- [ ] Port traits belong to the consuming crate (`ports/`) and exist only for real
      external/runtime capabilities, stubs, or multi-provider seams.
- [ ] In-process Cargo libraries and `domain/*` crates are called directly without
      ceremonial wrapper traits.
- [ ] `core/` remains synchronous and pure; runtime time enters via a `Clock` port
      and explicit values.
- [ ] Validated newtypes protect identifiers; `Result`/enums model expected outcomes
      with no recoverable-path `unwrap`/`expect`.
- [ ] Generic bounds remain narrow; `dyn Trait`, `Arc`, `Send`, and `Sync` appear
      only for real runtime needs.
- [ ] No repository layer exists; SQL adapters own queries, row decoding, and
      error translation, and transactions never span arbitrary network calls.
- [ ] Transport DTOs (`http/`, `queue/`) do not leak into `core/`, `ports/`, or `app/`.
- [ ] Async tasks and outbox processors have explicit ownership, cancellation,
      and shutdown draining in `crates/apps/*`.
