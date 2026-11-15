---
name: hexagonal-architecture
description: Luke's ranked modular DDD and hexagonal architecture for TypeScript Effect and Rust. Use for workspace ranks (infra/bin/app/services/domain/platform), module anatomy (http/queue/workflows/app/ports/adapters/core), single root barrels, persistence, transactions, outbox, workflows, migrations, and testing.
---

# Ranked modular & hexagonal architecture

**Favour small, deep modules arranged by rank, with hexagonal boundaries inside
services. Use idiomatic Effect or Rust inside them. Read only the recipes needed
for the task—not every linked document.**

## Two pictures: workspace ranks & module anatomy

```text
workspaces/ (or src/ | crates/)
├── infra/       Deploy layer: Alchemy / IaC stacks (may reference bin/ + platform/config)
│   ------------------------------------------------------------------------------------
├── bin/ (apps/) Rank 0: process entrypoints (main, worker, migrate)
├── app/         Rank 0: ONLY composition root (HTTP/queues/workflows, pools, bridges)
├── services/    Rank 1: isolated vertical features & workers (never import siblings)
├── domain/      Rank 2: shared deep domain modules (reused by 2+ services)
└── platform/    Rank 3: generic technical & vendor mechanisms (zero domain rules)
```

Inside any module (`index.ts` or `src/lib.rs` is the **sole** public import surface):

```text
http/ | queue/ | workflows/   inbound protocol triggers -> call app/
app/                          use cases: load -> core decision -> invoke ports/adapters
ports/                        optional capability contracts (>=2 impls or sibling bridge)
core/                         pure values, schemas, invariants, decisions (zero I/O)
-------------------------------------------------------------------------------------
adapters/                     SQL/ORM, row decoding, HTTP clients, queue/outbox writers
tests/                        pure, port-fixture, and real-Postgres tests
```

**There is no repository layer, no per-module `api/` or `impl/` folder, and no
`main/` sub-nesting.** Omit unused inner folders rather than creating empty ceremony.

## Rules that apply to every task

1. **Sink shared capabilities downward.** When two `services/*` need the same
   domain logic or mechanism, extract a deep `domain/*` or `platform/*` module.
   Never copy-paste across services and never import a sibling service directly.
2. **One Ubiquitous Language, context-shaped types.** Keep domain terminology
   exact across the workspace, while shaping each module's types for its own job
   instead of sharing one god-struct or leaking wire DTOs inward.
3. **Earn every inner layer.** Extract pure branching rules to `core/`; omit
   `decide*` wrappers when no rule branches. Add `ports/` only for genuine
   multi-implementation boundaries, external/paid API stubs, or cross-service
   callbacks—not 1-to-1 pass-through wrappers over single-implementation SQL.
4. **Core is pure.** Time, IDs, permissions, and runtime facts arrive as explicit
   data. Pure in-process libraries need no ceremonial ports or adapters.
5. **Top-level `app/` is the composition root.** Modules export cohesive
   functions, types, and Layers via their root barrel (`index.ts` / `lib.rs`);
   Rank 0 `app/` wires runtimes, transactions, and sibling bridges.
6. **Persist atomically; share schemas, guard writes.** Same-DB writes share one
   transaction and one `migrations/` history in `public`; expose co-located table
   schemas for FKs and read `JOIN`s, while keeping one module as sole write-owner.
7. **Parse at trust boundaries; own runtime work.** Preserve validated types and
   branded IDs internally. Bound concurrency, retries, and queues; manage
   lifetimes in the owning scope.

For named Effect operations, default to **`Effect.fn('name')((...) =>
Effect.gen(...).pipe(...))`**: `fn` supplies diagnostics, `gen` expresses flow,
and `.pipe` composes transformations and policy. Aggregate recovery policy in
`app/` composition (`catchTag`/`catchTags`), rather than catching and rethrowing
at every layer. Adapters translate vendor failures; inbound protocol boundaries
(`http/`, `queue/`) present unresolved failures without choosing business recovery.

## Choose what to read

| Task | Read |
| --- | --- |
| Any Effect implementation/review | [Effect entry point](references/typescript-effect.md), then its relevant recipe(s) |
| Scaffold or move folders (`infra/`, ranks, barrels) | [Canonical layouts](references/layout.md) |
| Rank placement, `infra/` vs `platform/`, or dependency rules | [Boundary rules](references/architecture.md) |
| Transactions, durable outbox, workflows, migrations | [Delivery and migrations](references/delivery.md) |
| Rust implementation/review | [Rust adaptation](references/rust.md) |

Read each selected recipe completely. Do not recursively load every link or
preload the Rust reference for TypeScript work. Load `software-design` for design
judgment and `typescript-style` for TypeScript conventions as applicable; the
Effect entry point states how Tiger Style's Node examples are adapted.

## Before implementing

- Classify the target module's rank (`services/`, `domain/`, `platform/`) and
  check whether logic belongs in a deeper shared module instead of a service.
- Name the use case and its situation -> outcome cases, including rejected states.
- Identify the capability owner, atomic write boundary, and durable external effects.
- Show the module's folder layout and deliberate inner-folder omissions. Respect
  established repo conventions (such as `public.ts` + `internal/`) unless
  migrating layout is requested.
- Verify the installed Effect version before copying an API. Do not assume a
  vendored `repos/effect/` exists or mix major versions.

## Before finishing

- [ ] Rank and inner-folder import directions hold; root barrels remain the sole
      cross-module import surface and contain no side effects.
- [ ] No shallow pass-through ports, repository layers, or sibling-service imports.
- [ ] Transport DTOs (`http/`, `queue/`) do not leak into `core/` or `app/`.
- [ ] Typed failures, concurrency protection, and resource lifetimes are explicit.
- [ ] Tests prove behavior at the right level (pure `core/`, port fixtures where
      `app/` branches richly, real PostgreSQL for SQL/isolation/atomicity).
- [ ] Durability work follows the delivery recipe; table schemas may be joined
      for reads/FKs, while each table has a single module write-owner.
- [ ] Report what was verified and any gaps; do not claim a sketch was executed.

If Luke corrects a boundary or convention, fix the work and propose updating the
smallest owning recipe. Keep one authoritative rule rather than duplicating it
across every page.

## Credits

- [rat-stack lore and recipes](https://ratstack.sh/lore)
- [Tim Zolleis's Effect DDD skill](https://github.com/timzolleis/.dotfiles/tree/main/agents/.agents/skills/effect-ddd)
- [Dillon Mulroy's error guide](https://github.com/dmmulroy/cf-workflow-pool/blob/main/docs/errors.md)
  and [coding standards](https://github.com/dmmulroy/cf-workflow-pool/blob/main/docs/coding-standards.md)
- [Effect documentation and source](https://github.com/Effect-TS/effect)
