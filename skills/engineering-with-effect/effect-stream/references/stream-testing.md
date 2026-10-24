# Stream testing

## Lifetime and demand

- Bound long-lived consumption with a count, condition, or finite sink. A count bound still waits forever if too few values arrive; give absence/liveness tests an explicit timeout failure policy rather than treating timeout as successful completion.
- Coordinate producer registration and consumer readiness with Deferred, Latch, or Queue rather than sleeps. TestClock controls Effect scheduling, not native event-loop callbacks or arbitrary Promises.
- Exercise normal completion, source failure, early `take`, and interruption. Assert unregistration/release exactly once, including interruption while a pull or offer is blocked. Returning from callback registration alone must not count as completion.
- Check per-subscription acquisition by consuming twice. For shared fan-out, test subscriber removal independently of producer shutdown and make slow-subscriber delivery behavior observable.
- For an abortable external source, assert its actual abort/cancel hook. A finalized Effect fiber alone does not prove a pending async iterator or native operation has stopped.

## Backpressure and concurrency

- Gate consumer progress, fill a small buffer, and assert whether the next offer suspends or is rejected. For dropping/sliding, inspect which values survive, not just how many. Distinguish an awaited offer from a synchronous callback's rejected offer.
- Measure upstream work separately from downstream values: buffering and concurrency may perform work beyond the consumer's final `take`.
- Hold the first mapped task while later tasks finish. Ordered mapping must delay their delivery; unordered mapping may deliver them. Separately record external side-effect order rather than inferring it from output order.
- Assert the maximum simultaneous tasks, and verify an inner failure or consumer interruption cancels remaining work and runs its finalizers.
- Use TestClock for debounce, throttle, retry, repeat, time-window grouping, and scheduled polling, with readiness coordination before advancing time.

## Framing and recovery

- Feed the same finite payload under adversarial byte/text partitions, including split UTF-8, split CRLF, many frames per chunk, and empty chunks. Valid output must not depend on transport partitions.
- For NDJSON, test valid records before a malformed line in the same chunk, invalid UTF-8, oversized unterminated lines, BOM handling, and final lines without terminators. Observe emitted records and terminal failure separately: a failed `runCollect` does not return the valid prefix.
- For SSE, test multiline data, inherited/reset IDs, blank-line dispatch, no dispatch of incomplete final events, pending-size overflow, and `retry:` control failures separately from domain events.
- For per-record rejection, place a valid record after a malformed one and assert it is processed. A fallback emitted by a stream-level catch does not prove resumption.
- Test cleanup before reacquisition on reconnect. If duplicates are possible, assert sequence/deduplication and acknowledgement behavior explicitly. Include a source that emits before every failure to distinguish reset-on-progress retry from a total reconnect budget.
