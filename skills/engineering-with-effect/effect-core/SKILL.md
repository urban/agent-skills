---
name: effect-core
description: Apply core Effect semantics for expected failures versus defects, Cause, interruption, fiber ownership, and function/runtime boundaries. Use when deciding recovery policy, cancellation behavior, or who owns concurrent work in Effect v4. Not a general prerequisite for application architecture, service, Layer, or testing work.
---

## Rules

- Start from the computation contract: success value, expected failures, required services, interruption behavior, and resource lifetime.
- Model expected failure around caller decisions; treat broken invariants and implementation faults as defects. An operational failure does not become a defect merely because this caller cannot recover.
- Give concurrent work an owner for lifetime, failure observation, and shutdown; automatic child interruption is not an error-recovery policy.
- Keep execution inside the current Effect until a genuine runtime boundary; nested runners create independent root fibers rather than child work.

## Constraints

- Use Effect v4 semantics; do not assume older Cause trees or fork ownership behavior.
- Do not turn application policy into a universal Effect rule.
- Keep whole-application topology, service design, and Layer construction outside this skill’s scope.

## Knowledge Boundaries

Applies to:

- choosing direct `Effect` values versus reusable effectful functions
- deciding expected failure versus defect policy
- reasoning about context requirements, interruption, causes, and fiber lifetime
- preserving ownership when crossing between Effect and Promise/callback runtimes

Does not cover:

- whole-application topology, one capability’s service contract, Layer graph and lifetime mechanics, or test evidence when one of those is the primary decision
- protocol-specific error taxonomies, telemetry configuration, or stream protocols
- lint-detectable syntax preferences or diagnostic catalogs

Decision inputs:

- who can recover from each failure and what information recovery needs
- who owns acquired resources and when interruption must release them
- whether work is one value, a reusable operation, a stream, or a long-lived service
- whether observability changes behavior or only records it

Failure modes this knowledge helps avoid:

- hiding operational failures as defects or swallowing defects as normal recovery
- losing cancellation, resource lifetime, or failure information at a boundary

## Patterns

- Return a direct Effect when no reusable function boundary is needed. Use an Effect function when parameters, tracing, or a stable operation boundary add meaning.
- Translate external failures once, at the boundary that understands both the external protocol and the domain contract. Preserve the original cause when it aids diagnosis.
- Keep defects out of public expected-error unions. Conversely, do not defect on validation, authorization, conflict, absence, or other outcomes callers are expected to handle.
- Keep requirements visible until the owning layer captures them. A requirement intentionally passed through a public capability is an API decision, not merely a typing choice.
- Prefer structured concurrency combinators when results belong to one operation. For explicit forks, select parent-owned, scope-owned, or detached lifetime separately from how the result is observed.
- Inspect `Cause` when failure, defect, and interruption must be distinguished; format it only at a display or protocol boundary.

## Gotchas

- `E = never` does not promise successful completion: the computation can still die or be interrupted. Do not use an empty expected-error channel as evidence that cleanup or failure observation is unnecessary.
- A generic tagged error can satisfy types while destroying recovery semantics; model the decision the caller actually makes.
- Converting every dependency failure into a domain error bloats public contracts with non-actionable infrastructure detail; translate only actionable distinctions.
- Detached fibers can outlive the resources and request that created them; choose detachment only with explicit ownership and shutdown semantics.
- Catching a cause for telemetry and returning success changes the operation, not just its observability; re-emit the original cause unless recovery is intentional.
- Providing dependencies deep inside reusable behavior can shorten scopes or duplicate resources; capture them in the owning layer or at the true runtime edge.
- Treating every cause containing interruption as harmless cancellation hides defects from failed cleanup. Suppress only interruption-only causes when that is the boundary’s policy.
- Wrapping a long-running operation in `uninterruptible` can make parent completion or shutdown wait forever. Protect only the critical transition and restore interruption around waiting work.

## References

- [`references/runtime-semantics.md`](./references/runtime-semantics.md): Read when: deciding function boundaries, expected failures versus defects, cause handling, or fiber/interruption ownership.
