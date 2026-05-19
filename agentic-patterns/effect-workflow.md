# Effect Workflow patterns for agents

## First principles

- Treat a workflow as a durable, schema-defined orchestration boundary.
- Define workflows with `Workflow.make({ name, payload, success, error, idempotencyKey })` at module scope.
- Use stable, deterministic idempotency keys derived from the logical payload. Do not use time, random values, counters, or mutable process state.
- Register behavior with `Workflow.toLayer(...)`. Callers should use `execute`, `poll`, `interrupt`, `resume`, or proxy-generated APIs, not the implementation function directly.
- Put durable or replay-sensitive side effects behind named primitives:
  - `Activity.make` for retryable, encoded steps.
  - `DurableDeferred.await` / `done` for external completion.
  - `DurableClock.sleep` for durable waits.
  - `DurableQueue.process` / `DurableQueue.worker` for worker-driven asynchronous work.
- Keep the engine at the infrastructure edge. Use `WorkflowEngine.layerMemory` for local tests and `ClusterWorkflowEngine.layer` when executions must be durable across runners.
- Use `Effect.fnUntraced` for project workflow bodies unless spans are intentionally needed.

## Behavior encapsulation

### Let the workflow orchestrate; let services do domain work

The workflow body should coordinate steps and decisions. It should not become the implementation of email, billing, Git, storage, or HTTP clients. Yield services from context inside the body, then call service methods from activities or durable steps.

```ts
import { Cause, Context, Effect, Layer, Schema } from "effect";
import { Activity, Workflow } from "effect/unstable/workflow";

export class SendEmailError extends Schema.TaggedErrorClass<SendEmailError>()("SendEmailError", {
  message: Schema.String,
}) {}

export interface EmailSenderShape {
  readonly send: (input: {
    readonly id: string;
    readonly to: string;
  }) => Effect.Effect<void, SendEmailError>;
  readonly markCompensated: (id: string, cause: Cause.Cause<SendEmailError>) => Effect.Effect<void>;
}

export class EmailSender extends Context.Service<EmailSender, EmailSenderShape>()(
  "app/email/EmailSender",
) {
  static readonly layer: Layer.Layer<EmailSender> = Layer.succeed(
    EmailSender,
    EmailSender.of({
      send: () => Effect.void,
      markCompensated: () => Effect.void,
    }),
  );
}

export const EmailWorkflow = Workflow.make({
  name: "EmailWorkflow",
  payload: {
    id: Schema.String,
    to: Schema.String,
  },
  error: SendEmailError,
  idempotencyKey: ({ id }) => id,
});

export const EmailWorkflowLayer = EmailWorkflow.toLayer(
  Effect.fnUntraced(function* ({ id, to }) {
    const email = yield* EmailSender;

    yield* Activity.make({
      name: "SendEmail",
      error: SendEmailError,
      execute: email.send({ id, to }),
    }).pipe(
      EmailWorkflow.withCompensation((_, cause) => email.markCompensated(id, cause)),
      Activity.retry({ times: 5 }),
    );
  }),
).pipe(Layer.provide(EmailSender.layer));
```

Guidelines:

- Keep workflow definitions near their domain module, with payload and result schemas beside the workflow.
- Use stable, descriptive step names. Activity identity includes execution id, activity name, and attempt, so names must not be generated from volatile data.
- Make each activity idempotent or safe to retry. Activity results are encoded and replayed by the engine.
- Use compensation for cleanup after a top-level effect succeeds and the workflow later fails.
- Do not expect compensation to work for nested activities. Effect's source explicitly documents that compensation finalizers are only registered for top-level workflow effects.

### Use durable primitives for waits and external completion

```ts
import { DateTime, Duration, Effect, Schema } from "effect";
import { Activity, DurableClock, DurableDeferred, Workflow } from "effect/unstable/workflow";

export const EmailTrigger = DurableDeferred.make("EmailTrigger", {
  success: Schema.String,
});

export const WaitForEmailWorkflow = Workflow.make({
  name: "WaitForEmailWorkflow",
  payload: { id: Schema.String },
  success: Schema.String,
  idempotencyKey: ({ id }) => id,
});

export const WaitForEmailWorkflowLayer = WaitForEmailWorkflow.toLayer(
  Effect.fnUntraced(function* () {
    const sentAt = yield* Activity.make({
      name: "WaitBeforeTrigger",
      success: Schema.DateTimeUtc,
      execute: Effect.gen(function* () {
        yield* DurableClock.sleep({
          name: "email-trigger-delay",
          duration: "10 seconds",
          inMemoryThreshold: Duration.zero,
        });
        return yield* DateTime.now;
      }),
    });

    const triggerResult = yield* DurableDeferred.await(EmailTrigger);
    return `${triggerResult}:${DateTime.formatIso(sentAt)}`;
  }),
);
```

Guidelines:

- Use `DurableClock.sleep` instead of long `Effect.sleep` when the workflow may suspend or move between runners.
- Use `DurableDeferred.token` when an external actor needs to complete a workflow later.
- Use `DurableDeferred.done`, `succeed`, `fail`, or `failCause` at the boundary that receives the external result.
- Use `Workflow.resume(executionId)` for manually resumed suspended executions.

### Use durable queues for worker-driven work

```ts
import { Effect, Layer, Schema } from "effect";
import { PersistedQueue } from "effect/unstable/persistence";
import { DurableQueue, Workflow, WorkflowEngine } from "effect/unstable/workflow";

export const ScoreQueue = DurableQueue.make({
  name: "AssessmentScoreQueue",
  payload: {
    id: Schema.String,
    rawScore: Schema.Number,
  },
  success: Schema.Number,
  idempotencyKey: ({ id }) => id,
});

export const ScoreWorkflow = Workflow.make({
  name: "ScoreWorkflow",
  payload: {
    id: Schema.String,
    rawScore: Schema.Number,
  },
  success: Schema.Number,
  idempotencyKey: ({ id }) => id,
});

export const ScoreWorkflowLayer = Layer.mergeAll(
  ScoreWorkflow.toLayer(({ id, rawScore }) => DurableQueue.process(ScoreQueue, { id, rawScore })),
  DurableQueue.worker(ScoreQueue, ({ rawScore }) => Effect.succeed(rawScore + 1), {
    concurrency: 5,
  }),
).pipe(
  Layer.provideMerge(WorkflowEngine.layerMemory),
  Layer.provideMerge(
    PersistedQueue.layer.pipe(Layer.provideMerge(PersistedQueue.layerStoreMemory)),
  ),
);
```

Guidelines:

- Use `DurableQueue.process` when workflow progress depends on an external worker pool.
- Keep queue payload, success, error, and idempotency schemas explicit.
- Put worker concurrency at the worker layer, not in workflow orchestration code.
- Worker failures propagate through the queue's error schema to the workflow result.

## Modular, testable, maintainable services

### Separate definition, implementation, workers, and engine

A maintainable workflow feature normally has:

1. tagged errors and schemas,
2. workflow definitions,
3. activities, queues, deferreds, and clocks owned by the feature,
4. `toLayer` implementation that yields domain services from context,
5. optional worker layers,
6. an engine layer provided by tests or application composition.

Do not hide the engine inside the workflow module unless that module is a final runtime composition. Tests should be able to provide `WorkflowEngine.layerMemory`, and live code should be able to provide `ClusterWorkflowEngine.layer`.

### Wrap workflows in application services when callers need a stable capability

Use a service when application code should not know about workflow execution details. The service resolves supported backends, returns safe defaults for unsupported inputs, maps dependency errors, and exposes domain methods.

```ts
import { Context, Effect, Layer, Option, Schema } from "effect";
import { Workflow, WorkflowEngine } from "effect/unstable/workflow";

export class AssessmentWorkflowError extends Schema.TaggedErrorClass<AssessmentWorkflowError>()(
  "AssessmentWorkflowError",
  { message: Schema.String },
) {}

export interface AssessmentWorkflowServiceShape {
  readonly start: (input: {
    readonly assessmentId: string;
    readonly recordingId: string;
  }) => Effect.Effect<string, never>;

  readonly poll: (
    executionId: string,
  ) => Effect.Effect<Option.Option<Workflow.Result<void, AssessmentWorkflowError>>, never>;
}

export const AssessmentWorkflow = Workflow.make({
  name: "AssessmentWorkflow",
  payload: {
    assessmentId: Schema.String,
    recordingId: Schema.String,
  },
  error: AssessmentWorkflowError,
  idempotencyKey: ({ assessmentId }) => assessmentId,
});

export class AssessmentWorkflowService extends Context.Service<
  AssessmentWorkflowService,
  AssessmentWorkflowServiceShape
>()("app/assessment/AssessmentWorkflowService") {}

export const AssessmentWorkflowServiceLayer: Layer.Layer<
  AssessmentWorkflowService,
  never,
  WorkflowEngine.WorkflowEngine
> = Layer.effect(
  AssessmentWorkflowService,
  Effect.gen(function* () {
    const services = yield* Effect.context<WorkflowEngine.WorkflowEngine>();

    return AssessmentWorkflowService.of({
      start: (input) =>
        AssessmentWorkflow.execute(input, {
          discard: true,
        }).pipe(Effect.provideContext(services)),
      poll: (executionId) =>
        AssessmentWorkflow.poll(executionId).pipe(Effect.provideContext(services)),
    });
  }),
);
```

Guidelines:

- Expose domain verbs such as `startAssessment`, `pollAssessment`, or `cancelAssessment`.
- Keep execution ids and polling semantics at the service boundary when UI or API code should not depend on Workflow directly.
- Map workflow errors into API/domain errors when crossing a public boundary.
- Use `Layer.mock(Service)` in tests for consumers that do not need to exercise the workflow engine.

### Generate API surfaces from workflow definitions when possible

`WorkflowProxy` derives RPC or HTTP API definitions from the workflow schemas, and `WorkflowProxyServer` derives handlers that call `execute`, `execute(..., { discard: true })`, and `resume`.

```ts
import { Layer, Schema } from "effect";
import { HttpApi, HttpApiBuilder } from "effect/unstable/httpapi";
import { Workflow, WorkflowProxy, WorkflowProxyServer } from "effect/unstable/workflow";

const NotifyWorkflow = Workflow.make({
  name: "NotifyWorkflow",
  payload: {
    id: Schema.String,
    to: Schema.String,
  },
  idempotencyKey: ({ id }) => id,
});

const workflows: readonly [typeof NotifyWorkflow] = [NotifyWorkflow];

class WorkflowApi extends HttpApi.make("api").add(
  WorkflowProxy.toHttpApiGroup("workflows", workflows),
) {}

export const WorkflowApiLayer = HttpApiBuilder.layer(WorkflowApi).pipe(
  Layer.provide(WorkflowProxyServer.layerHttpApi(WorkflowApi, "workflows", workflows)),
);
```

Guidelines:

- Prefer proxy generation over duplicating payload, error, and success schemas by hand.
- Keep proxy layers close to HTTP/RPC composition, not inside the workflow behavior layer.
- Use discard endpoints for start-and-poll flows; use normal execute endpoints only when the caller should wait for completion.

## Error handling patterns

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
