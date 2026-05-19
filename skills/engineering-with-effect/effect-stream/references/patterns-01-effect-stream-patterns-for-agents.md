# Effect `Stream` patterns for agents — part 1

Covers:

- Effect Stream patterns for agents
- Mental model from repos/effect
- Behavior encapsulation
- Expose streams as service capabilities
- Use Stream.unwrap for per-subscriber setup
- Use Stream.callback for push APIs
- Modular, testable, maintainable services

---

# Effect `Stream` patterns for agents

## Mental model from `.dotai/repos/effect`

- `Stream.Stream<A, E, R>` is a lazy, pull-based, back-pressured sequence. It emits `A`, can fail with `E`, and requires services `R`.
- The implementation is a thin pipeable wrapper around `Channel`. Most operators preserve laziness and build a new stream; nothing runs until a destructor like `Stream.runCollect`, `Stream.runDrain`, `Stream.runForEach`, `Stream.runFold`, `Stream.run`, or `Stream.toReadableStream` is used.
- Streams carry resource scopes. Constructors such as `Stream.callback`, `Stream.fromReadableStream`, `NodeStream.fromReadable`, `Stream.unwrap`, `Stream.scoped`, and `Stream.fromSubscription` are designed so interruption and normal completion can run finalizers.
- Stream output is chunked internally. Prefer stream combinators over manual reader loops; use `bufferArray` when preserving chunks matters and `buffer` when element-level buffering is fine.
- Tests in `.dotai/repos/effect/packages/effect/test/Stream.test.ts` consistently bound long-lived streams before collecting them, use `Effect.scoped` or `Effect.forkScoped` for scoped resources, and use `TestClock` for time-based operators.

## Behavior encapsulation

### Expose streams as service capabilities

A service should own the low-level source and expose a domain stream. Keep queues, callback handles, file watchers, child-process handles, sockets, and web readers private unless the caller truly owns their lifecycle.

Adapted from Effect PubSub docs:

```ts
import { Context, Effect, Layer, PubSub, Schema, Stream } from "effect";

export interface VoiceAssessmentEvent {
  readonly sessionId: string;
  readonly kind: "Started" | "TranscriptDelta" | "Completed";
  readonly message: string;
}

export class VoiceAssessmentEventError extends Schema.TaggedErrorClass<VoiceAssessmentEventError>()(
  "VoiceAssessmentEventError",
  {
    reason: Schema.Literals(["PublishRejected"]),
  },
) {}

export interface VoiceAssessmentEventsShape {
  readonly publish: (event: VoiceAssessmentEvent) => Effect.Effect<void, VoiceAssessmentEventError>;
  readonly streamSession: (sessionId: string) => Stream.Stream<VoiceAssessmentEvent>;
}

export class VoiceAssessmentEvents extends Context.Service<
  VoiceAssessmentEvents,
  VoiceAssessmentEventsShape
>()("fiberisle/VoiceAssessmentEvents") {
  static readonly layer: Layer.Layer<VoiceAssessmentEvents> = Layer.effect(
    VoiceAssessmentEvents,
    Effect.gen(function* () {
      const pubsub = yield* PubSub.bounded<VoiceAssessmentEvent>(128);

      return VoiceAssessmentEvents.of({
        publish: (event) => PubSub.publish(pubsub, event).pipe(Effect.asVoid),
        streamSession: (sessionId) =>
          Stream.fromPubSub(pubsub).pipe(Stream.filter((event) => event.sessionId === sessionId)),
      });
    }),
  );
}
```

Guidelines:

- Let the service define the lifecycle: when a stream starts, when it ends, how interruption releases resources, and which failures are actionable.
- Yield services from context inside service construction or effect bodies. Do not pass service instances into stream helpers.
- Keep the stream payload domain-level. Do not leak protocol frames unless the service is itself a protocol boundary.
- Add a snapshot before live events when subscribers need immediate state, as in `ws.ts` and `VcsStatusBroadcaster.ts`.

### Use `Stream.unwrap` for per-subscriber setup

Use `Stream.unwrap` when each subscription must acquire a subscription, read a snapshot, register a poller, or compute stream-specific state. Attach cleanup with `Stream.ensuring`.

Example pattern:

```ts
import { Effect, PubSub, Stream } from "effect";

interface StatusSnapshot {
  readonly localBranch: string;
}

interface StatusEvent {
  readonly cwd: string;
  readonly message: string;
}

declare const changes: PubSub.PubSub<StatusEvent>;
declare const loadSnapshot: (cwd: string) => Effect.Effect<StatusSnapshot>;
declare const retainPoller: (cwd: string) => Effect.Effect<void>;
declare const releasePoller: (cwd: string) => Effect.Effect<void>;

export const streamStatus = (cwd: string) =>
  Stream.unwrap(
    Effect.gen(function* () {
      const subscription = yield* PubSub.subscribe(changes);
      const snapshot = yield* loadSnapshot(cwd);
      yield* retainPoller(cwd);

      return Stream.concat(
        Stream.make({ type: "Snapshot", snapshot }),
        Stream.fromSubscription(subscription).pipe(
          Stream.filter((event) => event.cwd === cwd),
          Stream.map((event) => ({ type: "Event", event })),
        ),
      ).pipe(Stream.ensuring(releasePoller(cwd)));
    }),
  );
```

### Use `Stream.callback` for push APIs

`Stream.callback` is the right adapter for callback-style APIs. Register cleanup inside the callback effect so stream interruption unregisters handlers. Set a buffer size and strategy deliberately; the Effect tests show backpressure with `bufferSize` and cleanup on interruption.

```ts
import { Cause, Effect, Queue, Schema, Stream } from "effect";

export class WatchError extends Schema.TaggedErrorClass<WatchError>()("WatchError", {
  reason: Schema.Literals(["ReadFailed"]),
  cause: Schema.Defect,
}) {}

interface WatchHandle {
  readonly close: () => void;
}

interface WatchSource<Event> {
  readonly subscribe: (input: {
    readonly event: (event: Event) => void;
    readonly error: (cause: unknown) => void;
    readonly end: () => void;
  }) => WatchHandle;
}

export const watchSource = <Event>(source: WatchSource<Event>): Stream.Stream<Event, WatchError> =>
  Stream.callback<Event, WatchError>(
    Effect.fnUntraced(function* (queue) {
      yield* Effect.acquireRelease(
        Effect.sync(() =>
          source.subscribe({
            event: (event) => Queue.offerUnsafe(queue, event),
            error: (cause) =>
              Queue.failCauseUnsafe(
                queue,
                Cause.fail(new WatchError({ reason: "ReadFailed", cause })),
              ),
            end: () => Queue.endUnsafe(queue),
          }),
        ),
        (handle) => Effect.sync(() => handle.close()),
      );
    }),
    { bufferSize: 16, strategy: "suspend" },
  );
```

## Modular, testable, maintainable services
