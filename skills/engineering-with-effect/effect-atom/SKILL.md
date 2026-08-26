---
name: effect-atom
description: Design Effect Atom state around identity, AsyncResult lifecycle, cache/disposal policy, optimistic transitions, service boundaries, and React rendering. Use when state correctness depends on refresh, failure, family keys, or mutation semantics.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Model asynchronous atom values as a lifecycle, not as loaded data with fallback placeholders.
- Make cache identity explicit; every field that isolates state belongs in the family key.
- Let atom modules own queries, mutations, refresh, derived views, optimistic transitions, and cache policy; components render and dispatch.
- Choose disposal, idle retention, and process-wide retention from state ownership and staleness requirements.

## Constraints

- Effect reactivity is currently exposed through an unstable v4 module surface; verify imports and API details against the installed release.
- Loading, refreshing, failure, and successful empty data must remain distinguishable unless the domain intentionally merges them.
- Optimistic transitions need rollback/reconciliation semantics for failure and concurrent mutations.
- Causes may be formatted at the display boundary but should not be discarded earlier.

## Knowledge Boundaries

Applies to:

- local, derived, effect, stream, family, query, mutation, and optimistic atoms
- cache identity, idle TTL, keep-alive, refresh, and React hooks
- registry/layer-based testing and async-state assertions

Does not cover:

- generic React architecture or raw transport implementation
- syntax rules around direct storage or HTTP access

Decision inputs:

- state owner and identity dimensions
- loading/refresh/error UX and stale-data policy
- cache lifetime and invalidation triggers
- mutation concurrency and reconciliation behavior

## Patterns

- Use a family when input changes identity. Prefer structural keys with all tenant, entity, scope, mode, and filter fields that separate cached values.
- Render Initial, Success, Failure, and waiting/refresh states deliberately. A refreshing Success can show stale data while indicating progress.
- Put derived selection beside the owning atom and preserve the source lifecycle instead of copying values into component state.
- Keep optimistic reducers pure and define what happens on rejection, overlap, server normalization, and invalidation.
- Reserve keep-alive for true application-lifetime state; use ordinary disposal or bounded idle retention for remote caches.
- Test through a registry/provider, replace runtime services or seed state, and assert lifecycle transitions and isolation between keys.

## Gotchas

- Flattening failure or loading to an empty collection makes real empty data indistinguishable from an unavailable request.
- A family key missing scope or mode fields leaks values across users, tenants, views, or test cases.
- Duplicating remote data in component state splits optimistic updates from invalidation and refresh.
- Keeping every atom alive turns a lazy graph into an unbounded process cache.
- A reducer that assumes one mutation at a time can roll back newer successful state when requests finish out of order.
- Mocking atom definitions proves a different graph; replace services or registry inputs instead.

## References

- [`references/async-state-and-identity.md`](./references/async-state-and-identity.md): Read when: choosing atom kind, family keys, lifecycle rendering, disposal, or cache policy.
- [`references/optimistic-react-and-tests.md`](./references/optimistic-react-and-tests.md): Read when: designing optimistic mutations, React usage, service-backed atoms, or registry tests.
