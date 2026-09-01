---
name: effect-stream
description: Design Effect Stream sources and protocols with explicit ownership, backpressure, buffering, framing, recovery, interruption, and bounded verification. Use when adapting callbacks, readers, subscriptions, sockets, processes, NDJSON, SSE, or long-lived event flows.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Inspect installed Stream, Queue, PubSub, Sink, Channel, scheduling, and framing support before building a custom buffer, subscription loop, or stream protocol; custom machinery needs a named backpressure, delivery, framing, portability, or performance gap.
- Expose a domain stream when callers need values over time; keep producer handles private unless callers truly own their lifecycle.
- Separate source adaptation, framing/decoding, domain transformation, recovery, and terminal consumption.
- Choose buffering and concurrency from producer/consumer behavior and ordering requirements.
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
- retry/repeat policy and deterministic bounded tests

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
- Adapt push APIs with an explicit buffer and finalizer. Decide whether overflow suspends, drops, slides, or fails based on the protocol.
- Decode bytes to text before line or event framing, then schema-decode frames before domain transforms.
- Keep expected source and decode failures typed. Encode failures into protocol frames only when a remote consumer must observe them as data.
- Distinguish retry after failure from repeat after successful completion; both may recreate effects and duplicate output.
- Test long-lived streams by bounded consumption and explicit coordination, then interrupt the scope and assert cleanup.

## Gotchas

- A custom queue, framing loop, or subscription manager can recreate Stream semantics with weaker interruption and cleanup; identify what the installed primitives cannot express before owning it.
- Exposing a Queue or socket instead of a stream makes every caller responsible for backpressure and shutdown.
- Assuming each chunk is a complete UTF-8 string or JSON value fails on split code points and partial frames.
- An unbounded or poorly chosen callback buffer moves overload from backpressure into memory growth or silent loss.
- Retrying a source that already emitted values can duplicate them; require sequence, deduplication, or at-least-once semantics.
- Running a sink inside a reusable transformation makes composition eager and hides terminal ownership.
- Testing with collection alone can hang forever and never prove finalizers; bound, coordinate, and interrupt explicitly.

## References

- [`references/source-adapters.md`](./references/source-adapters.md): Read when: adapting callback, subscription, Web, Node, process, or queue sources and deciding cleanup/buffering.
- [`references/framing-and-recovery.md`](./references/framing-and-recovery.md): Read when: decoding line/NDJSON/SSE protocols, preserving remote failures, retrying, or repeating.
- [`references/stream-testing.md`](./references/stream-testing.md): Read when: designing bounded tests for timing, concurrency, backpressure, or cleanup.
