---
name: effect-core
description: Route ambiguous Effect tasks to one primary specialist and apply core Effect v4 semantics for computations, expected failures versus defects, requirements, causes, interruption, and fiber ownership. Use when those semantics are the primary concern or no narrower specialist fits. Do not load it as a general prerequisite for application architecture, service, Layer, or testing work.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Choose one primary Effect skill by the decision that owns the task; add another only when the task contains a separate, substantive decision in that skill’s scope.
- Inspect the installed Effect version, packages, existing adapters, and authoritative module surface before inventing infrastructure or relying on recalled APIs; route capability-specific selection to the narrow specialist.
- Start from the computation contract: success value, expected failures, required services, interruption behavior, and resource lifetime.
- Keep recoverable outcomes in the error channel only when a caller can make a meaningful decision from them; treat broken invariants and non-recoverable implementation faults as defects.
- Preserve boundary ownership: services own capabilities, layers own construction and lifetime, schemas own representation changes, and streams own incremental protocols.
- Decide whether an operation has independent semantic identity; route telemetry naming, attributes, metrics, logs, and exporters to the telemetry specialist.

## Constraints

- Target the current Effect v4 API exposed by the project and verify exact signatures against the installed release and its authoritative sources.
- Do not turn application policy into a universal Effect rule. Local architecture and enabled automation profiles remain authoritative.
- Do not duplicate guidance owned by any narrower Effect skill.

## Knowledge Boundaries

Applies to:

- choosing direct `Effect` values versus reusable effectful functions
- deciding expected failure versus defect policy
- reasoning about context requirements, interruption, causes, and fiber lifetime
- selecting one primary specialist when an Effect task is ambiguous

Does not cover:

- whole-application topology, one capability’s service contract, Layer graph and lifetime mechanics, or test evidence when one of those is the primary decision
- protocol-specific semantics already owned by a specialized Effect skill
- lint-detectable syntax preferences or diagnostic catalogs

Decision inputs:

- who can recover from each failure and what information recovery needs
- who owns acquired resources and when interruption must release them
- whether work is one value, a reusable operation, a stream, or a long-lived service
- whether observability changes behavior or only records it

## Patterns

Route by the primary decision:

| Decision | Specialist |
| --- | --- |
| Cross-capability topology, composition roots, or public application surface | `effect-application-architecture` |
| One capability’s contract, public failures, or dependency capture | `effect-service` |
| Construction of already-chosen capabilities, sharing, freshness, or scopes | `effect-layer` |
| Test seam, deterministic coordination, replacement boundary, or cleanup evidence | `effect-testing` |
| Encoded/domain representation | `effect-schema` |
| HTTP, Stream, platform, AI, Atom, Cluster, Workflow, Optic, telemetry, or property laws | Matching specialized skill |

- Return a direct Effect when no reusable function boundary is needed. Use an Effect function when parameters, tracing, or a stable operation boundary add meaning.
- Translate external failures once, at the boundary that understands both the external protocol and the domain contract. Preserve the original cause when it aids diagnosis.
- Keep defects out of public expected-error unions. Conversely, do not defect on validation, authorization, conflict, absence, or other outcomes callers are expected to handle.
- Keep requirements visible until the owning layer captures them. A requirement intentionally passed through a public capability is an API decision, not merely a typing choice.
- Treat interruption as part of semantics for forks, races, retries, acquisition, and streams. Decide whether child work is scoped, attached, detached, or externally supervised.
- Inspect `Cause` when failure, defect, and interruption must be distinguished; format it only at a display or protocol boundary.

## Gotchas

- A custom queue, scheduler, retry loop, cache, serializer, or lifecycle manager can duplicate an Effect capability the project already ships; prove the semantic gap against the installed version before owning a parallel mechanism.
- A generic tagged error can satisfy types while destroying recovery semantics; model the decision the caller actually makes.
- Converting every dependency failure into a domain error bloats public contracts with non-actionable infrastructure detail; translate only actionable distinctions.
- Detached fibers can outlive the resources and request that created them; choose detachment only with explicit ownership and shutdown semantics.
- Catching a cause for telemetry and returning success changes the operation, not just its observability; re-emit the original cause unless recovery is intentional.
- Providing dependencies deep inside reusable behavior can shorten scopes or duplicate resources; capture them in the owning layer or at the true runtime edge.
- Loading this skill as a universal Effect baseline makes its cross-cutting vocabulary co-trigger with the actual owner and produces conflicting advice; select the primary specialist directly unless routing or core runtime semantics are genuinely part of the task.

## References

- [`references/runtime-semantics.md`](./references/runtime-semantics.md): Read when: deciding function boundaries, expected failures versus defects, cause handling, or fiber/interruption ownership.
