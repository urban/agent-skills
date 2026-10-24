# Effectful and stateful properties

## Property outcomes and ownership

Use `it.effect.prop` from `@effect/vitest` when the predicate needs services, typed errors, TestClock, fibers, queues, streams, or scoped resources. Schemas and native `Arbitrary` values can be mixed in tuple or keyed inputs. A successful Effect passes unless its value is `false`; typed failures, thrown exceptions, and assertion defects falsify the property and shrink. Interruption still interrupts the test.

Expected rejection must therefore be observed as a result and asserted, not left as an unhandled Effect failure. Generate a deliberate invalid class, invoke the public boundary, and compare the caller-visible error reason. Catching every cause and treating it as expected rejection hides defects and interruption; inspect typed failures without swallowing unrelated causes.

Direct `Arbitrary.checkEffect` has a different reporting boundary: ordinary outcomes are returned as data, so merely yielding it does not assert that the law passed. Inspect the result or use `Arbitrary.formatCheckFailure` in a runner integration. Unlike the Vitest adapter, the direct checker propagates defects rather than converting them into shrinkable property failures.

Every evaluation must start from an independent fixture, including evaluations of shrink candidates. Allocate the model and mutable service inside the property Effect; scope acquisitions there so cleanup belongs to that evaluation, not the whole run. A fixture created outside the callback, or a shared `it.layer` service, may retain earlier commands and make the same input produce a different result. Direct `Arbitrary.checkEffect` inherits services and scope; it does not rebuild layers or reset mutable state for you.

Generated inputs are not cloned. Copy a generated array before testing an in-place algorithm; never mutate the runner's input or let a model consume it destructively.

## Model-based laws

Represent a command sequence as data, for example an `Arbitrary.array(commandArbitrary)`, and interpret it against both the real service and a simpler model. The test owns command interpretation, validity, and observations.

For an inventory reservation service, a model can track only available units and reservation IDs mapped to quantities, while the implementation manages storage and concurrency. Useful observations include:

- reserving an allowed quantity reduces availability by that quantity;
- releasing a known reservation restores it exactly once;
- dispatching a reservation removes it without restoring availability;
- rejected transitions leave stock and reservations unchanged.

Choose one contract per property and compare at each transition so the failure identifies the first divergence. Keep the model simpler than the implementation rather than reproducing its persistence algorithm.

Shrinking can delete the reservation-creating command before a release or dispatch. Decide what such a sequence means: test the public unknown-ID rejection, or construct legal dependent sequences and preserve their dependencies while shrinking. Do not silently skip commands that became invalid and claim the intended transition was tested. An empty command sequence can be a legitimate base case; separately exercise transitions that must be reached.

## Determinism and replay

Replace network, process, provider, random side channels, and wall-clock capabilities. Generate business randomness as property input when possible. For time-sensitive laws, use `TestClock` from `effect/testing`: start the waiting work in a fiber, advance test time, then observe its outcome. Test services do not make external I/O or native timers deterministic.

A focused expensive property can use options such as `{ arbitrary: { runs: 30, seed: "reservation-law" } }`. Bound command lengths for domain or cost reasons, and retain targeted examples for costly boundaries. `size` is a local complexity scale, not a global cap on the whole object or sequence graph; prefer explicit collection bounds when cost depends on length.

The failure report contains the shrunk input and a replay token. Reuse it through `{ arbitrary: { replay: token } }`; replay controls the recorded attempt and shrink path and overrides ordinary generation options. Preserve a concrete regression example as well: replay compatibility is not guaranteed across releases of the unstable module, and replay does not capture external fixtures or schedules.

An `Exhausted` result means too many candidates were discarded, not that the law passed. Fix the generator or its domain assumptions before increasing discard limits. A `ReplayMismatch` means the recorded failure no longer reproduces; it is not a successful property run.

To test concurrent service behavior, model concurrent operations and their allowed observations explicitly inside each isolated evaluation. Generate the scenario, then coordinate its fibers so the relevant operations overlap; sampling more command sequences does not itself exercise a race.

Source anchors: `packages/effect/src/Arbitrary.ts` (`checkEffect`, `CheckOptions`, `Replay`), `packages/effect/src/internal/arbitrary/runner.ts` (`checkEffect`, `evaluateProperty`), `packages/vitest/src/internal/internal.ts` (`normalizeProperty`, `runCheck`, `makeTester`), and `packages/effect/src/testing/TestClock.ts`. Failure shrinking, interruption, and timeout cleanup are tested in `packages/vitest/test/index.test.ts`; checking and replay are tested in `packages/effect/test/arbitrary/Arbitrary.test.ts`.
