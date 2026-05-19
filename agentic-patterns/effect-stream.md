# Effect `Stream` patterns for agents

These patterns are based on the `Stream` implementation and tests in `repos/effect`, the Effect stream docs in `repos/effect/ai-docs/src/02_stream`, and stream usage in `repos/t3code`, `repos/executor`, and `repos/alchemy-effect`.

## Mental model from `repos/effect`

- `Stream.Stream<A, E, R>` is a lazy, pull-based, back-pressured sequence. It emits `A`, can fail with `E`, and requires services `R`.
- The implementation is a thin pipeable wrapper around `Channel`. Most operators preserve laziness and build a new stream; nothing runs until a destructor like `Stream.runCollect`, `Stream.runDrain`, `Stream.runForEach`, `Stream.runFold`, `Stream.run`, or `Stream.toReadableStream` is used.
- Streams carry resource scopes. Constructors such as `Stream.callback`, `Stream.fromReadableStream`, `NodeStream.fromReadable`, `Stream.unwrap`, `Stream.scoped`, and `Stream.fromSubscription` are designed so interruption and normal completion can run finalizers.
- Stream output is chunked internally. Prefer stream combinators over manual reader loops; use `bufferArray` when preserving chunks matters and `buffer` when element-level buffering is fine.
- Tests in `repos/effect/packages/effect/test/Stream.test.ts` consistently bound long-lived streams before collecting them, use `Effect.scoped` or `Effect.forkScoped` for scoped resources, and use `TestClock` for time-based operators.

## Behavior encapsulation

### Expose streams as service capabilities

A service should own the low-level source and expose a domain stream. Keep queues, callback handles, file watchers, child-process handles, sockets, and web readers private unless the caller truly owns their lifecycle.

Adapted from `repos/t3code/apps/server/src/serverLifecycleEvents.ts`, `repos/t3code/apps/server/src/serverSettings.ts`, and Effect PubSub docs:

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

Adapted from `repos/t3code/apps/server/src/vcs/VcsStatusBroadcaster.ts`:

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

Adapted from `repos/effect/packages/effect/test/Stream.test.ts` and `repos/t3code/apps/server/src/ws.ts`:

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

### Split source, boundary decoding, domain transforms, and sinks

Keep pipeline stages separate:

1. source: `Stream.fromPubSub`, `Stream.callback`, `Stream.fromReadableStream`, `NodeStream.fromReadable`, `response.stream`, process output, or a page API;
2. boundary decoding and schema validation;
3. pure and effectful domain transforms;
4. terminal sink at the application edge.

Adapted from `repos/alchemy-effect/packages/alchemy/src/Cloudflare/Workers/Rpc.ts`, `repos/t3code/apps/server/src/textGeneration/ClaudeTextGeneration.ts`, and `repos/effect/ai-docs/src/02_stream/30_encoding.ts`:

```ts
import { Effect, Schema, Stream } from "effect";

const TranscriptFrame = Schema.Union(
  Schema.Struct({ type: Schema.Literal("Delta"), text: Schema.String }),
  Schema.Struct({ type: Schema.Literal("Done") }),
).annotate({ identifier: "TranscriptFrame" });

type TranscriptFrame = typeof TranscriptFrame.Type;

export class TranscriptFrameDecodeError extends Schema.TaggedErrorClass<TranscriptFrameDecodeError>()(
  "TranscriptFrameDecodeError",
  {
    reason: Schema.Literals(["InvalidFrame"]),
    cause: Schema.Defect,
  },
) {}

const decodeTranscriptFrame = Schema.decodeUnknownEffect(Schema.fromJsonString(TranscriptFrame));

export const decodeTranscriptFrames = <E>(
  body: Stream.Stream<Uint8Array, E>,
): Stream.Stream<TranscriptFrame, E | TranscriptFrameDecodeError> =>
  body.pipe(
    Stream.decodeText(),
    Stream.splitLines,
    Stream.filter((line) => line.trim().length > 0),
    Stream.mapEffect((line) =>
      decodeTranscriptFrame(line).pipe(
        Effect.mapError(
          (cause) => new TranscriptFrameDecodeError({ reason: "InvalidFrame", cause }),
        ),
      ),
    ),
  );
```

### Keep sinks at edges

A service that transforms a stream should usually return another stream. A service that performs a command, writes stdin, stores rows, publishes events, or returns an aggregate can run the stream internally.

Adapted from `repos/t3code/apps/server/src/processRunner.ts` and `repos/alchemy-effect/packages/alchemy/src/Build/Command.ts`:

```ts
import { Effect, Schema, Sink, Stream } from "effect";

export class ProcessReadError extends Schema.TaggedErrorClass<ProcessReadError>()(
  "ProcessReadError",
  {
    stream: Schema.Literals(["Stdout", "Stderr"]),
    cause: Schema.Defect,
  },
) {}

interface ChildHandle {
  readonly stdin: Sink.Sink<void, Uint8Array>;
  readonly stdout: Stream.Stream<Uint8Array, ProcessReadError>;
  readonly stderr: Stream.Stream<Uint8Array, ProcessReadError>;
  readonly exitCode: Effect.Effect<number, ProcessReadError>;
}

const collectText = (stream: Stream.Stream<Uint8Array, ProcessReadError>) =>
  stream.pipe(
    Stream.decodeText(),
    Stream.runFold(
      () => "",
      (text, chunk) => `${text}${chunk}`,
    ),
  );

export const collectChildOutput = (child: ChildHandle, stdin: string) =>
  Effect.all(
    [
      collectText(child.stdout),
      collectText(child.stderr),
      Stream.run(Stream.encodeText(Stream.make(stdin)), child.stdin),
      child.exitCode,
    ],
    { concurrency: "unbounded" },
  );
```

### Make tests consume bounded public streams

Use public service methods and bounded stream destructors. Prefer injected boundary layers and in-memory streams over implementation-detail assertions.

Adapted from `repos/t3code/apps/server/src/server.test.ts`, `repos/t3code/apps/server/src/processRunner.test.ts`, and Effect stream tests:

```ts
import { Deferred, Effect, PubSub, Stream } from "effect";

export const collectTwoEvents = Effect.gen(function* () {
  const pubsub = yield* PubSub.unbounded<string>();
  const collected = yield* Deferred.make<ReadonlyArray<string>>();

  yield* Stream.fromPubSub(pubsub).pipe(
    Stream.take(2),
    Stream.runCollect,
    Effect.flatMap((events) => Deferred.succeed(collected, events)),
    Effect.forkScoped,
  );

  yield* PubSub.publish(pubsub, "first");
  yield* PubSub.publish(pubsub, "second");

  return yield* Deferred.await(collected);
});
```

Testing rules:

- Cap streams with `Stream.take`, `Stream.takeUntil`, `Stream.timeout`, or a limiting fold before `runCollect`.
- Use `TestClock.adjust` for `debounce`, `throttle`, `repeat`, `retry`, `schedule`, and `groupedWithin`.
- Use `Deferred`, `Ref`, and `Queue` for deterministic coordination. Do not use arbitrary sleeps.
- Test cleanup by interrupting a scoped fiber and asserting finalizers ran, following the `Stream.callback` cleanup tests.

## Error handling patterns

### Map external failures at the boundary

Convert platform, process, socket, parser, HTTP, and vendor failures into precise tagged errors as close to the boundary as possible.

Adapted from `repos/t3code/apps/server/src/processRunner.ts`, `repos/alchemy-effect/packages/alchemy/src/Cloudflare/Workers/Rpc.ts`, and `repos/effect/packages/effect/src/Stream.ts`:

```ts
import { Effect, Schema, Stream } from "effect";

export class OutputLimitError extends Schema.TaggedErrorClass<OutputLimitError>()(
  "OutputLimitError",
  {
    stream: Schema.Literals(["Stdout", "Stderr"]),
    maxBytes: Schema.Number,
  },
) {}

export class OutputReadError extends Schema.TaggedErrorClass<OutputReadError>()("OutputReadError", {
  stream: Schema.Literals(["Stdout", "Stderr"]),
  cause: Schema.Defect,
}) {}

interface CollectState {
  readonly chunks: ReadonlyArray<Uint8Array>;
  readonly bytes: number;
}

export const collectLimited = <E>(input: {
  readonly streamName: "Stdout" | "Stderr";
  readonly stream: Stream.Stream<Uint8Array, E>;
  readonly maxBytes: number;
}): Effect.Effect<{ readonly bytes: number }, OutputReadError | OutputLimitError> =>
  input.stream.pipe(
    Stream.mapError((cause) => new OutputReadError({ stream: input.streamName, cause })),
    Stream.runFoldEffect(
      (): CollectState => ({ chunks: [], bytes: 0 }),
      (state, chunk) => {
        const nextBytes = state.bytes + chunk.byteLength;
        if (nextBytes > input.maxBytes) {
          return Effect.fail(
            new OutputLimitError({ stream: input.streamName, maxBytes: input.maxBytes }),
          );
        }

        return Effect.succeed({
          chunks: [...state.chunks, chunk],
          bytes: nextBytes,
        });
      },
    ),
    Effect.map((state) => ({ bytes: state.bytes })),
  );
```

### Recover only from expected typed errors

Use stream error combinators when continuing is part of the product behavior:

- `Stream.mapError` to translate dependency errors;
- `Stream.catchTag` / `Stream.catchTags` for tagged error recovery;
- `Stream.retry(schedule)` when rebuilding the whole stream is valid;
- `Stream.repeat(schedule)` when normal completion should poll or reconnect;
- `Stream.tapError`, `Stream.tapCause`, `Stream.onError`, and `Stream.catchCause` for boundary observation or protocol conversion.

```ts
import { Schedule, Schema, Stream } from "effect";

class RemoteEventError extends Schema.TaggedErrorClass<RemoteEventError>()("RemoteEventError", {
  reason: Schema.Literals(["Disconnected", "InvalidFrame"]),
}) {}

declare const remoteEvents: Stream.Stream<string, RemoteEventError>;

export const resilientEvents = remoteEvents.pipe(
  Stream.catchTag("RemoteEventError", (error) =>
    error.reason === "InvalidFrame"
      ? Stream.succeed("RecoveredFromInvalidFrame")
      : Stream.fail(error),
  ),
  Stream.retry(Schedule.exponential("1 second")),
);
```

Do not recover from defects or unexpected causes unless the stream is crossing a protocol boundary and you are intentionally encoding the failure for a remote consumer.

### Preserve remote stream failures explicitly

When a stream crosses RPC, HTTP, worker, or WebSocket boundaries, encode stream failures as protocol frames and decode them back into the error channel. `repos/alchemy-effect/packages/alchemy/src/Cloudflare/Workers/Rpc.ts` uses `Stream.catchCause` to append an error marker and `Stream.flatMap` to turn remote error markers back into `Stream.fail`.

```ts
import { Cause, Effect, Schema, Stream } from "effect";

const RemoteFrame = Schema.Union(
  Schema.Struct({ type: Schema.Literal("Data"), value: Schema.String }),
  Schema.Struct({ type: Schema.Literal("Error"), message: Schema.String }),
).annotate({ identifier: "RemoteFrame" });

type RemoteFrame = typeof RemoteFrame.Type;

const encodeRemoteFrame = Schema.encodeEffect(Schema.fromJsonString(RemoteFrame));

export class RemoteStreamError extends Schema.TaggedErrorClass<RemoteStreamError>()(
  "RemoteStreamError",
  {
    reason: Schema.Literals(["RemoteFailed"]),
    message: Schema.String,
  },
) {}

export const failRemoteFrames = (
  frames: Stream.Stream<RemoteFrame>,
): Stream.Stream<string, RemoteStreamError> =>
  frames.pipe(
    Stream.flatMap((frame) =>
      frame.type === "Error"
        ? Stream.fail(new RemoteStreamError({ reason: "RemoteFailed", message: frame.message }))
        : Stream.succeed(frame.value),
    ),
  );

export const appendFailureFrame = <E>(lines: Stream.Stream<string, E>): Stream.Stream<string> =>
  lines.pipe(
    Stream.catchCause((cause) =>
      Stream.fromEffect(
        encodeRemoteFrame({
          type: "Error",
          message: Cause.pretty(cause),
        }).pipe(Effect.map((line) => `${line}\n`)),
      ),
    ),
  );
```

## Encoding and protocol boundaries

- Use `Stream.decodeText()` and `Stream.encodeText` for byte/text boundaries. Effect tests cover split multi-byte characters.
- Use `Stream.splitLines` for line-oriented protocols.
- Use `Schema.fromJsonString(...)` for JSON input/output in implementation code.
- Use `Stream.pipeThroughChannel(Ndjson.decodeSchemaString(MySchema)())` and `Ndjson.encodeSchemaString(MySchema)()` for NDJSON.
- Use `effect/unstable/encoding/Sse` for SSE framing. The Effect AI clients use `Stream.pipeThroughChannel(Sse.decodeDataSchema(schema))`; do not hand-roll SSE parsing or formatting.
- Use `Stream.fromReadableStream` / `Stream.toReadableStreamEffect` for Web streams and `NodeStream.fromReadable` / `NodeStream.toReadable` for Node streams.
- Convert to raw `ReadableStream`, `Readable`, callbacks, or sinks only at the external boundary.

## Constructor and operator choices

- finite values: `Stream.make`, `Stream.fromIterable`, `Stream.fromArray`;
- one effectful value: `Stream.fromEffect`;
- polling: `Stream.fromEffectSchedule`, `Stream.repeat`, `Stream.schedule`;
- paginated APIs: `Stream.paginate`;
- existing producer queue: `Stream.fromQueue`;
- fan-out domain events: `Stream.fromPubSub` or `Stream.fromSubscription`;
- callback APIs: `Stream.callback`;
- Web body: `Stream.fromReadableStream`;
- Node body: `NodeStream.fromReadable`;
- effectful per-element transform: `Stream.mapEffect` with explicit concurrency when parallelism is safe;
- unbounded or fast producer: `Stream.buffer` / `Stream.bufferArray` with intentional capacity and strategy;
- process stdin or file writes: `Stream.run(stream, sink)`;
- fire-and-forget consumption inside a scoped service: `Stream.runForEach(...).pipe(Effect.forkIn(scope))` or `Effect.forkScoped`.

## What to avoid

- Do not write ad hoc async generators, manual `ReadableStream` reader loops, event-emitter arrays, or callback buffering when a `Stream` constructor models the source.
- Do not expose `Queue`, `PubSub`, sockets, file watchers, or process handles as service APIs when callers only need a stream.
- Do not pass service instances into stream functions. Yield services from context inside service construction or effect bodies.
- Do not use `Effect.orDie` or `Stream.die` for expected failures. Map expected failures to tagged errors and handle them explicitly.
- Do not invent generic errors like `InternalError`, `UnknownError`, or `XFailed` for stream failures.
- Do not erase stream error channels to `unknown`; keep `Stream.Stream<A, E, R>` precise.
- Do not `runCollect` infinite or long-lived streams unless capped first.
- Do not add arbitrary sleeps in tests for time-based streams; use `TestClock`.
- Do not manually parse JSON, NDJSON, or SSE in implementation code when a schema codec or Effect encoding channel can own the boundary.
- Do not ignore cleanup. Every subscription, callback, poller, reader, and spawned stream consumer needs scoped lifetime or an `ensuring` finalizer.
