---
name: effect-layer
description: Compose already-chosen Effect capabilities through Layer ownership, dependency visibility, memoized sharing, freshness, construction failures, and scoped lifetime. Use when build, acquisition, reuse, or release semantics are the primary decision. Do not use to design a service API, whole-application topology, or test strategy.
---

## Rules

- Use installed Layer, Scope, acquisition, memoization, and supervision primitives before introducing a custom container, resource manager, lifecycle registry, or background-worker owner.
- Use layers to construct capabilities and own lifetimes; keep domain branching in the services they provide.
- Choose composition by dependency graph and output visibility, not by whichever operator makes types pass.
- Treat memoization and freshness as lifetime semantics: choose both the sharing domain and the scope owner; neither substitutes for the other.
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
- cross-capability application topology, public facades, or composition-root placement
- test seam selection or behavioral evidence beyond Layer-specific isolation mechanics
- mechanical nesting or provide-shape diagnostics

Decision inputs:

- provided services, construction failures, and required services
- acquisition identity and intended sharing domain
- scope owner and release condition
- whether dependencies remain available to downstream consumers

## Patterns

- Merge layers that can build as peers from the same inputs; merging does not feed one peer's output into another. Configure dependent layers before merging their results.
- Use dependency-hiding composition for implementation details; retain dependencies in the output only when downstream code or a test harness intentionally needs them.
- Use `Layer.provide` to satisfy and hide construction dependencies; use `Layer.provideMerge` only when retaining the provided capabilities in the resulting graph is intentional.
- Use `Layer.effect` with `Effect.acquireRelease` for owned clients, handles, and subscriptions; it supplies the layer scope. Attach background fibers to that scope as well.
- Use `Layer.suspend` to defer recipe creation, and `Layer.unwrap` when an Effect selects an implementation. Neither is a per-call factory once the layer is shared.
- Provide a Layer inside an operation only when runtime policy deliberately owns that Layer's activation or lifetime boundary; keep acquisition scoped and the wrapped Effect semantically transparent.
- Give request-bound or tenant-bound resources an appropriate scope and sharing boundary. Reuse already-built global dependencies only when that inheritance is intentional.
- Use one `ManagedRuntime` for repeated host calls that should share a built graph; its owner must dispose it.
- Allocate test state during layer acquisition, not in a value captured before acquisition; expose a harness service only when assertions need controlled observability.

## Gotchas

- Merging interdependent layers builds them as peers, so one cannot satisfy another merely by appearing earlier in the call.
- Hiding a dependency with `provide` does not release it early: the constructed service may still use it. Visibility and lifetime are separate decisions.
- Recreating an equivalent layer value can defeat expected sharing; sharing follows layer identity and memoization context, not visual similarity.
- Freshening a subtree gives it a new memo map on each build, not a new scope or cloned values. It can multiply pools and workers while still sharing objects captured by `Layer.succeed`.
- Converting construction errors to defects too early removes fallback and startup-reporting choices from the application edge.
- Reusing one parameterized layer under different tenant/config inputs in the same memo map can reuse the first acquisition: memoization keys on layer identity, not input values. Use distinct recipes or an isolated build boundary.
- Returning a resource from `Effect.scoped(Layer.build(...))` leaves the caller holding a released service. Keep use inside the owning scope or let the host own a managed runtime.
- Retrying a call through `ManagedRuntime` does not retry a failed startup: the runtime caches that build failure. Put recovery in construction or dispose and recreate the runtime.

## References

- [`references/composition-and-lifetimes.md`](./references/composition-and-lifetimes.md): Read when: choosing composition operators, sharing versus freshness, manual build boundaries, or scoped acquisition.
- [`references/test-layers.md`](./references/test-layers.md): Read when: designing isolated fake state, harness services, or scoped test resources.
