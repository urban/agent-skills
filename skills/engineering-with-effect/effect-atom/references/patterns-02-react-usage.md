# Effect `Atom` patterns for agents — part 2

Covers:

- React usage
- Testing patterns
- What to avoid

---

## React usage

- Put one `RegistryProvider` around the application or feature surface.
- Use `useAtomValue(atom)` for reads, `useAtomSet(atom)` for writes, and `useAtomRefresh(atom)` for explicit refresh actions.
- Use `useAtomValue(atom, selector)` for cheap selectors over local state.
- Do not create atoms during render unless they are intentionally scoped to that component instance and memoized from stable dependencies.
- Do not wrap `family(key)` in `useMemo`. Memoize the key if needed.

## Testing patterns

- Test atoms through `AtomRegistry.make()` or `RegistryProvider`, not by mocking atom definitions.
- Mount async atoms when testing lifecycle, cancellation, refresh, or subscriptions.
- Use fake timers or Effect `TestClock` for delayed effects and SWR behavior.
- Seed values with `Atom.initialValue(atom, value)` or replace runtime services with `Atom.initialValue(runtime.layer, testLayer)`.
- Assert `AsyncResult` states directly: `Initial`, `Success`, `Failure`, and `waiting`.

```ts
const count = Atom.make(Effect.succeed(1).pipe(Effect.delay("100 millis")), {
  initialValue: 0,
}).pipe(Atom.keepAlive);

const registry = AtomRegistry.make();

const initial = registry.get(count);
assert(AsyncResult.isSuccess(initial));
assert.strictEqual(initial.value, 0);
assert.strictEqual(initial.waiting, true);

await TestClock.adjust("100 millis");

const loaded = registry.get(count);
assert(AsyncResult.isSuccess(loaded));
assert.strictEqual(loaded.value, 1);
assert.strictEqual(loaded.waiting, false);
```

## What to avoid

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
