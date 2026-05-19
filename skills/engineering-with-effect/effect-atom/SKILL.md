---
name: effect-atom
description: Build Effect Atom state modules with clear async lifecycles, stable families, service-backed data access, optimistic updates, React integration, and deterministic tests. Use when implementing or refactoring Effect reactivity atoms, AtomHttpApi clients, async atom rendering, optimistic mutations, React hooks, cache identity, or Atom tests.
---

## Native Effect Standards

- An Atom is a reactive value owned by an `AtomRegistry`.
- `Atom.make(value)` creates local writable state.
- `Atom.make(get => value)` or `Atom.readable(get => value)` creates derived state.
- `Atom.make(effect)` and `Atom.make(stream)` create `AsyncResult` state. The result is not the loaded data; it is the full lifecycle: `Initial`, `Success`, `Failure`, plus `waiting`.
- `Atom.fn` creates a writable effectful action. Setting it runs the effect. In React, use `useAtomSet(fn, { mode: "promiseExit" })` when the caller needs to await success or failure without throwing.
- `Atom.family` is the default when identity depends on input. Primitive keys are fine. For compound keys, prefer a `Data.Class` key or another stable, structural key with every identity field included.
- Atoms are lazy and auto-disposed unless mounted, subscribed, `keepAlive`, or given an idle TTL. Use `Atom.keepAlive` only for true process-wide state.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not flatten `AsyncResult` into fake defaults such as `result.value ?? []`.
- Do not treat failure or loading as empty data.
- Do not add parallel `isLoading`, `hasLoaded`, or `error` state beside an async atom unless modeling an intentional domain state machine.
- Do not call raw HTTP/RPC/storage clients from components when an Atom service boundary exists.
- Do not scatter reactivity keys through components; put them on query and mutation atoms.
- Do not use `Atom.keepAlive` for every atom. Prefer default auto-disposal or `setIdleTTL` for cacheable remote data.
- Do not hide causes behind generic copy like `Something went wrong` without details.
- Do not use `Cause.squash` as the first step in UI error rendering; keep the `Cause` until the display boundary.
- Do not mock atoms in tests. Replace service layers or seed registry initial values.
- Do not use singleton atoms for per-entity or per-mode state. Use `Atom.family` and include every isolating id in the key.
- Do not use `Effect.promise` around raw fetches in application Atom code when an Effect HTTP/RPC client can model the boundary.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- the state identity, cache lifetime, and reactivity keys
- query/mutation API contracts and service boundaries
- React surfaces that read or write the atom
- loading, refreshing, failure, and optimistic-update UX requirements

Effect-native code should tend toward:

- atom modules that own loading, derivation, refresh, cache identity, and optimistic behavior
- components that render `AsyncResult` explicitly and dispatch through atom actions
- service-backed clients and tests using registries or seeded layers

Applies to:

- applying Effect Atom patterns to implementation, refactoring, review, or tests
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

- Bundled `references/patterns-*` files contain source-pattern detail for changing async, family, optimistic, or React usage.
- Place query, mutation, derived, and optimistic atoms near the domain API client rather than inside components.
- Choose `Atom.family` whenever identity depends on input and use stable structural keys that include every isolating field.
- Render `AsyncResult` states explicitly, including `waiting` on successful refreshes and real causes on failures.
- Keep HTTP/RPC/storage/browser access behind Atom services or Effect service layers; components should read, render, refresh, and dispatch only.
- Use React hooks according to intent: `useAtomValue` for reads, `useAtomSet` for writes, `useAtomRefresh` for refreshes, and `promiseExit` when UI must branch on mutation outcome.
- Test through `AtomRegistry` or `RegistryProvider`, seed values or replace runtime services, and assert `AsyncResult` states directly.

## Gotchas

- If `AsyncResult` is flattened into `[]` or placeholder objects, loading and failure become indistinguishable from real empty data. Render the lifecycle state instead.
- If per-entity state uses a singleton atom, values bleed across ids or modes. Use `Atom.family` and include every identity field in the key.
- If components call raw clients or maintain local copies of remote lists, optimistic updates drift from cache invalidation. Keep mutations and optimistic reducers at the atom boundary.
- If every atom is marked `keepAlive`, lazy disposal stops working and stale process-wide state accumulates. Reserve it for true process-wide state and prefer idle TTLs for caches.
- If failure causes are replaced with generic copy, operators lose the actual decode, transport, or domain cause. Preserve `Cause` until the display boundary.
- If tests mock atom definitions instead of registry state or service layers, they prove a fake graph. Mount atoms through `AtomRegistry` or `RegistryProvider`.

## References

- [`references/patterns-01-effect-atom-patterns-for-agents.md`](./references/patterns-01-effect-atom-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Atom patterns for agents, Core model, Encapsulate behavior outside components.
- [`references/patterns-02-react-usage.md`](./references/patterns-02-react-usage.md): Read when: you need source-pattern detail for React usage, Testing patterns, What to avoid.
