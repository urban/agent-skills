# Effect Workflow patterns for agents — part 2

Covers:

- Use durable queues for worker-driven work
- Modular, testable, maintainable services
- Separate definition, implementation, workers, and engine
- Wrap workflows in application services when callers need a stable capability
- Generate API surfaces from workflow definitions when possible
- Error handling patterns

---

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
