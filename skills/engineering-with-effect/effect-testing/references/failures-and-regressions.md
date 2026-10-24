# Failures and regressions

Assert expected errors through the public error/result/exit contract. Check tag/reason and fields that callers use. `Effect.result` exposes typed success/failure but is not full termination evidence: a typed failure mixed with interruption can be captured with the interruption discarded. Use `Effect.exit` when defects, interruption, or mixed causes matter.

A failed exit alone does not prove the expected rejection: an assertion defect or interruption also fails. Check the intended failure classification and payload. For cancellation, inspect interruption reasons without pinning incidental fiber IDs. When cleanup must succeed, an interruption reason is insufficient if the same Cause also contains a finalizer defect; assert that no unexpected reasons remain. Prefer semantic Cause assertions over snapshots of stack traces or rendered diagnostics.

A regression test should:

1. name the caller-visible failure;
2. reproduce it through the nearest public composition;
3. replace only external/nondeterministic edges;
4. assert the stable outcome that was broken;
5. avoid pinning incidental internal sequencing.

Exact invocation assertions are appropriate for protocol contracts: HTTP method/path/body, CLI arguments, serialized payload, idempotency keys, approval prompts, or required cleanup calls. A call count alone is weak regression evidence when the caller's returned value or persisted outcome could still be wrong.

Exercise the path that distinguishes the fix from the old behavior: a retry test needs the transient failure before recovery; a deduplication test needs overlapping callers; a cleanup test needs completed acquisition before cancellation. Avoid wrapping the entire test in retries to hide a missing coordination point—retry behavior belongs to the operation under test, not the evidence collector.

Source anchors (Effect v4): `packages/effect/src/Effect.ts` (`result`, `exit`), `packages/effect/src/Cause.ts` (`hasInterrupts`, `hasInterruptsOnly`), `packages/effect/test/Exit.test.ts`, `packages/vitest/test/timeout.test.ts` (finalizer-defect reporting).
