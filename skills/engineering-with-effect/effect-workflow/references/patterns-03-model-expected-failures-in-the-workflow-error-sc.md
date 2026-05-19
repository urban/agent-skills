# Effect Workflow patterns for agents — part 3

Covers:

- Model expected failures in the workflow error schema
- Understand poll and result semantics
- Use suspension and compensation intentionally
- Testing patterns
- Test through public workflow APIs
- Additional workflow patterns
- What to avoid

---

### Model expected failures in the workflow error schema

The Effect tests use simple string errors for minimal examples. In this project, use precise `Schema.TaggedErrorClass` errors for actionable workflow failures.

```ts
import { Effect, Schema } from "effect";
import { Activity, Workflow } from "effect/unstable/workflow";

export class TranscriptionUnavailable extends Schema.TaggedErrorClass<TranscriptionUnavailable>()(
  "TranscriptionUnavailable",
  { message: Schema.String },
) {}

export const TranscriptionWorkflow = Workflow.make({
  name: "TranscriptionWorkflow",
  payload: { recordingId: Schema.String },
  success: Schema.String,
  error: TranscriptionUnavailable,
  idempotencyKey: ({ recordingId }) => recordingId,
});

export const TranscriptionWorkflowLayer = TranscriptionWorkflow.toLayer(
  Effect.fnUntraced(function* ({ recordingId }) {
    return yield* Activity.make({
      name: "TranscribeRecording",
      success: Schema.String,
      error: TranscriptionUnavailable,
      execute: Effect.gen(function* () {
        if (recordingId.trim() === "") {
          return yield* new TranscriptionUnavailable({
            message: "recording id must not be empty",
          });
        }

        return "transcript text";
      }),
    });
  }),
);
```

Guidelines:

- Put expected business failures in `Workflow.make({ error })` and `Activity.make({ error })`.
- Return tagged errors with `return yield* new MyError(...)` from generators.
- Use `Activity.retry(...)` for retryable typed failures.
- Let non-actionable defects die or convert them to defects at the service boundary before they enter workflow APIs.
- Do not erase errors with `unknown`; callers should be able to pattern match on `_tag`.

### Understand `poll` and result semantics

- `execute(payload)` waits for completion and returns the success value or fails with the workflow error.
- `execute(payload, { discard: true })` starts execution and returns the deterministic execution id.
- `poll(executionId)` returns `Option.none()` when no complete result is available.
- A completed workflow is returned as `Workflow.Complete({ exit })`; inspect `Exit.isSuccess` or `Exit.isFailure`.
- Suspended workflows may resume through a deferred completion, durable clock, explicit `resume`, or suspended retry polling depending on engine configuration.

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Exit, Layer, Option, Schema } from "effect";
import { Workflow, WorkflowEngine } from "effect/unstable/workflow";

const IncrementWorkflow = Workflow.make({
  name: "WorkflowEngine/IncrementWorkflow",
  payload: { value: Schema.Number },
  success: Schema.Number,
  idempotencyKey: ({ value }) => String(value),
});

const IncrementWorkflowLayer = IncrementWorkflow.toLayer(({ value }) => Effect.succeed(value + 1));

it.effect("starts, executes, and polls", () =>
  Effect.gen(function* () {
    const executionId = yield* IncrementWorkflow.execute({ value: 1 }, { discard: true });
    const result = yield* IncrementWorkflow.execute({ value: 1 });
    const polled = yield* IncrementWorkflow.poll(executionId);

    assert.strictEqual(result, 2);
    assert(Option.isSome(polled));
    assert(polled.value._tag === "Complete");
    assert(Exit.isSuccess(polled.value.exit));
    assert.strictEqual(polled.value.exit.value, 2);
  }).pipe(
    Effect.provide(IncrementWorkflowLayer.pipe(Layer.provideMerge(WorkflowEngine.layerMemory))),
  ),
);
```

### Use suspension and compensation intentionally

- `Workflow.SuspendOnFailure` marks a workflow as suspended when any failure occurs, allowing manual inspection and `resume`.
- `Workflow.CaptureDefects` defaults to true, so defects may be encoded into results. In project code, actionable failures should still be tagged errors, not defects.
- Normal finalizers run when the workflow scope closes. In Effect's cluster tests, ordinary finalizers run on suspension, while compensation does not run merely because the workflow suspended.
- Compensation runs on workflow failure after the compensated top-level effect succeeded.
- Use `Cause.pretty(...)` when turning causes into visible text.

## Testing patterns

### Test through public workflow APIs

Prefer executing the workflow and polling its result over reaching into engine internals. Use lower-level storage assertions only when testing engine implementation, replay, deduplication, or persistence.

```ts
import { assert, it } from "@effect/vitest";
import { Cause, Effect, Exit, Layer, Option, Schema } from "effect";
import { TestClock } from "effect/testing";
import { PersistedQueue } from "effect/unstable/persistence";
import { DurableQueue, Workflow, WorkflowEngine } from "effect/unstable/workflow";

const pollUntilComplete = <A, E, R>(
  poll: Effect.Effect<Option.Option<Workflow.Result<A, E>>, never, R>,
) =>
  Effect.gen(function* () {
    let polled = yield* poll;
    for (let i = 0; i < 10 && (Option.isNone(polled) || polled.value._tag !== "Complete"); i += 1) {
      yield* Effect.yieldNow;
      yield* TestClock.adjust("10 millis");
      polled = yield* poll;
    }
    return polled;
  });

it.effect("propagates worker failures to the workflow", () =>
  Effect.gen(function* () {
    const executionId = yield* FailureWorkflow.execute({ id: "failure" }, { discard: true });
    const polled = yield* pollUntilComplete(FailureWorkflow.poll(executionId));

    assert(Option.isSome(polled));
    assert(polled.value._tag === "Complete");
    assert(Exit.isFailure(polled.value.exit));

    const failure = polled.value.exit.cause.reasons.find(Cause.isFailReason);
    assert.strictEqual(failure?.error, "boom");
  }).pipe(
    Effect.provide(
      FailureLayer.pipe(
        Layer.provideMerge(WorkflowEngine.layerMemory),
        Layer.provideMerge(
          PersistedQueue.layer.pipe(Layer.provideMerge(PersistedQueue.layerStoreMemory)),
        ),
      ),
    ),
  ),
);
```

Guidelines:

- Use `WorkflowEngine.layerMemory` for unit and integration tests that do not need cluster durability.
- Use `TestClock.adjust(...)` for time-dependent workflow tests.
- Provide worker and queue layers in the same test composition when using `DurableQueue`.
- Keep tests deterministic. Avoid arbitrary wall-clock sleeps unless the test drives a true external deployment.
- For external deployments, use a fixture pattern: deploy a fixture once, expose start/status routes, and poll until a terminal status.

## Additional workflow patterns

- Use a two-phase shape: the outer effect resolves shared dependencies and the returned function is the workflow body. Resolve services in the layer and keep the body focused on durable steps.
- Named workflow steps should preserve the surrounding Effect context. Yield services from context and preserve requirements through activities instead of passing service instances as parameters.
- Prefer service-provided runtime context over callback parameters.
- Route operations through private helpers, map dependency errors at the boundary, and return safe domain defaults. Use workflow engine tests only where the workflow behavior itself is under test.

## What to avoid

- Do not put business logic, protocol parsing, HTTP clients, filesystem work, or vendor SDK calls directly in workflow orchestration code. Put them behind services and activities.
- Do not use non-deterministic idempotency keys.
- Do not generate activity, deferred, queue, or clock names from timestamps, random ids, or mutable counters.
- Do not use plain `Effect.sleep` for long durable waits. Use `DurableClock.sleep`.
- Do not coordinate suspended workflows with in-memory `Deferred`, `Queue`, or mutable module state. Use `DurableDeferred` or `DurableQueue`.
- Do not expose generic errors such as `WorkflowFailed`, `UnknownError`, or raw defects for actionable failures.
- Do not use `Effect.orDie` to hide expected workflow or activity failures.
- Do not duplicate workflow payload and result schemas in HTTP/RPC layers when `WorkflowProxy` can derive them.
- Do not call engine internals or engine-specific storage from application code.
- Do not assume `execute(..., { discard: true })` returns the result; it returns the execution id.
- Do not rely on nested activity compensation. Register compensation around top-level effects only.
- Do not write tests that depend on wall-clock races. Use `TestClock` or poll deterministic public APIs.
