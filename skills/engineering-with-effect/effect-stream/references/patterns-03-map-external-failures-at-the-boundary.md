# Effect `Stream` patterns for agents — part 3

Covers:

- Map external failures at the boundary
- Recover only from expected typed errors
- Preserve remote stream failures explicitly
- Encoding and protocol boundaries
- Constructor and operator choices
- What to avoid

---

### Map external failures at the boundary

Convert platform, process, socket, parser, HTTP, and vendor failures into precise tagged errors as close to the boundary as possible.

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

When a stream crosses RPC, HTTP, worker, or WebSocket boundaries, encode stream failures as protocol frames and decode them back into the error channel. Use `Stream.catchCause` to append an error marker and `Stream.flatMap` to turn remote error markers back into `Stream.fail`.

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
