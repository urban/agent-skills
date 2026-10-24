# Time, concurrency, and cleanup

## Virtual time is not readiness

`it.effect` provides a fresh scope plus `TestClock` and `TestConsole`; `it.live` provides a fresh scope without those replacements. Use imports such as `import { TestClock } from "effect/testing"`. The test clock controls Effect's clock-dependent operations, not `Date.now()`, native timers, or external I/O. `TestClock.withLive` switches only the clock for a bounded live-time operation, not the whole test environment.

Fork an operation that sleeps before adjusting time; awaiting its sleep in the driving fiber leaves nobody to advance the clock. Under `TestClock.layer()` (also installed by `it.effect`), adjustment yields before advancing, wakes due sleeps in deadline order, and tracks work scheduled by woken fibers across scheduler hops. Simple fork/sleep tests do not need an arbitrary yield-count ritual. Prefer the layer over manually providing a clock from `TestClock.make`, which does not install the tracking scheduler.

Scheduler coordination is not application readiness. A fiber waiting for I/O, a queue item, or a gate may not have reached its timer. Await a semantic milestone such as “first request failed” or “subscriber registered” before advancing. A signal before an intervening asynchronous step does not prove the timer is registered. `Effect.yieldNow` is not evidence that an external operation completed. Busy fibers can exceed the clock's live warning delay, so clock adjustment is not a universal drain-all-work barrier.

For a retry policy, establish the first attempt, advance to just before the retry deadline and assert no second request, then cross the deadline and observe the next attempt and final result. For cancellation, cancel while the operation is known to be in flight and verify that later clock advancement does not restart it. Keep these observations at the boundary; private timer counts do not establish caller behavior.

## Deterministic concurrency

Use Deferred for one-shot readiness/completion, Queue for ordered handoffs, Ref for observed state, and scoped fibers for work owned by the test. Coordinate contenders so they actually overlap:

- **Deduplicated refresh:** hold the first underlying request open, start the other callers, then release it; assert one underlying request and the result for every caller.
- **Bounded parallelism:** block admitted operations, observe the maximum active count and that excess work remains unstarted, then release capacity.
- **Cancellation:** signal after acquisition/registration, interrupt, await termination, and observe release/unsubscription before allowing later work.

A passing sequential invocation test does not demonstrate sharing under contention. Avoid asserting which equally eligible fiber runs first unless that ordering is part of the public contract.

## Cleanup evidence

The runner closes the test scope after the body finishes. To assert release inside the body, close a smaller scope explicitly. For interrupted work, `Fiber.interrupt` waits for termination, including finalizers; then inspect the resource observation and, when relevant, `Fiber.await` for the exit. Interruption is cooperative, so uninterruptible work can delay this completion.

This reduced example demonstrates the ownership boundary and readiness signal. In an application test, exercise the real resource-owning operation and record releases through its external adapter rather than reimplementing the operation:

```ts
import { it } from "@effect/vitest"
import { Cause, Deferred, Effect, Exit, Fiber, Ref } from "effect"

it.effect("cancellation releases the acquired session once", ({ expect }) =>
  Effect.gen(function*() {
    const started = yield* Deferred.make<void>()
    const releases = yield* Ref.make(0)
    const worker = yield* Effect.gen(function*() {
      yield* Effect.acquireRelease(
        Effect.succeed("session"),
        () => Ref.update(releases, (n) => n + 1)
      )
      yield* Deferred.succeed(started, undefined)
      yield* Effect.never
    }).pipe(Effect.scoped, Effect.forkScoped)

    yield* Deferred.await(started)
    expect(yield* Ref.get(releases)).toBe(0)
    yield* Fiber.interrupt(worker)
    const exit = yield* Fiber.await(worker)
    expect(Exit.isFailure(exit) && Cause.hasInterruptsOnly(exit.cause)).toBe(true)
    expect(yield* Ref.get(releases)).toBe(1)
  }))
```

The inner scope owns the session; the test scope owns the worker. Without the inner scope, a resource acquired in the ambient test scope can outlive the interrupted worker, making an immediate release assertion incorrect.

For resources and streams, cover normal completion, typed failure, and interruption when their release paths differ. Assert completed release, not just that release started. A finalizer that sleeps on virtual time still needs a separate driver; the Vitest timeout is a live safety bound, not a clock adjustment. Logs can supply evidence when logging is the contract: inspect `TestConsole` for Effect console output rather than assuming a quiet terminal means the code did not run.

Source anchors: `packages/effect/src/testing/TestClock.ts` (`run`, `wake`, `layer`, `withLive`), `packages/effect/test/TestClock.test.ts`, `packages/effect/src/Fiber.ts` (`interrupt`), `packages/vitest/src/internal/internal.ts` (`TestEnv`, `makeItProxy`, `settleOnAbort`), `packages/vitest/test/timeout.test.ts`, `packages/effect/src/testing/TestConsole.ts`.
