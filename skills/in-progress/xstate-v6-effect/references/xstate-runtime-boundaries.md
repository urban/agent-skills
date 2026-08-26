# XState v6 runtime boundaries

## Pure transition APIs

```ts
import { initialTransition, transition } from "xstate";

const [initialSnapshot, initialEffects] = initialTransition(machine, input);
const [nextSnapshot, effects] = transition(
  machine,
  initialSnapshot,
  { type: "submit", orderId: "o-1" },
);
```

The methods also exist on the machine:

```ts
const [initialSnapshot, initialEffects] = machine.initialTransition(input);
const [nextSnapshot, effects] = machine.transition(initialSnapshot, event);
```

Both forms are pure and do not execute returned effects. Effects are ordered `ExecutableActionObject`s. Current kinds include custom action, emitted event, spawn, start, raise, send, cancel, stop, and terminate.

Use `getInitialMicrosteps` / `getMicrosteps` only when inspection or per-microstep execution is required. Normal application loops should use the macrostep result from `initialTransition` / `transition`.

## Effect-owned execution

Use the pure APIs as the calculation kernel and let one serialized Effect mailbox own snapshots and execution. Read [`effect-integration.md`](./effect-integration.md) for the constrained emitted-command adapter and full `ActorSystemRuntime` boundary.

Do not call `executeEffects` without understanding its behavior. It executes arbitrary custom actions and delegates built-ins through a Promise-shaped runtime contract. An Effect-owned domain adapter should interpret only its explicit command algebra and reject unsupported kinds; a generic adapter must implement the complete actor runtime semantics.

## XState-owned actor, Effect-owned work

Use this branch when XState should own mailbox, actor lifecycle, timers, and framework bindings while Effect implements invoked work.

### Reuse one managed runtime

```ts
import { Effect, ManagedRuntime, Schema } from "effect";
import { createAsyncLogic } from "xstate";

const runtime = ManagedRuntime.make(AppLayer);

const logic = createAsyncLogic({
  schemas: {
    input: Schema.toStandardSchemaV1(Input),
    output: Schema.toStandardSchemaV1(Outcome),
  },
  run: ({ input, signal }) =>
    runtime.runPromise(
      program(input).pipe(Effect.result),
      { signal },
    ),
});
```

The exact result combinator and output schema must agree with the installed Effect version and domain model. Keep these invariants:

- create the runtime at the application or feature composition root
- reuse it across invocations
- pass XState's `AbortSignal`
- dispose it with `runtime.dispose()` or `runtime.disposeEffect`
- never rebuild the Layer inside `run`

### Preserve typed failures

Promise rejection erases the typed Effect error channel at the XState boundary. Transform expected failures into a schema-backed output union before `runPromise`:

```text
SubmitOutcome =
  | { _tag: "Submitted", receiptId }
  | { _tag: "OutOfStock", productId }
  | { _tag: "PaymentDeclined", reason }
```

`onDone` exhaustively maps every outcome to a transition. `onError` handles defects and only those infrastructure failures the boundary policy intentionally leaves exceptional.

Do not catch every cause and return a generic string. Keep actionable cases typed; format causes only at an operator or UI display boundary.

### Cancellation

Passing `{ signal }` to `ManagedRuntime.runPromise` interrupts the Effect fiber when XState cancels the async actor. The Effect program must use interruptible, scoped resource APIs so cancellation releases resources. Promise APIs that ignore abort need an Effect adapter with explicit cleanup.

### Durable async logic

`createAsyncLogic` supports XState features such as timeout, `AbortSignal`, emitted events, and durable `enq.step` outcomes. These guarantees belong to XState-owned mode. Do not assume they carry into a separate Effect-owned custom interpreter.

## Other runtime features

- `actor.trigger.EVENT(payload)` is a typed alternative to `actor.send` in XState-owned mode.
- `actor.select(selector)` creates a memoized subscribable projection; do not mirror it in Effect Atom without a separate responsibility.
- `internalEvents` restricts external sending but does not validate payloads.
- `type: "choice"` must resolve a target.
- `timeout` / `onTimeout` and duration strings require the chosen runtime to schedule them.
- machine `version` supports persisted snapshot compatibility checks.
- spawned or invoked children require registered logic for persistence and rehydration.
