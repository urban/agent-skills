---
name: effect-stream
description: Design Effect Stream sources and protocols with explicit ownership, backpressure, buffering, framing, concurrency, recovery, and interruption. Use when adapting callbacks, readers, subscriptions, sockets, processes, NDJSON, SSE, or long-lived event flows.
---

## Rules

- Prefer Stream/Channel adapters and protocol decoders over custom loops; own custom machinery only for a concrete delivery, framing, portability, or performance gap.
- Expose a domain stream when callers need values over time; keep producer handles private unless callers truly own their lifecycle.
- Separate source adaptation, framing/decoding, domain transformation, recovery, and terminal consumption.
- Choose buffering and concurrency from producer/consumer behavior, loss tolerance, and ordering requirements; ordered output does not serialize concurrent side effects.
- Recover at the boundary that can actually continue: individual records for rejectable data, whole subscriptions for reconnectable transport failures.
- Make acquisition, interruption, completion, and cleanup part of the stream contract.

## Constraints

- Never collect an unbounded stream without a prior semantic bound.
- Retry or repeat only when rebuilding the source is safe and duplicate delivery is understood.
- Protocol framing must tolerate chunk boundaries; individual transport chunks are not messages.

## Knowledge Boundaries

Applies to:

- choosing stream constructors and source ownership
- callback adaptation, buffering, backpressure, and cleanup
- text, line, NDJSON, SSE, and remote failure framing
- concurrency ordering, recovery granularity, and deterministic bounded tests

Does not cover:

- generic service or schema style rules
- HTTP status semantics outside a streaming body

Decision inputs:

- pull versus push source and producer cancellation capability
- ordering, fan-out, loss, and buffer-overflow policy
- message framing and schema trust boundary
- completion, reconnection, and terminal sink ownership

## Patterns

- Use per-subscription setup when each subscriber needs its own resource, snapshot, or registration. Share only when fan-out is a deliberate service semantic.
- Adapt push APIs with an explicit buffer and finalizer. Suspending an offer only backpressures a producer that waits for it; synchronous callbacks need an explicit rejection, loss, or pause policy.
- Keep incremental decoding/framing state per subscription. Prefer byte-aware NDJSON decoding for strict UTF-8 and line-byte limits; decode SSE bytes to text before event framing.
- Keep expected source and decode failures typed. Encode failures into protocol frames only when a remote consumer must observe them as data.
- Distinguish retry after failure from repeat after successful completion; both rerun the wrapped source rather than resume it. Keep resume state outside that restarted region.
- Test long-lived streams by bounded consumption and explicit coordination, then interrupt the scope and assert cleanup.

## Gotchas

- Exposing a Queue or socket instead of a stream makes every caller responsible for backpressure and shutdown.
- Assuming each chunk is a complete UTF-8 string or JSON value fails on split code points and partial frames.
- `Stream.callback` defaults to unbounded buffering, and returning from registration does not end it. Choose a capacity and signal completion explicitly.
- Forking an offer for every synchronous callback does not backpressure the source; it accumulates waiting work outside the queue. Pause the producer or handle rejection/loss explicitly.
- A catch after a failing decoder replaces the failed stream; it cannot skip the bad frame and resume that decoder. Handle rejectable records before their failures terminate the stream.
- Concurrent `mapEffect` can preserve output order while side effects run out of order; use sequential processing for ordered writes.
- Retrying a source that already emitted values can duplicate them; require sequence, deduplication, or at-least-once semantics.
- Running a sink inside a reusable transformation makes composition eager and hides terminal ownership.
- Testing with collection alone can hang forever and never prove finalizers; bound, coordinate, and interrupt explicitly.

## References

- [`references/source-adapters.md`](./references/source-adapters.md): Read when: adapting callback, subscription, Web, Node, process, or queue sources and deciding cleanup, buffering, or concurrency.
- [`references/framing-and-recovery.md`](./references/framing-and-recovery.md): Read when: decoding line/NDJSON/SSE protocols, preserving remote failures, retrying, or repeating.
- [`references/stream-testing.md`](./references/stream-testing.md): Read when: designing bounded tests for timing, concurrency, backpressure, or cleanup.
