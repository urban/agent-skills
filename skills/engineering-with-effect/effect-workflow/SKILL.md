---
name: effect-workflow
description: Design durable Effect workflows around deterministic identity, replay-safe activities, durable waits and queues, compensation, suspension, engine ownership, proxy semantics, and public API tests. Use when work must survive runner or process lifetime.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Inspect the installed workflow engine, durable activities, waits, queues, retry, compensation, and proxy semantics before building custom orchestration or persistence machinery.
- Treat workflow payload, result, expected failures, and idempotency key as a durable protocol.
- Keep workflow bodies focused on orchestration; put domain behavior behind services and replay-sensitive side effects behind named durable primitives.
- Derive stable execution and step identity from logical input, never ambient time, randomness, or process state.
- Keep engine, storage, workers, and transport proxies at infrastructure boundaries.

## Constraints

- Effect Workflow is currently exposed through an unstable v4 module surface; verify imports and API details against the installed release.
- Every retryable or replayable side effect needs idempotency or deduplication; compensation is an additional business-reversal policy, not replay safety.
- Long waits and external completion must use durable primitives when execution may move or restart.
- Compensation scope and trigger semantics must be verified; it is not a substitute for idempotent activities.

## Knowledge Boundaries

Applies to:

- workflow/activity schemas and deterministic identity
- durable clocks, deferreds, queues, retries, suspension, and compensation
- memory versus cluster engine composition and proxy-generated APIs
- execute, discard/start, poll, interrupt, resume, and deterministic tests

Does not cover:

- ordinary in-process orchestration that does not require durability
- business logic belonging in domain services

Decision inputs:

- durability and replay requirements
- logical idempotency key and step identity
- retry safety, compensation action, and approval requirements
- synchronous completion versus start-and-poll caller contract

## Patterns

- Use activities for encoded retryable steps whose results must survive replay. Make the activity name stable and its external effect idempotent.
- Use durable clock for waits, durable deferreds for external completion, and durable queues for worker-owned execution.
- Separate workflow definition, implementation layer, worker layers, engine/storage layer, and transport proxy so tests and deployments can choose each.
- Put expected business failures in workflow/activity error schemas. Preserve defects as defects unless the workflow explicitly captures them for operational handling.
- Prefer generated workflow proxies when they preserve the intended start/wait/poll semantics and avoid duplicate schema definitions.
- Test through execute/poll/resume with deterministic engine composition; inspect storage only when replay or deduplication is the behavior.

## Gotchas

- A custom durable queue, scheduler, or replay loop can become a partial workflow engine without deterministic identity, suspension, or recovery guarantees; prove the installed workflow primitives miss a named semantic requirement.
- A volatile idempotency key creates a new execution on every retry instead of finding the same logical work.
- An activity that charges, sends, or mutates without idempotency can repeat after recovery even when its code runs once in a happy-path test.
- Plain sleeps and in-memory deferreds disappear when execution suspends or moves runners.
- Treating start-with-discard as a result-returning call confuses execution identity with workflow success.
- Nested compensation assumptions can leave partially completed side effects uncorrected; register compensation where the runtime guarantees it.
- Hiding the engine inside a reusable workflow module prevents tests and deployments from choosing durability semantics.

## References

- [`references/identity-activities-and-durable-primitives.md`](./references/identity-activities-and-durable-primitives.md): Read when: defining workflow identity, activities, durable waits, deferreds, queues, retry, or compensation.
- [`references/engines-proxies-and-testing.md`](./references/engines-proxies-and-testing.md): Read when: composing engines/workers/storage, exposing proxies, or testing execute/poll/resume and replay semantics.
