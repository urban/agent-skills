---
name: effect-cluster
description: Model stateful per-identity behavior with Effect Cluster entities, typed RPC protocols, runner layers, persistence annotations, proxy adapters, and public-client tests. Use when designing or modifying Cluster entities, entity RPCs, sharding runners, persistent messages, entity proxies, actor-style state, or tests around clustered stateful behavior.
---

## Native Effect Standards

- Treat Cluster as an actor/entity runtime for stateful, per-identity behavior. Do not use it as a generic RPC wrapper for stateless services.
- Model the public message protocol with `Rpc.make` and `Schema` before writing handlers. The protocol is the durable boundary.
- Keep domain behavior behind `Context.Service` services. Entity clients are an infrastructure detail that services can use internally.
- Use `Entity.make("Name", [rpcs])` for the entity definition and `Entity.toLayer(...)` for the implementation.
- Prefer `TestRunner.layer` or `Entity.makeTestClient` for tests, `SingleRunner.layer` for local durable single-node workflows, and `NodeClusterSocket.layer` / `NodeClusterHttp.layer` for live runners.
- Use `ClusterSchema.Persisted` only when the message can be replayed safely and the environment provides `MessageStorage`.
- Keep error channels precise. Business failures belong in RPC error schemas. Cluster delivery failures are typed as cluster errors such as `MailboxFull`, `AlreadyProcessingMessage`, and `PersistenceError`.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not pass `Sharding`, entity clients, `MessageStorage`, or runner internals through domain APIs.
- Do not use Cluster for stateless CRUD or one-off background tasks when a normal service, queue, or workflow is simpler.
- Do not keep production entity state in module-level mutable variables. Put per-entity state in `toLayer` and shared dependencies in services.
- Do not use `Rpc.fork` for handlers that mutate the same state unless the mutation is safe under concurrency.
- Do not mark RPCs persisted without a storage layer and an idempotency/replay story.
- Do not throw global `Error` values for expected failures.
- Do not erase delivery failures into `unknown`, `Error`, or generic `InternalError` types.
- Do not use wall-clock sleeps in cluster tests unless the test is intentionally live/networked. Prefer `TestClock.adjust(...)`, explicit queues, scoped fibers, and `sharding.pollStorage`.
- Do not hand-roll socket clients, serialization, shard assignment, or message persistence. Use the provided runner layers and storage modules.
- Do not edit or import from `.dotai/repos/effect`; it is reference material only.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- entity identity and state ownership model
- RPC payload, success, error, persistence, and primary-key schemas
- runner choice for tests, local workflows, or live cluster
- domain service boundary that should hide raw entity clients

Effect-native code should tend toward:

- typed entity definitions and handler layers
- domain services that wrap entity clients and map delivery failures
- runner compositions for test/local/live use
- tests through public entity clients or domain services

Applies to:

- applying Effect Cluster patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for designing entity protocols, persistence, proxying, or runner composition.
- Confirm Cluster is appropriate for stateful per-identity behavior; use a normal service, queue, or workflow for stateless work.
- Define RPC schemas and business error schemas before handler code; treat the protocol as the durable boundary.
- Put per-entity mutable state inside `Entity.toLayer` and use sequential handlers unless concurrency is explicitly safe.
- Wrap entity clients in a domain service and map cluster delivery errors there.
- Choose persistence annotations only with storage, idempotency, replay, and primary-key semantics understood.
- Test via `Entity.makeTestClient`, `TestRunner.layer`, or the domain service instead of invoking handler internals.

## Gotchas

- If Cluster is used as a generic RPC wrapper, actor runtime complexity leaks into stateless CRUD. Use Cluster only when per-identity state and delivery semantics matter.
- If RPC schemas are written after handlers, accidental implementation shapes become the public protocol. Define the durable message contract first.
- If state lives in module-level variables, passivation and restart semantics are wrong. Keep per-entity refs, queues, and caches inside `toLayer`.
- If `Rpc.fork` is used around shared mutable state, handlers can race inside one entity. Keep default sequential processing unless the operation is safe concurrently.
- If persisted RPCs lack `MessageStorage` or replay idempotency, recovery becomes invalid or defects at runtime. Add persistence only with storage and duplicate-handling policy.
- If delivery failures are erased into `UnknownError`, callers cannot react to mailbox, duplicate, or persistence problems. Map cluster errors explicitly at the service boundary.

## References

- [`references/patterns-01-effect-cluster-patterns-for-agents.md`](./references/patterns-01-effect-cluster-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Cluster patterns for agents, First principles, Behavior encapsulation.
- [`references/patterns-02-put-business-errors-in-rpc-schemas.md`](./references/patterns-02-put-business-errors-in-rpc-schemas.md): Read when: you need source-pattern detail for Put business errors in RPC schemas, Map cluster delivery errors at the boundary, Treat defects as defects.
