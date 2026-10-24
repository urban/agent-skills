# Retry, lifecycle, and tests

## Retry and uncertain outcomes

Classify retryability from documented provider codes, status, and retry hints, not every rejected Promise or a message substring. Unknown failures should not default to transient. Honor retry hints within an overall latency budget; bound backoff and total attempts. `Effect.retry` reruns typed failures under its policy; `Schedule.recurs(3)` permits three retries after the initial attempt, not three total calls.

Choose one retry owner or account explicitly for SDK-internal retries; nested SDK, adapter, and domain retries multiply requests and latency. Apply a retry around the individual safe operation, not a larger program that also performs unrelated side effects.

For mutations, create or accept the provider idempotency key at the logical-operation boundary and reuse it across attempts with the same payload. A new key per attempt defeats deduplication. Respect provider retention windows and operation coverage; a key is not a universal exactly-once guarantee. Timeout, cancellation, or a lost response can leave a committed mutation with no acknowledgement. Without a deduplication guarantee, reconcile via provider lookup or surface an uncertain outcome rather than blindly resending.

## Lifetime belongs to the owner

Construct an owned SDK in `Layer.effect(Service, acquisition)` and use `Effect.acquireRelease` inside that acquisition when close, flush, or shutdown is required. In Effect v4, `Layer.effect` runs acquisition in the layer's scope, which owns release; do not wrap acquisition in an inner `Effect.scoped` that closes before consumers use the returned service. Share the same layer value within a composition when callers should share one client; repeatedly creating layer values can create distinct clients.

A wrapper given an externally managed client borrows it. It can expose the same narrow capability without registering shutdown. Do not invent cleanup for a resource-free SDK, or close a shared client after each request. Coordinate in-flight operations with shutdown, especially when the SDK ignores cancellation and work can outlive the requesting fiber.

`Effect.acquireRelease` protects acquisition from interruption by default and registers release only after success. Do not put an indefinitely pending connection attempt there without considering shutdown behavior. `{ interruptible: true }` allows cancellable acquisition, but requires the acquisition itself to clean up partial allocations: release cannot clean up a handle that was never returned.

Scope finalizers have no typed failure channel. Translate a fallible close/flush into an explicit policy: handle a sanitized failure with reporting if loss is acceptable, or turn it into a defect when shutdown must fail. A finalizer defect contributes to the scope-closing failure, combined with an existing use failure; it is not a normal request error. If callers must recover from a flush failure, expose an explicit typed flush operation while the service is alive rather than relying only on shutdown. Finalizers run uninterruptibly, so bound provider shutdown work where possible; a hung flush can otherwise stall scope closure.

## Telemetry boundaries

Add a span when one SDK operation is an operator-useful boundary; do not duplicate automatic SDK instrumentation or existing domain spans without purpose. Use stable names and low-cardinality attributes. Decide whether a span represents the logical operation or each retry attempt. Do not include credentials, payloads, recipient data, or unbounded provider messages by default, including through error causes.

## Adapter-focused test design

Test domain consumers with a narrow service fake. Test the adapter separately with a scripted SDK so translation and ownership cannot be bypassed by that fake. Useful cases include:

- synchronous invocation throw and asynchronous rejection map to the intended safe errors; unknown and malformed failures do not break the mapper;
- response projection/decoding preserves domain meaning and does not turn transport or authorization errors into absence;
- one logical invocation creates a fresh SDK call per retry, stops at the expected total call count, and never retries permanent or unsafe failures;
- mutation attempts keep the same key and payload; ambiguous outcomes follow the reconciliation policy, with SDK-internal attempts included in the budget;
- interruption after the SDK signals request start aborts the forwarded signal or invokes the cancellation handle; an SDK that ignores cancellation can still complete remotely;
- an owned client stays open while the service is used and closes once when its scope ends, including interruption; a borrowed client is never closed;
- partial acquisition and close/flush failures follow the chosen policy, including the case where use and release both fail;
- captured errors, logs, and spans omit a sentinel secret even when the SDK embeds it in the rejection payload.

Synchronize interruption tests on an explicit request-start latch or callback rather than sleeping. A fake that merely notices fiber interruption does not prove the signal reached the SDK; capture it at the scripted SDK boundary.
