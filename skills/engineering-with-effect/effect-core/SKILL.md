---
name: effect-core
description: Apply cross-cutting Effect v4 judgment about direct computations, function boundaries, expected failures versus defects, requirements, causes, interruption, and fiber/resource ownership. Use when those are the primary concern and no narrower Effect skill applies.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Start from the computation contract: success value, expected failures, required services, interruption behavior, and resource lifetime.
- Keep recoverable outcomes in the error channel only when a caller can make a meaningful decision from them; treat broken invariants and non-recoverable implementation faults as defects.
- Preserve boundary ownership: services own capabilities, layers own construction and lifetime, schemas own representation changes, and streams own incremental protocols.
- Decide whether an operation has independent semantic identity; route telemetry naming, attributes, metrics, logs, and exporters to the telemetry specialist.

## Constraints

- Target the current Effect v4 API exposed by the project; do not preserve an older idiom merely because it appears in existing prose or examples.
- Do not turn application policy into a universal Effect rule. Local architecture and enabled automation profiles remain authoritative.
- Do not duplicate guidance owned by any narrower Effect skill.

## Knowledge Boundaries

Applies to:

- choosing direct `Effect` values versus reusable effectful functions
- deciding expected failure versus defect policy
- reasoning about context requirements, interruption, causes, and fiber lifetime
- selecting the specialized boundary that should own further design

Does not cover:

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
| Whole-application topology, composition roots, or public application surface | `effect-application-architecture` |
| Capability contract or dependency capture | `effect-service` |
| Construction graph, sharing, or scopes | `effect-layer` |
| Encoded/domain representation | `effect-schema` |
| HTTP, Stream, platform, AI, Atom, Cluster, Workflow, Optic, telemetry, testing, or property laws | Matching specialized skill |

- Return a direct Effect when no reusable function boundary is needed. Use an Effect function when parameters, tracing, or a stable operation boundary add meaning.
- Translate external failures once, at the boundary that understands both the external protocol and the domain contract. Preserve the original cause when it aids diagnosis.
- Keep defects out of public expected-error unions. Conversely, do not defect on validation, authorization, conflict, absence, or other outcomes callers are expected to handle.
- Keep requirements visible until the owning layer captures them. A requirement intentionally passed through a public capability is an API decision, not merely a typing choice.
- Treat interruption as part of semantics for forks, races, retries, acquisition, and streams. Decide whether child work is scoped, attached, detached, or externally supervised.
- Inspect `Cause` when failure, defect, and interruption must be distinguished; format it only at a display or protocol boundary.

## Gotchas

- A generic tagged error can satisfy types while destroying recovery semantics; model the decision the caller actually makes.
- Converting every dependency failure into a domain error bloats public contracts with non-actionable infrastructure detail; translate only actionable distinctions.
- Detached fibers can outlive the resources and request that created them; choose detachment only with explicit ownership and shutdown semantics.
- Catching a cause for telemetry and returning success changes the operation, not just its observability; re-emit the original cause unless recovery is intentional.
- Providing dependencies deep inside reusable behavior can shorten scopes or duplicate resources; capture them in the owning layer or at the true runtime edge.

## References

- [`references/runtime-semantics.md`](./references/runtime-semantics.md): Read when: deciding function boundaries, expected failures versus defects, cause handling, or fiber/interruption ownership.
