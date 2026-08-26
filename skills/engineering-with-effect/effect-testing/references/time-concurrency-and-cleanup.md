# Time, concurrency, and cleanup

A deterministic time test needs a readiness point. Fork the operation, yield or await a latch until it has reached sleep/timeout/retry, then advance logical time and join the fiber.

Use Deferred for one-shot readiness/completion, Queue for ordered coordination, Ref for observed state, and scoped fibers for work that must stop with the test.

Assert concurrency contracts such as deduplicated refresh, shared acquisition, bounded parallelism, ordering, cancellation, and all callers seeing the same result. Avoid asserting scheduler accident.

For resources and streams, test finalizers after normal completion, typed failure, and interruption when those paths differ.
