# Testing XState v6 with Effect and Effect Atom

Test each boundary at the level that owns the behavior.

## Pure machine tests

Use `initialTransition` and `transition` without starting an actor or constructing Effect services.

Assert:

- legal state changes
- ignored or guarded events
- state-specific context
- emitted command payloads
- terminal output
- initial effects

```ts
it("requests submission and enters Submitting", () => {
  const [draft] = initialTransition(orderMachine);
  const [submitting, effects] = transition(orderMachine, draft, {
    type: "submit",
    orderId: "o-1",
  });

  expect(submitting.matches("Submitting")).toBe(true);
  expect(effects).toContainEqual(
    expect.objectContaining({
      kind: "emit",
      type: "submitOrder",
      event: { type: "submitOrder", orderId: "o-1" },
    }),
  );
});
```

Do not execute the emitted command in this test. The machine test protects the “when/what” contract.

Add table or property tests when the machine has an important state/event matrix. Assert that forbidden events do not reach illegal states rather than testing XState's internal node representation.

## Command handler tests

Test each emitted command against Effect service Layers without involving XState.

Assert:

- success event construction
- each actionable tagged failure event
- defect policy
- interruption cleanup
- idempotency/correlation data

Use `@effect/vitest` and return an Effect from `it.effect`. Replace external boundaries with test Layers. Do not call `Effect.runPromise` inside the Effect test.

## Interpreter tests

Exercise the public machine service with test command Layers:

1. send a validated event
2. observe the committed intermediate snapshot
3. complete or fail a test service operation deterministically
4. observe the result snapshot
5. assert fibers/listeners are cancelled on state exit or service release

Use:

- `TestClock` for timer commands, retry delays, and timeouts
- `Deferred` for deterministic control of in-flight commands
- `Queue` for scripted events
- scoped test fibers
- `Ref` for call recording where behavior cannot be observed publicly

Never use wall-clock sleeps.

### Serialization and reentrancy

Include a regression test where a command immediately feeds a result event back to the machine. The event must enter the mailbox after the current transition rather than recursively invoking `transition`.

Include a concurrency test that sends multiple events and verifies the service serializes them against successive snapshots.

### Unsupported executable effects

A constrained emitted-command interpreter should have a test proving unsupported kinds fail. This prevents a later `after`, `invoke`, `enq.raise`, or `enq(fn)` from being silently ignored.

### Cancellation

For each long-running command:

- hold the command with a `Deferred`
- send its cancellation or state-exit event
- assert the fiber is interrupted/finalized
- complete the old `Deferred`
- assert no stale success event changes the snapshot

### Terminal behavior

Assert:

- terminal snapshot publication order
- later sends fail with `MachineStopped`
- snapshot stream completion policy
- all child fibers and timers are interrupted

## XState-owned async actor tests

When using `createAsyncLogic` plus `ManagedRuntime`:

- test the Effect program separately with test Layers
- test machine `onDone` exhaustively for every tagged output variant
- test `onError` only for the chosen defect/infrastructure policy
- test that stopping/leaving the invocation interrupts the Effect fiber through the AbortSignal
- dispose the shared runtime after the suite or fixture

Do not mock `ManagedRuntime.runPromise` and consider the integration proven. At least one test should cross the real XState-to-Effect boundary with a test Layer.

## Persistence tests

Round-trip encoded snapshots through JSON and restore them. Cover:

- machine version acceptance/rejection
- state-specific context encoding
- v5 snapshot rejection or migration
- pending command/outbox recovery
- idempotent replay
- timer due-date policy

Do not test only `JSON.stringify` success. Prove the restored service accepts a next event and produces the expected transition.

## Effect Atom tests

Test through `AtomRegistry.make()` or `RegistryProvider`; do not mock atom definitions.

Assert:

- initial runtime/stream lifecycle
- successful snapshot projection
- failure cause when the machine service cannot start
- dispatch through the effectful atom
- state-specific rendering after updates
- family isolation between machine IDs
- unsubscribe/disposal behavior when relevant

A stream-backed snapshot atom yields `AsyncResult`; assert `Initial`, `Success`, `Failure`, and `waiting` rather than flattening them to defaults.

For React, render one user path through the real RegistryProvider with a test machine Layer. Keep component tests focused on rendering and dispatch; machine legality belongs in pure tests, and command implementation belongs in Effect tests.

## Recommended test split

| Test | XState runtime | Effect services | Atom/React |
| --- | --- | --- | --- |
| pure transition | no | no | no |
| command handler | no | test Layer | no |
| Effect-owned interpreter | pure transition API | test Layer | no |
| XState-owned async bridge | actor | test Layer through runtime | no |
| Atom projection | chosen machine service | test Layer | AtomRegistry |
| user path | chosen machine service | test Layer | RegistryProvider + React |

This split keeps failures diagnostic: behavior-map failures point to the machine, execution failures point to Effect handlers, and rendering failures point to Atom/React integration.
