# Framing and recovery

## Incremental protocol boundaries

Keep transport adaptation, framing, schema decoding, and domain transformation distinct. Framing and decoder state belong to each subscription, not a shared mutable parser. Multiple messages may arrive in one transport chunk, and a message or UTF-8 code point may span many chunks.

For general text, `Stream.decodeText` keeps decoder state and flushes on normal completion, replacing malformed UTF-8. Dropping down to `Channel.decodeText` with `{ fatal: true }` makes decoding throw a defect, not a typed protocol error. Neither is a strict typed UTF-8 validator.

### NDJSON

Use `effect/encoding/Ndjson` byte channels directly when bytes are available. They reject invalid UTF-8 with a typed `NdjsonError` and accept LF, CRLF, bare CR, and a leading BOM. The byte decoder's `maxLineBytes` bounds a pending line before reading the remainder; it is unbounded by default. A bounded transport queue alone does not bound an unterminated record.

```ts
import { Stream } from "effect"
import * as Ndjson from "effect/encoding/Ndjson"
import * as Schema from "effect/Schema"

const messages = Stream.make(
  new Uint8Array([0x22, 0xc3]),
  new Uint8Array([0xa9, 0x22, 0x0a])
).pipe(
  Stream.pipeThroughChannel(
    Ndjson.decodeSchema(Schema.String)({ maxLineBytes: 4096 })
  )
)
// Emits "é" even though its UTF-8 bytes cross transport chunks.
```

The decoder emits valid JSON records preceding the first malformed line, then fails. It also parses a nonempty unterminated final line on normal completion; `NdjsonError.unterminated` identifies a rejected final line. Transport failure is not normal EOF and does not flush pending records. Decide whether your protocol accepts final records without a terminator rather than assuming every EOF is a clean message boundary.

### SSE

Decode bytes to text, then use `effect/encoding/Sse` channels. Line splitting alone loses blank-line dispatch, multiline `data`, inherited IDs, and control directives. Pending events without a blank-line terminator are not dispatched at EOF.

`Sse.decode` consumes text and bounds pending state with `maxEventSize` (string code units, default 10 MiB). Set an appropriate domain limit. Empty named events are dropped by default; enable `dispatchEmptyNamedEvents` only when the protocol uses them as signals.

A valid `retry:` directive becomes a typed `Sse.Retry` failure carrying a duration and last event ID, not an ordinary event or an automatic reconnect. The connection owner must interpret it and preserve resume state. For JSON event payloads, `Sse.decodeDataSchema` decodes the `data` field while retaining the event name and ID.

## Recovery granularity

Source/transport failures stay in the stream error channel. Decode failures should remain distinguishable from transport failures; malformed data usually needs rejection or termination, not a reconnect loop.

A stream-level `Stream.catch` switches to a replacement stream after failure. It does not resume the failed decoder or the original tail. Likewise, `Stream.result` emits one failure result and then ends; it is not per-record error isolation.

When the domain permits rejecting individual records, first establish recoverable record boundaries, then decode each record into a success/failure value. For example, after bounded line framing:

```ts
import { Effect, Schema, Stream } from "effect"

const decodeRecord = Schema.decodeUnknownEffect(
  Schema.fromJsonString(Schema.Struct({ sequence: Schema.Number }))
)

const records = Stream.make('{"sequence":1}', 'bad', '{"sequence":2}').pipe(
  Stream.mapEffect((line) => decodeRecord(line).pipe(Effect.result))
)
// Success, failure, success: the bad record does not terminate consumption.
```

This deliberately does not use the fail-fast NDJSON channel. Raw `Stream.splitLines` does not impose a size limit; enforce a framing limit for untrusted input. Keep transport errors terminal rather than turning a broken connection into an endless stream of rejected records.

Encode a local failure into an ordinary protocol frame only when the wire contract defines such a frame. Conversely, turn remote error frames back into local failures when the consumer API promises failure semantics; a named SSE event is not inherently an error.

## Retry and repeat

Retry reruns the wrapped source after typed failure; repeat reruns it after normal completion. Attempt scopes close before restart, but neither operator can recreate a resource acquired outside the restarted region or infer a resume position.

After partial output, require offsets, sequence IDs, resume tokens, deduplication, or explicit at-least-once acceptance. Persist the resume position at the domain's acknowledgement boundary, outside per-attempt setup; receiving an event is not necessarily committing its effects.

`Stream.retry` resets its schedule after output is emitted. A source that repeatedly emits one value then fails can therefore keep reconnecting despite a finite retry schedule. If a lifetime reconnect budget is required, own it separately from this reset-on-progress policy.
