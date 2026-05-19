---
name: effect-workflow
description: Model durable Effect workflows with schema-defined payloads, deterministic idempotency keys, activities, durable deferreds/clocks/queues, engine layers, proxies, compensation, and public API tests. Use when designing or modifying Effect workflows, activities, durable waits, external completions, durable queues, workflow services, workflow HTTP/RPC proxies, compensation, or workflow tests.
---

## Native Effect Standards

- Treat a workflow as a durable, schema-defined orchestration boundary.
- Define workflows with `Workflow.make({ name, payload, success, error, idempotencyKey })` at module scope.
- Use stable, deterministic idempotency keys derived from the logical payload. Do not use time, random values, counters, or mutable process state.
- Register behavior with `Workflow.toLayer(...)`. Callers should use `execute`, `poll`, `interrupt`, `resume`, or proxy-generated APIs, not the implementation function directly.
- Put durable or replay-sensitive side effects behind named primitives: `Activity.make` for retryable encoded steps, `DurableDeferred` for external completion, `DurableClock.sleep` for durable waits, and `DurableQueue` for worker-driven asynchronous work.
- Keep the engine at the infrastructure edge. Use `WorkflowEngine.layerMemory` for local tests and `ClusterWorkflowEngine.layer` when executions must be durable across runners.
- Use `Effect.fnUntraced` for project workflow bodies unless spans are intentionally needed.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not put business logic, protocol parsing, HTTP clients, filesystem work, or vendor SDK calls directly in workflow orchestration code. Put them behind services and activities.
- Do not use non-deterministic idempotency keys.
- Do not generate activity, deferred, queue, or clock names from timestamps, random ids, or mutable counters.
- Do not use plain `Effect.sleep` for long durable waits. Use `DurableClock.sleep`.
- Do not coordinate suspended workflows with in-memory `Deferred`, `Queue`, or mutable module state. Use `DurableDeferred` or `DurableQueue`.
- Do not expose generic errors such as `WorkflowFailed`, `UnknownError`, or raw defects for actionable failures.
- Do not use `Effect.orDie` to hide expected workflow or activity failures.
- Do not duplicate workflow payload and result schemas in HTTP/RPC layers when `WorkflowProxy` can derive them.
- Do not call engine internals or engine-specific storage from application code.
- Do not assume `execute(..., { discard: true })` returns the result; it returns the execution id.
- Do not rely on nested activity compensation. Register compensation around top-level effects only.
- Do not write tests that depend on wall-clock races. Use `TestClock` or poll deterministic public APIs.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- workflow payload, success, error, and idempotency semantics
- durable side effects, waits, external completions, and worker queues
- domain services and activities involved
- engine choice for tests or live cluster durability

Effect-native code should tend toward:

- module-scope workflow/activity/deferred/queue definitions
- workflow layers that orchestrate services without owning their business logic
- deterministic idempotency keys and stable step names
- tests through execute/poll/resume with memory engine or appropriate live engine

Applies to:

- applying Effect Workflow patterns to implementation, refactoring, review, or tests
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

- Bundled `references/patterns-*` files contain source-pattern detail for defining workflows, activities, durable primitives, proxies, or tests.
- Define `Workflow.make` at module scope with payload, success, error, and deterministic idempotency key schemas.
- Keep workflow bodies as orchestration; put domain work behind services and retryable durable side effects behind `Activity.make`.
- Use `DurableClock`, `DurableDeferred`, and `DurableQueue` for durable waits, external completion, and worker-driven work.
- Keep engine layers at infrastructure/test composition, not hidden in reusable workflow modules.
- Wrap workflows in domain services or generated proxies when callers should not depend on workflow internals.
- Test through public `execute`, `poll`, `interrupt`, and `resume` APIs with `WorkflowEngine.layerMemory`, durable queue layers, and `TestClock`.

## Gotchas

- If idempotency keys use time, random values, counters, or process state, retries create duplicate logical executions. Derive keys from the payload meaning.
- If business logic or HTTP clients live directly in the workflow body, replay and testing become brittle. Put domain work in services and durable effects in activities.
- If long waits use plain `Effect.sleep`, workflow suspension and runner movement are not durable. Use `DurableClock.sleep`.
- If external completion uses in-memory `Deferred` or module state, it disappears across runners. Use `DurableDeferred` and tokens.
- If `execute(..., { discard: true })` is treated as a result, callers will mis-handle start-and-poll flows. It returns the execution id.
- If compensation is nested inside activities or assumed to run on suspension, cleanup semantics are wrong. Register compensation around top-level effects only.

## References

- [`references/patterns-01-effect-workflow-patterns-for-agents.md`](./references/patterns-01-effect-workflow-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Workflow patterns for agents, First principles, Behavior encapsulation.
- [`references/patterns-02-use-durable-queues-for-worker-driven-work.md`](./references/patterns-02-use-durable-queues-for-worker-driven-work.md): Read when: you need source-pattern detail for Use durable queues for worker-driven work, Modular, testable, maintainable services, Separate definition, implementation, workers, and engine.
- [`references/patterns-03-model-expected-failures-in-the-workflow-error-sc.md`](./references/patterns-03-model-expected-failures-in-the-workflow-error-sc.md): Read when: you need source-pattern detail for Model expected failures in the workflow error schema, Understand poll and result semantics, Use suspension and compensation intentionally.
