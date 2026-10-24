# Source adapters

## Ownership

- Per-subscriber source: acquire inside stream setup; release when that subscription ends. `Stream.unwrap` can acquire a resource with `Effect.acquireRelease` and build the stream that uses it without closing the resource before consumption.
- Shared fan-out source: own producer and subscription lifecycle in a service; expose a domain stream. Sharing changes delivery semantics: specify replay and whether a slow subscriber blocks everyone or loses events.
- Caller-owned handle: expose only when callers genuinely control pause, close, seek, or process lifecycle.

A lazy adapter is not necessarily a fresh source. Returning the same Web reader, iterator, or socket on every run can reuse an exhausted or cancelled resource. Put the resource factory inside setup when reruns must reconnect.

## Push sources

`Stream.callback` supplies a Queue and a registration scope. Register unsubscription with `Effect.addFinalizer` or acquire/release there, not in an outer scope that may end before consumption. Setup failures fail the stream; successful setup returning does not signal completion. Signal the queue's end or failure explicitly.

Choose buffer behavior from delivery requirements:

- Awaiting `Queue.offer` with a bounded `"suspend"` queue backpressures an effectful producer.
- A synchronous callback using `Queue.offerUnsafe` cannot wait: a full non-sliding queue rejects the value with `false`, even under `"suspend"`. Handle rejection or pause the producer; do not fork unlimited waiting offers.
- `"dropping"` rejects new values; `"sliding"` evicts old values to retain recent ones. Neither is suitable for lossless commands or audit events.
- Fail-on-overflow is an adapter policy, not a built-in callback strategy. Convert rejection into an explicit typed queue failure when loss must terminate the subscription.
- Unbounded buffering needs a demonstrated backlog bound; a temporarily fast consumer is not a memory bound.

Account for pending offers, in-flight transformations, and parser state as well as queued values. `Stream.buffer` bounds elements; `Stream.bufferArray` bounds array chunks, so a small chunk count is not a byte-memory bound. Buffering adds prefetch: early downstream termination does not undo upstream side effects already performed.

## External readers

Use the matching Web/Node/process adapters and preserve bytes until protocol decoding. Choose cancellation according to ownership:

- `Stream.fromReadableStream` cancels the reader and releases its lock on scope close by default. `releaseLockOnEnd: true` instead only releases the lock, including on early termination; choose this only when another owner must continue the underlying stream.
- AsyncIterable adaptation calls iterator `return()` when available. Idle cleanup is awaited, but if `next()` is pending, `return()` is requested without waiting. An async generator blocked in `next()` may not run its `finally` yet. Use a source-specific abort mechanism when prompt cancellation matters.

## Concurrency and ordering

- `Stream.mapEffect` is sequential by default. With bounded concurrency it preserves result order unless `unordered: true`; a slow early result can delay delivery of later completed results. Output ordering does not order external writes or commits.
- Concurrent `Stream.flatMap` merges inner-stream output as it arrives; use sequential flattening when one logical record's stream must finish before the next starts.
- `Stream.switchMap` interrupts superseded inner streams. Use it for latest-query/latest-state semantics, not work that must finish for every input.
- A mapping failure terminates the stream and interrupts in-flight work. If failures are independent per record, represent each record's expected failure as a value inside the mapper instead of failing the concurrent stage.

Set concurrency from downstream service capacity and per-task resource cost, not just throughput goals. Already-completed external effects remain completed when siblings fail or the consumer stops.
