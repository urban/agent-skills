# Effect Workflow patterns for agents — part 1

Covers:

- Effect Workflow patterns for agents
- First principles
- Behavior encapsulation
- Let the workflow orchestrate; let services do domain work
- Use durable primitives for waits and external completion

---

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
