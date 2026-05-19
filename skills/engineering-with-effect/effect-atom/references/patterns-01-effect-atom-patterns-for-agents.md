# Effect `Atom` patterns for agents — part 1

Covers:

- Effect Atom patterns for agents
- Core model
- Encapsulate behavior outside components
- Services should be modular, testable, and maintainable
- Error handling and async rendering

---

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
