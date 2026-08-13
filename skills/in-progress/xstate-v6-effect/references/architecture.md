# Architecture: XState decides when, Effect decides how

## Responsibility split

| Concern | Owner | Reason |
| --- | --- | --- |
| legal states and events | XState | the statechart makes impossible paths explicit |
| next-state calculation | XState | `initialTransition` and `transition` are pure reducers |
| outgoing work description | XState | emitted commands record what the chosen transition requires |
| service implementation | Effect | requirements stay in the typed context and are supplied by Layers |
| expected failures | Effect domain services, then machine events | failures remain typed and the machine chooses recovery |
| mailbox serialization | Effect-owned interpreter or XState actor runtime | exactly one owner must order events |
| time, interruption, retries, resources | chosen runtime owner | competing runtimes produce duplicate or untestable behavior |
| UI projection | Effect Atom or framework binding | projection must not become another state owner |

This is the talk's core distinction: a state machine is the map; Effect is the execution engine. A well-engineered Effect program can still implement the wrong behavioral path, while a correct statechart still needs safe effect execution.

## Integration modes

### Mode A: Effect-owned interpreter

Use when Effect must own the runtime.

The machine is pure. The interpreter owns:

- one serialized event mailbox
- the current XState snapshot
- publication of snapshot changes
- execution of emitted commands
- fibers for in-flight work and timers
- cancellation and shutdown
- result events fed back to the mailbox
- persistence policy

Prefer a domain command algebra carried by XState emitted events:

```ts
import { Schema } from "effect";
import { setup } from "xstate";

const standard = Schema.toStandardSchemaV1;

const Submit = Schema.Struct({ orderId: Schema.String });
const Submitted = Schema.Struct({ orderId: Schema.String });
const SubmitRejected = Schema.Struct({
  orderId: Schema.String,
  reason: Schema.Literals(["OutOfStock", "PaymentDeclined"]),
});

export const orderMachine = setup({
  schemas: {
    events: {
      submit: standard(Submit),
      submitted: standard(Submitted),
      submitRejected: standard(SubmitRejected),
    },
    emitted: {
      submitOrder: standard(Submit),
    },
  },
}).createMachine({
  initial: "Draft",
  states: {
    Draft: {
      on: {
        submit: ({ event }, enq) => {
          enq.emit({ type: "submitOrder", orderId: event.orderId });
          return { target: "Submitting" };
        },
      },
    },
    Submitting: {
      on: {
        submitted: { target: "Submitted" },
        submitRejected: { target: "Rejected" },
      },
    },
    Submitted: {},
    Rejected: {},
  },
});
```

The interpreter handles the `submitOrder` emitted effect with an Effect service, then offers either `submitted` or `submitRejected` to the mailbox. The machine never imports a payment client or runs a promise.

#### Backend service shape

Expose behavior rather than infrastructure:

```ts
type MachineService<Snapshot, Event> = {
  readonly send: (event: Event) => Effect.Effect<Snapshot, MachineStopped>;
  readonly getSnapshot: Effect.Effect<Snapshot>;
  readonly snapshots: Stream.Stream<Snapshot>;
};
```

A typical scoped implementation uses:

- `Queue` for input envelopes
- `SubscriptionRef` for the current snapshot and `SubscriptionRef.changes` for subscribers
- a scoped mailbox fiber
- `FiberMap` or supervised child fibers for correlated commands and timers
- `Deferred` in each envelope when `send` must await the transition result
- a Layer to provide command-handler services and own cleanup

The mailbox pattern is:

1. Compute `[initialSnapshot, initialEffects]` with `initialTransition`.
2. Publish the initial snapshot.
3. Interpret initial effects.
4. Take one envelope from the queue.
5. Compute `[nextSnapshot, effects]` with `transition`.
6. Publish `nextSnapshot` before or after effects according to an explicitly documented contract.
7. Interpret effects in order; fork ongoing work rather than blocking the mailbox.
8. Complete the sender's `Deferred` and continue while the snapshot is active.

This is an architectural pattern, not permission to write one generic interpreter casually. XState v6 executable effects include custom actions, emits, spawn/start/stop/terminate, raises, sends, cancellation, and timers. Reject unsupported kinds deterministically.

#### Command completion and cancellation

Use correlation IDs when more than one command can be active. A command should carry enough identity for its result and cancellation events:

```text
startUpload { uploadId, fileId }
  -> uploadSucceeded { uploadId, fileId }
  -> uploadFailed { uploadId, fileId, reason }

cancelUpload { uploadId }
```

Fork ongoing work in a scope keyed by `uploadId`. On cancellation or state exit, interrupt that fiber. An interrupted command must not later enqueue a stale success event.

### Mode B: XState-owned actor with an Effect bridge

Use when the XState actor runtime and bindings are valuable. XState owns mailbox, clock, children, invocation, and subscriptions. Effect owns invoked service implementations.

- Create one `ManagedRuntime` from the application's Layer.
- In `createAsyncLogic.run`, call `managedRuntime.runPromise(program, { signal })`.
- Dispose the managed runtime at application shutdown.
- Convert expected failures to tagged output data before crossing the Promise boundary.
- Let unexpected defects reject so `onError` remains exceptional.

This mode is simpler for `@xstate/react`, `invoke`, actor trees, `enq.listen`, `enq.subscribeTo`, and built-in persistence. It does not satisfy the stronger claim that Effect owns scheduling or the actor runtime.

### Mode C: direct pure decisions

For request-local or test-only logic with no ongoing work, call the pure APIs directly:

```ts
const [initial, initialEffects] = initialTransition(machine, input);
const [next, effects] = transition(machine, initial, event);
```

If effects must execute, choose Mode A or B rather than adding ad hoc callbacks at each call site.

## Runtime completeness boundary

An Effect-owned adapter that supports generic XState actor features must account for the v6 `ActorSystemRuntime` operations:

- `spawnActor`
- `startActor`
- `stopActor`
- `terminateActor`
- `sendEvent`
- `emitEvent`
- `scheduleTimer`
- `cancelTimer`
- `cancelAllTimers`

`executeEffects(effects, runtime)` awaits XState effect objects sequentially, but it is Promise-based. Calling it from Effect via a Promise bridge can still make Effect the outer owner, yet custom actions may execute arbitrary callbacks and the runtime contract still needs complete lifecycle semantics. Prefer direct command interpretation for a constrained domain adapter; implement the complete runtime for generic XState support.

## Timers

Choose one timer model:

1. **XState built-in timers**: keep `after`, `timeout`, and delayed `enq.raise`/`enq.sendTo`; implement scheduling and cancellation through an Effect-backed `ActorSystemRuntime`.
2. **Domain timer commands**: emit `startTimer` and `cancelTimer`; Effect uses `Effect.sleep` in keyed fibers and returns an elapsed event.

The second model is easier for a constrained interpreter and makes the clock injectable. It must still cancel timers on state exit. Never combine both models for the same timeout.

## Persistence and backend durability

XState v6 persisted snapshots are not compatible with v5. Set a machine `version`, persist the version with the snapshot, and define migration or rejection policy.

For local rehydration:

- persist only encoded, schema-validated data
- restore the snapshot before accepting new events
- restore or deliberately cancel in-flight command records
- ensure replay cannot duplicate non-idempotent work

XState durable timers store logical declarations, not wall-clock due dates. A local restore restarts the full declared delay. Durable backends that need wall-clock semantics must persist `scheduledAt`/`dueAt` separately.

A snapshot alone does not provide exactly-once effects. For money movement, email, jobs, or external writes, use idempotency keys and an outbox/workflow protocol. Decide atomically how the next snapshot and outgoing command record are committed before claiming crash safety.
