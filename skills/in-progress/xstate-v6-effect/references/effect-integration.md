# Effect integration patterns

## Effect-owned interpreter

### Public contract

Keep XState and Effect implementation details behind a domain service. A useful contract exposes:

- `send(event)` — serialize a validated event and optionally await its committed transition
- `getSnapshot` — read the latest snapshot
- `snapshots` — subscribe to current and future snapshots
- no public mailbox, mutable ref, or raw fiber

The service implementation belongs in a scoped Layer. The Layer should start the loop once and interrupt it on release.

### Core state

The talk maps XState actor concepts directly to Effect primitives:

| Actor concept | Effect primitive |
| --- | --- |
| mailbox | `Queue` |
| current machine snapshot | `SubscriptionRef` or `Ref` plus a publication stream |
| actor process | scoped `Fiber` |
| invoked work and timers | supervised fibers / `FiberMap` |
| service implementation | `Context.Service` supplied by `Layer` |
| swappable HTML5/YouTube implementation | alternate service Layers |
| time | `Effect.sleep` and test clock |

Use `SubscriptionRef` when frontend or backend subscribers need every committed update. Its `changes` stream includes the current value and subsequent updates.

### Transition kernel

Keep the state calculation in one small pure function:

```ts
import type { AnyActorLogic, EventFromLogic, SnapshotFrom } from "xstate";
import { transition } from "xstate";

const reduceEvent = <Logic extends AnyActorLogic>(
  logic: Logic,
  snapshot: SnapshotFrom<Logic>,
  event: EventFromLogic<Logic>,
) => transition(logic, snapshot, event);
```

Do not make the kernel acquire services or execute effects. The mailbox fiber calls it, commits the returned snapshot, then delegates returned executable effects to an adapter.

### Interpret only an explicit command algebra

For a constrained domain interpreter, accept emitted commands and reject everything not in the supported set:

```ts
const interpretExecutable = (
  executable: ExecutableActionObject,
): Effect.Effect<void, MachineExecutionError, CommandServices> => {
  if (executable.kind !== "emit") {
    return Effect.fail(
      new MachineExecutionError({
        reason: "UnsupportedExecutableKind",
        detail: executable.type,
      }),
    );
  }

  return Schema.decodeUnknownEffect(MachineCommand)(executable.event).pipe(
    Effect.flatMap(executeMachineCommand),
  );
};
```

`MachineCommand` is an Effect Schema union of outgoing command variants. `executeMachineCommand` should use `Match.tagsExhaustive` or an equivalent exhaustive match and acquire implementations from Effect services.

This strict failure is intentional. If someone adds `after`, `invoke`, `enq.raise`, `enq.sendTo`, `enq.spawn`, or `enq(fn)` later, tests fail instead of silently dropping behavior.

### Feed outcomes back as events

A command handler must not mutate the snapshot. It returns machine events through the mailbox:

```text
machine emits LoadUser { requestId, userId }
Effect forks UserRepository.get(userId)
  success -> mailbox offers UserLoaded { requestId, user }
  expected failure -> mailbox offers UserLoadRejected { requestId, reason }
  interruption -> no stale completion event
  defect -> runtime policy logs/terminates/escalates
```

Decode result events too when they cross a process or trust boundary. Internal constructors may create them safely without decoding if their values already satisfy domain types.

### Do not block the actor

A mailbox loop should await only short transition bookkeeping. For ongoing work:

- fork in the machine scope
- key the fiber by command/correlation ID
- return success or expected failure through the queue
- interrupt on cancellation, replacement, or machine shutdown
- guard against stale results by checking identity in the machine transition

Sequentially awaiting a remote request in the mailbox prevents cancel, timeout, and UI events from being processed.

### Ordering contract

Choose and document one ordering policy. A common policy is:

1. calculate transition
2. commit/publish snapshot
3. start commands in returned order
4. acknowledge the sender

This lets observers see the `Submitting` state before a fast command produces `Submitted`. If persistence requires an atomic snapshot/outbox commit, persist both before starting external work.

If command-start failure must prevent state publication, model that as a different protocol rather than changing order ad hoc.

### Timers

For domain timer commands, use a keyed fiber:

```text
StartTimer { timerId, duration, elapsedEvent }
CancelTimer { timerId }
```

The handler for `StartTimer` forks `Effect.sleep(duration)` followed by offering `elapsedEvent`. The handler for `CancelTimer` interrupts the matching fiber. Effect `TestClock` then controls time deterministically.

For XState's built-in delayed effects, implement the full timer portion of `ActorSystemRuntime`. XState stores logical timer IDs and expects `{ type: "xstate.timer", id }` delivery to the source. Do not reinterpret the public event as the final delayed event yourself without following the current v6 runtime contract.

### Shutdown

A scoped release should:

- stop accepting sends
- interrupt the mailbox fiber
- interrupt command and timer fibers
- shut down or release the queue
- close snapshot publication
- run service finalizers
- reject later sends with a typed `MachineStopped` failure

Terminal XState snapshots should stop normal event processing. Decide whether subscribers receive the terminal snapshot before stream completion.

## Full XState runtime under Effect

A generic adapter can execute XState's returned effects using a custom `ActorSystemRuntime`. This is infrastructure, not domain code.

Requirements:

- implement all runtime operations used by enabled features
- preserve effect ordering
- route reentrant sends through the mailbox, never recursively call `transition`
- supervise child actor start/stop/termination
- preserve source and target actor identity
- schedule and cancel logical timers by source session and timer ID
- publish emitted events
- complete children before notifying parents
- cover persistence and restoration semantics if advertised

XState's own `custom-interpreter.test.ts` is the best executable specification for the current contract. Copying a minimal example that only handles `sendEvent` is not sufficient once machines gain children or timers.

Because `ExecutableActionObject.exec(runtime?)` returns `void | PromiseLike<void>`, an adapter may expose Promise callbacks backed by an Effect runtime. Keep that callback bridge at the outer edge. Domain command handlers should remain ordinary typed Effects.

## Services and Layers

Machine command handlers should depend on small domain services such as `VideoPlayer.play`, `VideoPlayer.pause`, and `VideoPlayer.ended`. Provide alternate Layers for HTML video, YouTube, tests, and backend adapters. The state machine should not change when implementations change.

Keep observability at execution boundaries: span correlated command work, use low-cardinality machine/state/command attributes, and avoid embedding logging actions in the machine.
