# Identity, activities, and durable primitives

## Identity is a persistence contract

Execution identity is derived from the workflow tag and `idempotencyKey(payload)`, not the entire payload. Reusing the key with changed payload is not an update operation: it addresses the existing execution. Include tenant and operation identity where needed; create a new logical key for a genuinely new run.

Activity result identity includes execution ID, activity name, and `Activity.CurrentAttempt`. Step names must distinguish different items within one execution. Renaming a step can rerun an external effect; retaining its name while incompatibly changing its result schema can break replay decoding. Treat both as stored-protocol changes.

## Replay and retries

Only completed activity outcomes are memoized, including failures. Workflow code outside activities runs again during replay. An activity awaiting a child or durable signal can suspend and rerun its own body too. Split externally visible work from later waits so a completed activity can be replayed without redoing that work.

`Activity.retry` advances `CurrentAttempt`, starting at 1, so each retried activity attempt has a distinct recorded identity. An `Effect.retry` inside the activity can retry the underlying operation before storing a single final outcome, but it does not create separate durable attempt records. The activity's default interruption retry policy is separate from expected business-error retry policy; intentional workflow suspension is not retried as an accidental interruption.

`Activity.idempotencyKey(name)` derives a downstream key from execution ID and name. It excludes the attempt by default. `includeAttempt: true` intentionally creates different external keys across `Activity.retry` attempts; do not use it for a charge that must deduplicate across ambiguous failures. Local attempt counts are not proof that a provider rejected an earlier request.

## Compensation placement

Wrap the activity in workflow-level compensation, not the effect inside `Activity.make.execute`. Registration happens only after success and receives the successful value plus the later workflow failure cause. Compensation is not called merely because the workflow suspends. It cannot repair an effect whose external mutation succeeded but whose success value was never recorded; downstream idempotency and reconciliation still matter.

This handler factory injects domain operations while making retry and compensation ownership visible:

```ts
import { Effect, Schema } from "effect"
import { Activity, Workflow } from "effect/workflow"

const FulfillOrder = Workflow.make("FulfillOrder", {
  payload: { orderId: Schema.String },
  error: Schema.String,
  idempotencyKey: ({ orderId }) => orderId
})

const makeFulfillOrderLayer = (
  charge: (orderId: string, key: string) => Effect.Effect<string, string>,
  refund: (chargeId: string) => Effect.Effect<void>,
  ship: (orderId: string, key: string) => Effect.Effect<void, string>
) => FulfillOrder.toLayer(({ orderId }) => Effect.gen(function*() {
  yield* Activity.make({
    name: "charge",
    success: Schema.String,
    error: Schema.String,
    execute: Effect.flatMap(Activity.idempotencyKey("charge"), (key) => charge(orderId, key))
  }).pipe(
    Activity.retry({ times: 3 }),
    FulfillOrder.withCompensation((chargeId) => refund(chargeId))
  )

  yield* Activity.make({
    name: "ship",
    error: Schema.String,
    execute: Effect.flatMap(Activity.idempotencyKey("ship"), (key) => ship(orderId, key))
  })
}))
```

Here a terminal shipping failure compensates the recorded charge. The injected charge, refund, and shipping operations still need their own deduplication/reconciliation policies; the wrapper is not a transaction across providers.

## Durable coordination choices

- **Clock:** `DurableClock.sleep` ignores zero duration. At or below its default 60-second threshold it uses an in-memory sleep activity; longer sleeps schedule a clock through the engine and await its deferred. Set `inMemoryThreshold: 0` for durably scheduled positive delays rather than promising that every sleep preserves its deadline through restart.
- **Deferred:** an absent result suspends the workflow. External `done`/`succeed`/`fail` records an exit and wakes the execution. Tokens encode workflow name, execution ID, and deferred name as base64url JSON; they are routing identifiers, not signed authorization. Authenticate and authorize approval callbacks independently. Repeated completion does not overwrite the first recorded result.
- **Queue:** `DurableQueue.process` offers an item to a `PersistedQueue` and waits on a result deferred. Its item ID incorporates workflow execution identity, queue name, and queue payload key; it is not global business deduplication across executions. Workers are at-least-once: a crash after handling but before acknowledgement can redeliver. A typed handler failure is delivered back to the workflow as an exit, not automatically retried as queue delivery failure. Exhausted queue delivery attempts dead-letter the item and can leave the workflow parked until out-of-band recovery; replay does not resurrect that item. Own recovery and `PersistedQueue.layerCleanup` at deployment level.

Source anchors (Effect v4): `packages/effect/src/workflow/Workflow.ts` (`makeExecutionIdFromPayload`, `withCompensation`); `Activity.ts` (`make`, `retry`, `idempotencyKey`); `DurableClock.ts` (`sleep`); `DurableDeferred.ts` (`TokenParsed`, `done`); `DurableQueue.ts` (`process`, `makeWorker`). These module filenames are under `packages/effect/src/workflow/`.
