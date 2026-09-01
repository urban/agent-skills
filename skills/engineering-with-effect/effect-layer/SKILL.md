---
name: effect-layer
description: Reason about Effect Layer ownership, dependency visibility, memoized sharing, freshness, construction failures, and scoped lifetime. Use when composing service graphs or debugging surprising acquisition, reuse, release, or test isolation.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Use installed Layer, Scope, acquisition, memoization, and supervision primitives before introducing a custom container, resource manager, lifecycle registry, or background-worker owner.
- Use layers to construct capabilities and own lifetimes; keep domain branching in the services they provide.
- Choose composition by dependency graph and output visibility, not by whichever operator makes types pass.
- Treat memoization and freshness as lifetime semantics: decide which consumers share an acquisition and when it is released.
- Keep recoverable construction failures typed until a boundary has enough context to recover, substitute, or terminate.

## Constraints

- Build layers manually only at a real lifetime boundary that normal application provision cannot express.
- Do not expose dependency services merely because composition made them available; output visibility is part of the module API.
- Freshness must solve an explicit isolation requirement, not mask accidental mutable state.

## Knowledge Boundaries

Applies to:

- layer constructor and composition choices
- dependency hiding versus output merging
- scoped acquisition, finalization, sharing, and per-request state
- dynamic layer selection and test graph design

Does not cover:

- service contract design beyond implications for the layer graph
- mechanical nesting or provide-shape diagnostics

Decision inputs:

- provided services, construction failures, and required services
- acquisition identity and intended sharing domain
- scope owner and release condition
- whether dependencies remain available to downstream consumers

## Patterns

- Merge layers only when they are independent at that stage. Configure dependent layers first, then merge the configured results that may safely build in parallel.
- Use dependency-hiding composition for implementation details; retain dependencies in the output only when downstream code or a test harness intentionally needs them.
- Acquire clients, handles, subscriptions, and background fibers in scoped construction so interruption and scope closure run finalizers.
- Use dynamic unwrapping when configuration selects an implementation; keep the selected layer's requirements and errors honest.
- Give request-bound or tenant-bound resources a request/tenant scope and independent memoization boundary. Share process-wide pools through one stable layer value.
- Build test state in the layer scope and expose a harness service only when assertions need controlled observability.

## Gotchas

- A custom container or lifecycle registry can recreate Layer and Scope with weaker sharing, interruption, and release semantics; prove the ownership model cannot be expressed by the installed primitives.
- Merging interdependent layers builds them as peers, so one cannot satisfy another merely by appearing earlier in the call.
- Keeping dependencies in the output can turn implementation details into accidental public API; hide them unless access is intentional.
- Recreating an equivalent layer value can defeat expected sharing; sharing follows layer identity and memoization context, not visual similarity.
- Freshening a subtree duplicates acquisition and finalization; this can multiply sockets, pools, or background workers.
- Converting construction errors to defects too early removes fallback and startup-reporting choices from the application edge.
- Manual builds inside service methods create nested lifetimes that are difficult to observe and release correctly.

## References

- [`references/composition-and-lifetimes.md`](./references/composition-and-lifetimes.md): Read when: choosing composition operators, sharing versus freshness, manual build boundaries, or scoped acquisition.
- [`references/test-layers.md`](./references/test-layers.md): Read when: designing isolated fake state, harness services, or scoped test resources.
