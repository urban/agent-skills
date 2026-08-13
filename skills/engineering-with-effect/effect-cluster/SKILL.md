---
name: effect-cluster
description: Decide when Effect Cluster entity semantics fit, then design identity, message protocols, state ownership, concurrency, persistence, delivery errors, runners, and public client tests. Use for stateful per-identity behavior, not generic RPC.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Use an entity when per-identity state, serialized message handling, passivation, or clustered placement is essential.
- Define the message protocol before handlers; payload, success, business errors, primary key, and persistence annotations are durable contracts.
- Keep per-entity state inside entity construction and hide raw sharding/entity clients behind domain capabilities where appropriate.
- Choose sequential or concurrent handling from state-transition safety, not throughput preference alone.

## Constraints

- Effect Cluster is currently exposed through an unstable v4 module surface; verify imports and API details against the installed release.
- Persisted messages require storage, deterministic identity, replay safety, and duplicate-handling policy.
- Delivery failures and business failures are separate contracts.
- Fire-and-forget client semantics do not remove server-side durability or error considerations.

## Knowledge Boundaries

Applies to:

- entity suitability, identity, state, passivation, and handler concurrency
- RPC schemas, delivery failures, persistence, primary keys, and transactions
- test, local, and clustered runner composition
- domain/proxy adapters and public-client verification

Does not cover:

- stateless RPC, simple queues, or durable orchestration better modeled as workflows
- generic service and schema syntax

Decision inputs:

- state partition key and ownership
- ordering and concurrency invariants
- replay/idempotency and persistence guarantees
- caller response to mailbox, duplicate, persistence, or transport failure

## Patterns

- Keep default sequential processing when handlers mutate shared entity state. Fork only read-only or commutative work with explicit safety reasoning.
- Put business validation failures in RPC schemas. Translate cluster delivery failures at the boundary that can choose retry, backpressure, conflict, or unavailability behavior.
- Use stable primary keys for commands that must deduplicate or reject duplicate in-flight work.
- Keep runner, storage, shard configuration, and proxy generation at infrastructure edges.
- Test through entity clients or domain services. Inspect storage internals only for persistence, replay, deduplication, or transaction semantics.

## Gotchas

- Using Cluster as a generic RPC wrapper adds placement, mailbox, passivation, and delivery complexity without stateful benefit.
- Module-level state survives and shares differently from entity state, breaking passivation and restart assumptions.
- Forking stateful handlers introduces races within one identity despite actor-style expectations.
- Persistence without idempotent effects replays external side effects after retries or recovery.
- Mapping mailbox-full and duplicate-processing to one internal error prevents callers from applying backpressure or conflict handling.
- Handler-only tests miss serialization, entity identity, mailbox, and delivery behavior.

## References

- [`references/entity-protocols-and-state.md`](./references/entity-protocols-and-state.md): Read when: deciding entity suitability, message schemas, state ownership, concurrency, or passivation.
- [`references/persistence-delivery-and-runners.md`](./references/persistence-delivery-and-runners.md): Read when: choosing persistence, primary keys, delivery-error mapping, proxies, runner layers, or tests.
