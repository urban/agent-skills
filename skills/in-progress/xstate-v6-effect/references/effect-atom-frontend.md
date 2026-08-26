# Effect Atom frontend integration

## One source of truth

The machine service owns the XState snapshot. Effect Atom exposes it reactively; components render it. Do not copy `snapshot.value`, context, errors, or loading flags into separate writable atoms.

```text
machine service SubscriptionRef
  -> snapshots Stream
  -> runtime.atom(stream)
  -> AsyncResult<MachineSnapshot>
  -> snapshot.matches(...) in React
```

Commands flow in the opposite direction:

```text
React event handler
  -> runtime.fn(machineService.send)
  -> Effect service
  -> machine mailbox
```

## Atom runtime pattern

Assume `CheckoutMachine` is a `Context.Service` whose Layer provides:

- `snapshots: Stream<CheckoutSnapshot>`
- `send(event): Effect<CheckoutSnapshot, MachineStopped>`

Expose it through one Atom runtime:

```ts
import { Effect, Stream } from "effect";
import * as Atom from "effect/unstable/reactivity/Atom";

const machineRuntime = Atom.runtime(CheckoutMachine.layer);

export const checkoutSnapshotAtom = machineRuntime.atom(
  Stream.unwrap(
    Effect.map(CheckoutMachine, (service) => service.snapshots),
  ),
);

export const sendCheckoutEventAtom = machineRuntime.fn(
  (event: CheckoutEvent) =>
    Effect.flatMap(CheckoutMachine, (service) => service.send(event)),
);
```

The snapshot atom is an `AsyncResult` because the runtime Layer and stream have lifecycles. Render `Initial`, `Success`, and `Failure` explicitly. A successful result can still have `waiting: true` during replacement or refresh.

If the service exposes a `SubscriptionRef`, `machineRuntime.subscriptionRef(...)` may be a more direct fit. Keep the service contract stable and select the simpler adapter supported by the installed Effect Atom version.

## React rendering

```tsx
import * as AsyncResult from "effect/unstable/reactivity/AsyncResult";
import { useAtomSet, useAtomValue } from "@effect/atom-react";

export const CheckoutScreen = () => {
  const result = useAtomValue(checkoutSnapshotAtom);
  const send = useAtomSet(sendCheckoutEventAtom, { mode: "promiseExit" });

  return AsyncResult.builder(result)
    .onInitial(() => <Loading />)
    .onFailure((cause) => <MachineError cause={cause} />)
    .onSuccess((snapshot) => {
      if (snapshot.matches("Draft")) {
        return (
          <CheckoutForm
            onSubmit={(orderId) => send({ type: "submit", orderId })}
          />
        );
      }

      if (snapshot.matches("Submitting")) {
        return <Submitting />;
      }

      if (snapshot.matches("Rejected")) {
        return <Rejected reason={snapshot.context.reason} />;
      }

      return <Receipt />;
    })
    .render();
};
```

Use the installed `@effect/atom-react` import path and hook signatures; package layout can move while Effect Atom is unstable.

Why `promiseExit` is useful:

- event handlers can await mailbox acceptance without throwing
- `Exit` preserves typed service failures such as `MachineStopped`
- UI-only feedback about dispatch failure can remain local
- machine transition failures still belong in machine state/events, not thrown callbacks

Do not await command completion from `send` unless that is the service contract. Usually `send` acknowledges the committed transition; later async success/failure appears through the snapshot stream.

## Derived atoms

Derive cheap views from the snapshot atom rather than storing them:

```ts
export const canSubmitAtom = Atom.mapResult(
  checkoutSnapshotAtom,
  (snapshot) => snapshot.matches("Draft"),
);
```

Prefer selectors or `Atom.mapResult` for:

- whether an event is currently legal
- display data from state-specific context
- route/view selection
- progress labels

Keep orchestration in XState. A derived atom may calculate presentation data, but it must not decide a second transition path.

## Families and feature scope

When there is one machine per entity or tab, identity belongs in the Atom boundary:

```ts
export const checkoutSnapshotAtom = Atom.family((checkoutId: CheckoutId) =>
  checkoutRuntime.atom(
    Stream.unwrap(
      Effect.map(CheckoutMachines, (service) => service.snapshots(checkoutId)),
    ),
  ),
);
```

Use a stable structural key for compound identity and include every isolating field. Do not use one singleton snapshot atom for all entities.

Choose cache lifetime deliberately:

- default auto-disposal for component-scoped machines
- idle TTL for revisitable feature state
- `Atom.keepAlive` only for a true application-lifetime machine

When the atom unmounts, the underlying stream scope should unsubscribe. Decide separately whether the machine service stops or remains cached; do not let unmount accidentally destroy backend or application-global state.

## Registry ownership

Put one `RegistryProvider` around the application or feature lifetime. Do not create an `AtomRegistry` or runtime during render.

For SSR or hydration:

- persist only schema-encoded domain snapshots, not opaque live actor references
- create the machine service at the correct request/client scope
- avoid sharing one mutable registry between server requests
- confirm how a restored XState snapshot reaches the service before mounting the stream atom

## When using `@xstate/react` instead

If XState owns the actor runtime, `useMachine` / `useActor` is already the canonical snapshot and dispatch surface. Do not wrap that same actor in writable Effect Atoms merely for consistency.

Effect Atom can still own other application data, and Effect services can still implement `createAsyncLogic`. Use an Atom bridge only when it adds a real boundary such as:

- one Effect service shared by React and non-React consumers
- an Effect-owned interpreter
- composition with other service-backed Atom state
- feature lifetime controlled by an Atom registry

## Frontend side effects

Browser APIs belong behind Effect services:

- DOM/video player
- keyboard listeners
- storage
- WebSocket or HTTP clients
- visibility/focus events

The machine emits commands such as `playVideo` or `startEscapeListener`. Effect service Layers implement HTML5, YouTube, test, or server variants. Components should not query the DOM because a machine entered a state.

Long-lived listeners should be Streams or scoped Effects. Their events feed the machine mailbox, and their finalizers run when the owning state/command fiber is cancelled.
