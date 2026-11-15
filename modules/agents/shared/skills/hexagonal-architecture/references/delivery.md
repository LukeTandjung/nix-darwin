# Delivery, workflows, and migrations

Read when changing transactions, durable side effects, outbox processing,
workflows, or schema history. For SQL/Effect wiring use
[persistence](effect/persistence.md).

## Same-DB transactions vs transactional outbox

- **Same-process, same-database modules:** compose operations inside **one real
  database transaction** wired at `app/` (Rank 0 or the owning service). Do not
  invent per-module outboxes and async event ping-pong merely to coordinate two
  modules that share one PostgreSQL database.
- **Cross-process or external side effects (queues, webhooks, third-party
  writes):** never hold a database transaction open across arbitrary network
  calls and never rely on post-commit detached fibers. Persist an outbox row in
  the same transaction as the state change, unless synchronous coupled failure
  semantics are explicitly required for the current response.

```text
app/ opens transaction
  use case loads -> core decides -> adapter guards and writes state (+ outbox when external)
commit
  poke outbox processor (latency hint only)
processor claims -> outbound adapter publishes with persisted key -> acknowledge
```

Protect decisions against concurrent changes using locks, expected versions,
constraints, or suitable isolation. A transaction alone does not prevent stale
read decisions, and status-only guards miss changes within the same status. A
conflict or failed outbox append commits neither the mutation nor its event.

## Outbox contract

| Guarantee | Implementation obligation |
| --- | --- |
| Atomic intent | State and outbox row share the same actual database transaction |
| Stable replay identity | Persist event/effect ID before dispatch; never regenerate on retry |
| Concurrent claim safety | `FOR UPDATE SKIP LOCKED` plus explicit claim ownership |
| Crash recovery | Lease/reclaim protocol or equivalent; a released row lock is not a lease |
| At-least-once delivery | Downstream deduplication by stable key; duplicates remain possible |
| Retry recovery | Persist attempts/backoff; retain exhausted work for inspection/repair |
| Missed wakeups | Startup drain plus bounded recovery scan or durable wakeup |
| Shutdown | Stop accepting work, drain within a budget, leave pending work recoverable |

Pokes improve latency; they are not durable delivery. Delayed retries need a
wakeup after their due time. Bound batch size, concurrency, attempts, and
memory. A database commit or HTTP response lost in transit has an **uncertain
outcome**; reconcile by stable identity instead of claiming rollback or issuing
a new logical operation.

## Queue and outbox ownership

- `core/` owns module-private persisted event variants and queue payload schemas;
  move schemas to `domain/*` when one service publishes events another consumes.
- Persistence adapters in `adapters/` write outbox rows atomically with state;
  outbound queue adapters in `adapters/` send claimed batches and translate
  transport errors.
- Inbound consumers in `queue/` decode incoming messages, invoke module `app/`,
  and translate outcomes into ack/retry actions. Keeping producers in `adapters/`
  and consumers in `queue/` prevents `app <-> queue` cycles.
- Rank 0 `app/` starts, pokes, drains, and closes background processors and owns
  their fibers/tasks.

## Durable workflows

A workflow (`workflows/`) is an inbound durable-sequencing trigger, not the home
of business rules or direct I/O. Activities are small adapter/app operations
wired by Rank 0 `app/`. Keep durable step sequencing visible in the workflow
definition rather than hiding an entire multi-step process inside one giant
activity. Deterministic workflow code must use runtime-safe clock, randomness,
and activity APIs—never ordinary host I/O—and expose `workflows/index.ts`
separately from the module's root `index.ts`.

Do not create workflows merely to poll, claim, or drain outbox rows. Pure
discriminated-union transitions or bounded `Schedule` policies usually beat
heavyweight state-machine frameworks unless finite-state complexity justifies one.

## Co-located schemas, one `migrations/` history, single write-owner

```text
<module>/adapters/schema.ts  co-located table definitions (like Django models.py)
platform/db + bin/migrate    aggregates schemas (or runs from Rank 0) into one migrations/ history
migrations/                  one linear DDL timeline per physical DB (shared `public` namespace)
```

- **One `migrations/` folder per physical database, never per service.** Unlike
  Django's built-in cross-app DAG solver, TypeScript/Rust SQL and snapshot tools
  (`drizzle-kit`, Atlas, `sqlx`) expect one linear timeline; per-service
  migration silos break cross-module foreign keys and snapshot differs. Split
  `migrations/` only for physically separate databases.
- **Expose schemas for FKs and read `JOIN`s:** keep all module tables in the
  shared `public` namespace and export table schemas so `platform/db` / Rank 0
  configs and higher-rank callers can declare database foreign keys and write
  read-only `SELECT ... JOIN` queries directly instead of N+1 wrapper calls. In
  multi-package or Cargo workspaces where `platform/db` cannot import upward,
  place tables shared by 2+ services in `domain/*` so imports stay downward.
- **Single write-owner per table:** invariants, optimistic version bumps, and
  outbox appends live on writes. Only the single owning `services/*` or
  `domain/*` module may execute `INSERT`, `UPDATE`, or `DELETE` on its tables;
  other modules mutate that state exclusively through the owner's public barrel.

## Proof to require

- Fail an outbox insert after mutation; prove both roll back.
- Race two writers at the same version; only one mutation/event pair commits.
- Crash after send but before acknowledgement; replay keeps the same key.
- Lose a poke or advance past retry due time; recovery still dispatches.
- Exhaust retries or shutdown budget; pending work is retained and discoverable.
- Use real PostgreSQL for SQL/isolation guarantees; an in-memory fake cannot prove them.
