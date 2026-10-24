---
name: effect-cluster
description: Design Effect Cluster entity identity, protocols, activation state, concurrency, persistence, delivery guarantees, and runner ownership. Use for stateful per-identity behavior and its public-client tests, not generic RPC.
---

## Rules

- Use an entity when per-identity coordination, serialized message handling, passivation, or clustered placement is essential; do not build a parallel actor registry or placement loop.
- Treat entity type, entity ID, RPC tag, payload, result, and command primary key as protocol contracts, including compatibility with stored requests and replies.
- Allocate per-identity state in the effect passed to `Entity.toLayer`; reconstruct authoritative state from durable storage rather than assuming an activation survives.
- Choose concurrency from state-transition safety, not throughput preference alone. Default sequential handling is local to one entity activation, not a cross-entity transaction.
- Separate business outcomes from delivery failures at the domain or proxy boundary, where callers can choose backpressure, retry, or unavailability behavior.
- Keep runner transport, storage, and shard configuration at infrastructure edges; expose domain capabilities instead of leaking raw clients where that would obscure ownership.

## Constraints

- This guidance targets Effect v4's unstable `effect/cluster` surface.
- `ClusterSchema.Persisted` persists mailbox requests and replies, not entity memory, and requires a real `MessageStorage` implementation.
- Durable delivery does not make external side effects exactly-once. Handlers must tolerate replay after defects, ownership changes, and transaction failures.
- Discard sends do not report handler completion or business failure; volatile discard is not durable submission.

## Knowledge Boundaries

Applies to:

- entity suitability, identity, activation state, passivation, and concurrency
- protocol compatibility, delivery failures, persistence, deduplication, and transactions
- test, single-process, and distributed runner ownership
- domain/proxy adapters and public-client tests

Does not cover:

- stateless RPC, simple queues, or durable orchestration better modeled as workflows
- generic service and schema syntax

Decision inputs:

- partition key, authoritative state store, and reconstruction cost
- ordering and concurrency invariants
- replay/idempotency and command identity semantics
- caller response to storage, capacity, or routing failure

## Patterns

- Keep default sequential processing for shared state transitions. `Rpc.fork` bypasses that serialization; reserve it for work whose overlap is safe.
- Use persisted command primary keys to identify one logical operation across retries, not to represent a business lock. Duplicates can join the original request or reuse its stored reply.
- Design recovery and passivation together: a new activation must rebuild usable state even when earlier requests have already completed and will not replay.
- Match tests to the boundary: `Entity.makeTestClient` for per-ID behavior; `TestRunner.layer` with the real entity client for mailbox and recovery semantics; SQL and transport tests for guarantees the in-memory runtime cannot prove.

## Gotchas

- A persisted counter stored only in a `Ref` resets after passivation: mailbox durability is not state persistence. Store authoritative transitions durably and rebuild activation state.
- Raising entity concurrency or returning `Rpc.fork` can overlap handlers for the same ID. Keep state transitions serialized unless the domain proves overlap safe.
- Reusing a command key with a changed payload can return the old result rather than run the new intent. Give distinct operations distinct keys and handle conflicting reuse explicitly.
- Retrying a payment after a handler defect can charge twice even with persisted messages. Carry the logical command key into the external system's idempotency contract.
- Treating `AlreadyProcessingMessage` as a business conflict confuses duplicate envelopes with domain contention. Storage-backed duplicate calls normally observe the original operation; model conflicts in the RPC's business errors.
- Returning success from a discard endpoint means submission, not successful handling. Use request/reply when the caller needs the business outcome.
- A passing `makeTestClient` test does not prove serialization, persistence, or shard handoff; exercise those boundaries with the runtime that owns them.
- Starting several `SingleRunner` processes does not create a distributed cluster: its communication and health services are no-ops. Use coordinated runner storage and a real transport for multiple runners.

## References

- [`references/entity-protocols-and-state.md`](./references/entity-protocols-and-state.md): Read when: deciding entity identity, protocol compatibility, state ownership, concurrency, or passivation.
- [`references/persistence-delivery-and-runners.md`](./references/persistence-delivery-and-runners.md): Read when: choosing persistence, command keys, transactions, delivery-error mapping, proxies, runner layers, or recovery tests.
