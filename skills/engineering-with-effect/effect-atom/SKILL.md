---
name: effect-atom
description: Design Effect Atom state around identity, AsyncResult lifecycle, cache/disposal policy, optimistic transitions, service boundaries, and React rendering. Use when state correctness depends on refresh, failure, family keys, or mutation semantics.
---

## Rules

- Let the registry own values, subscriptions, and resources; share stable atom definitions rather than mirroring their state in another cache.
- Model asynchronous atom values as a lifecycle, not as loaded data with fallback placeholders.
- Make cache identity explicit; every field that isolates state belongs in the family key or registry boundary.
- Let atom modules own queries, mutations, refresh, derived views, optimistic transitions, and cache policy; components render and dispatch.
- Choose disposal and idle retention from state ownership; choose freshness and invalidation separately.
- Decide mutation overlap policy before enabling concurrency: cancellation, serialization, and independent operations have different domain consequences.

## Constraints

- The Effect v4 reactivity surface is unstable; the registry, not a module-level atom definition, owns live state.
- Loading, refreshing, failure, and successful empty data must remain distinguishable unless the domain intentionally merges them.
- Optimistic transitions need reconciliation semantics for failure and overlapping mutations; they are not server-side concurrency control.
- Causes may be formatted at the display boundary but should not be discarded earlier.

## Knowledge Boundaries

Applies to:

- local, derived, effect, stream, family, query, mutation, and optimistic atoms
- cache identity, idle TTL, keep-alive, refresh, and React hooks
- registry/layer-based testing and async-state assertions

Does not cover:

- generic React architecture or raw transport implementation
- server-side transaction protocols or SSR serialization design

Decision inputs:

- state owner and identity dimensions
- loading/refresh/error UX and stale-data policy
- cache lifetime and invalidation triggers
- mutation concurrency and reconciliation behavior

## Patterns

- Use a family when input changes identity. Use immutable value keys containing the tenant, entity, scope, mode, and filters that separate cached values.
- Render Initial, Success, Failure, and `waiting` deliberately. Retained data can accompany either a refreshing Success or a Failure with `previousSuccess`.
- Put derived selection beside the owning atom; `Atom.mapResult` preserves lifecycle instead of copying successful values into component state.
- Keep optimistic reducers pure; reconcile with the authoritative query rather than treating provisional values as committed writes.
- Reserve keep-alive for intentional registry-lifetime retention. Use idle TTL for reuse and refresh/invalidation for freshness.
- Test the real graph through fresh registries or providers, replacing runtime layers at service boundaries and controlling request completion order.

## Gotchas

- Creating atoms during each render gives each render a new state identity; keep definitions stable or select a stable family member instead.
- Flattening Initial or Failure to an empty collection hides unavailable requests; render lifecycle separately from successful empty data.
- Omitting tenant/scope fields shares family state across domains, while mutating an already-hashed key corrupts lookup assumptions; use complete immutable keys.
- An idle TTL only controls retention, not data age; pair it with an explicit stale-data and invalidation policy.
- Keeping every family member alive retains nodes and resources until registry disposal; bound remote caches instead.
- Treating optimistic rollback as a saved-snapshot restore can overwrite newer state; reconcile against the latest source and test reversed completion orders.
- A promise-mode React setter observes the atom's next settled result, not a write-specific response; serialize calls or isolate mutation atoms when callers need correlation.
- A provider boundary isolates values and default runtime services, not just rendering; place shared consumers under the same registry and do not expect cross-registry invalidation broadcasts.

## References

- [`references/async-state-and-identity.md`](./references/async-state-and-identity.md): Read when: choosing atom kind, family keys, lifecycle rendering, disposal, or cache policy.
- [`references/optimistic-react-and-tests.md`](./references/optimistic-react-and-tests.md): Read when: designing optimistic mutations, React usage, service-backed atoms, or registry tests.
