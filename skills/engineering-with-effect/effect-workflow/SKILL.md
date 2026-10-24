---
name: effect-workflow
description: Design durable Effect workflows around deterministic identity, replay-safe activities, durable waits and queues, compensation, suspension, and engine ownership. Use when work must survive runner or process lifetime.
---

## Rules

- Treat workflow tags, payload/result/error schemas, idempotency keys, and step names as a durable protocol; changes can affect executions already in storage.
- Keep workflow bodies focused on replayable orchestration; put domain behavior behind services and externally visible effects behind named activities or durable workers.
- Derive execution and step identity from logical input, never ambient time, randomness, or process state. Record nondeterministic decisions in an activity when replay must reuse them.
- Assume an external effect can succeed before its activity result is recorded. Use downstream idempotency or deduplication, not activity memoization alone.
- Prefer engine-owned timers, signals, and persisted queues over custom replay loops unless a specific durability requirement is missing.
- Keep engine, storage, worker lifetime, and transport proxies at infrastructure boundaries.

## Constraints

- The `effect/workflow` surface is unstable.
- Durable primitives inherit their guarantees from the engine and backing stores; an in-memory engine does not survive process loss.
- Compensation is business reversal of a successful step after terminal workflow failure, not an atomic rollback or replay-safety mechanism.
- Use durable waits and external completion when execution may move or restart; process-local resources cannot represent persistent workflow state.

## Knowledge Boundaries

Applies to:

- workflow/activity schemas and deterministic identity
- durable clocks, deferreds, queues, retries, suspension, and compensation
- memory versus cluster engine composition and proxy-generated APIs
- execute, discard/start, poll, interrupt, resume, and behavioral tests

Does not cover:

- ordinary in-process orchestration that does not require durability
- business logic belonging in domain services

Decision inputs:

- durability and replay requirements, including existing stored executions
- logical idempotency key and distinct step identities
- retry safety, compensation action, and approval requirements
- synchronous completion versus start-and-poll caller contract

## Patterns

- Model activities as stored step outcomes, including expected failures, rather than exactly-once side effects. Give repeated logical steps distinct stable names.
- Use `Activity.retry` around an activity when retries need distinct recorded attempts. Keep the downstream idempotency key stable across attempts unless each attempt intentionally represents a new external operation.
- Use durable clocks for waits, deferreds for external completion, and queues when a separately owned worker pool should process the step.
- Register compensation around the activity at workflow level, where replay can rebuild the finalizer from the recorded success value.
- Put expected business failures in error schemas. Defects remain distinct from typed failures, but `Workflow.CaptureDefects` defaults to true and records them in result exits; choose failure/suspension policy deliberately.
- Separate workflow definition, handler registration, workers, engine/storage, and proxy layers so tests and deployments can choose each.

## Gotchas

- A key based on request time starts new work on every client retry; a key omitting a tenant or business-operation dimension can join unrelated work. Define the logical operation before choosing the key.
- Reusing an activity name in a loop reuses that step's recorded outcome for the same attempt. Include a stable item identity, not replay-dependent ordering.
- A suspended activity has no completed outcome to memoize, so its body runs again. Isolate side effects before waits into completed activities and still make external mutations idempotent.
- Retrying an activity with ordinary `Effect.retry` outside it can replay the same stored failure. Use `Activity.retry` to advance the recorded attempt identity.
- A short `DurableClock.sleep` is in-memory by default, so recovery can restart its delay. Choose its threshold according to whether the deadline must be durably scheduled.
- Start-with-discard returns execution identity, not business success. Polling can return `None` for either unknown or running work; do not interpret it as a distinct not-found state.
- Compensation inside an activity belongs to that activity's execution scope, not the later workflow failure. Wrap the activity at workflow level; suspension alone must not trigger reversal.
- A generated proxy does not expose every engine operation. Add explicit boundary operations when callers need polling or interruption rather than assuming they are generated.

## References

- [`references/identity-activities-and-durable-primitives.md`](./references/identity-activities-and-durable-primitives.md): Read when: defining workflow identity, activities, durable waits, deferreds, queues, retry, or compensation.
- [`references/engines-proxies-and-testing.md`](./references/engines-proxies-and-testing.md): Read when: composing engines/workers/storage, exposing proxies, or testing execute/poll/resume and replay semantics.
