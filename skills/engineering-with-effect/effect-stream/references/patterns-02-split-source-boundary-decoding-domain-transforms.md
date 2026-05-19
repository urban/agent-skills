# Effect `Stream` patterns for agents — part 2

Covers:

- Split source, boundary decoding, domain transforms, and sinks
- Keep sinks at edges
- Make tests consume bounded public streams
- Error handling patterns

---

### Split source, boundary decoding, domain transforms, and sinks

Keep pipeline stages separate:

1. source: `Stream.fromPubSub`, `Stream.callback`, `Stream.fromReadableStream`, `NodeStream.fromReadable`, `response.stream`, process output, or a page API;
2. boundary decoding and schema validation;
3. pure and effectful domain transforms;
4. terminal sink at the application edge.

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

Example pattern:

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

Adapted from Effect stream tests:

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
