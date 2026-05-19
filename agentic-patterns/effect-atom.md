# Effect `Atom` patterns for agents

## Core model

- An Atom is a reactive value owned by an `AtomRegistry`.
- `Atom.make(value)` creates local writable state.
- `Atom.make(get => value)` or `Atom.readable(get => value)` creates derived state.
- `Atom.make(effect)` and `Atom.make(stream)` create `AsyncResult` state. The result is not the loaded data; it is the full lifecycle: `Initial`, `Success`, `Failure`, plus `waiting`.
- `Atom.fn` creates a writable effectful action. Setting it runs the effect. In React, use `useAtomSet(fn, { mode: "promiseExit" })` when the caller needs to await success or failure without throwing.
- `Atom.family` is the default when identity depends on input. Primitive keys are fine. For compound keys, prefer a `Data.Class` key or another stable, structural key with every identity field included.
- Atoms are lazy and auto-disposed unless mounted, subscribed, `keepAlive`, or given an idle TTL. Use `Atom.keepAlive` only for true process-wide state.

## Encapsulate behavior outside components

Components should read, render, and dispatch. Atom modules should own data loading, cache identity, reactivity keys, optimistic updates, refresh policy, and derived views.

Example pattern:

```ts
import * as Atom from "effect/unstable/reactivity/Atom";
import * as AsyncResult from "effect/unstable/reactivity/AsyncResult";

export const sourcesAtom = (scopeId: ScopeId) =>
  AppApiClient.query("sources", "list", {
    params: { scopeId },
    timeToLive: "30 seconds",
    reactivityKeys: [ReactivityKey.sources],
  });

export const sourceAtom = (sourceId: SourceId, scopeId: ScopeId) =>
  Atom.mapResult(
    sourcesOptimisticAtom(scopeId),
    (sources) => sources.find((source) => source.id === sourceId) ?? null,
  );

export const removeSource = AppApiClient.mutation("sources", "remove");

export const sourcesOptimisticAtom = Atom.family((scopeId: ScopeId) =>
  Atom.optimistic(sourcesAtom(scopeId)),
);

export const removeSourceOptimistic = Atom.family((scopeId: ScopeId) =>
  sourcesOptimisticAtom(scopeId).pipe(
    Atom.optimisticFn({
      reducer: (current, arg) =>
        AsyncResult.map(current, (sources) =>
          sources.filter((source) => source.id !== arg.params.sourceId),
        ),
      fn: removeSource,
    }),
  ),
);
```

Follow this shape:

- Define query and mutation atoms near the domain API client.
- Define derived atoms with `Atom.mapResult`, `Atom.map`, or `Atom.readable` instead of recalculating in many components.
- Keep optimistic behavior at the data boundary. Components call `removeSourceOptimistic(scopeId)`; they do not maintain duplicate local copies of the list.
- Label long-lived or family atoms with `Atom.withLabel(...)` for debugging.
- Use `Atom.swr`, `Atom.setIdleTTL`, `Atom.refreshOnWindowFocus`, and reactivity keys as part of the atom definition rather than ad hoc component effects.

## Services should be modular, testable, and maintainable

Atoms that touch HTTP, RPC, storage, browser APIs, or cross-module state should depend on a service boundary rather than raw clients in React components.

Example pattern:

```ts
import * as AtomHttpApi from "effect/unstable/reactivity/AtomHttpApi";
import { FetchHttpClient, HttpClient, HttpClientRequest } from "effect/unstable/http";
import * as Effect from "effect/Effect";

const AppApiClient = AtomHttpApi.Service<"AppApiClient">()("AppApiClient", {
  api: AppApi,
  httpClient: FetchHttpClient.layer,
  transformClient: HttpClient.mapRequest((request) => {
    const withBaseUrl = HttpClientRequest.prependUrl(request, getBaseUrl());
    const authorization = readAuthorizationHeader();

    return authorization === undefined
      ? withBaseUrl
      : HttpClientRequest.setHeader(withBaseUrl, "authorization", authorization);
  }),
  transformResponse: (effect) => Effect.tapCause(effect, reportApiClientInfrastructureCause),
});

export { AppApiClient };
```

Use this pattern because it gives agents a clean seam:

- The client module owns transport setup, base URL, auth headers, response instrumentation, and typed API shape.
- Atom modules own query and mutation definitions.
- Components own UI only.
- Tests can replace layers through the registry instead of mocking atoms.

```tsx
class TheNumber extends Context.Service<TheNumber>()("TheNumber", {
  make: Effect.succeed({ n: 42 }),
}) {
  static readonly layer = Layer.effect(this, this.make);
}

const runtime = Atom.runtime(TheNumber.layer);
const numberAtom = runtime.atom(TheNumber.use((service) => Effect.succeed(service.n)));

function TestComponent() {
  const value = useAtomValue(numberAtom, AsyncResult.getOrThrow);
  return <div data-testid="value">{value}</div>;
}

render(
  <RegistryProvider
    initialValues={[Atom.initialValue(runtime.layer, Layer.succeed(TheNumber, { n: 69 }))]}
  >
    <TestComponent />
  </RegistryProvider>,
);
```

## Error handling and async rendering

- Render `AsyncResult` explicitly. Do not turn loading or failure into empty arrays or placeholder objects.
- Use `result.waiting` for in-flight state. A `Success` can still be refreshing.
- Use `AsyncResult.builder`, `AsyncResult.match`, or `AsyncResult.matchWithError` at page and route boundaries.
- Preserve and display the real `Cause` for failures. Prefer `Cause.pretty(cause)` or an existing cause-detail component for user-visible diagnostics.
- Use typed service errors for actionable cases. Decode, transport, and other infrastructure failures should be handled at the service boundary as non-actionable defects or reported via `Effect.tapCause`.
- For mutations, prefer `promiseExit` so UI can branch on `Exit.isFailure(exit)` without throwing from event handlers.

```tsx
import * as Cause from "effect/Cause";
import * as AsyncResult from "effect/unstable/reactivity/AsyncResult";

function UsersPanel() {
  const result = useAtomValue(usersAtom);

  return AsyncResult.builder(result)
    .onInitial(() => <Spinner label="Loading users" />)
    .onSuccess((users, state) => <UsersTable users={users} isRefreshing={state.waiting} />)
    .onFailure((cause) => <ErrorBanner detail={Cause.pretty(cause)} />)
    .render();
}
```

Mutation example:

```tsx
const detectSource = useAtomSet(detectSourceAtom, { mode: "promiseExit" });

const exit = await detectSource({
  params: { scopeId },
  payload: { url },
});

if (Exit.isFailure(exit)) {
  setError("Detection failed. Try adding a source manually.");
  return;
}

useDetectedSource(exit.value);
```

When one atom depends on the completed result of another async atom, use `get.result` and decide whether `waiting` should suspend the dependent computation.

```ts
const inner = Atom.make(Effect.succeed(1).pipe(Effect.delay("50 millis")));

const outer = Atom.make((get) => get.result(inner, { suspendOnWaiting: true }));
```

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
