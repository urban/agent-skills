# Effect Cluster patterns for agents — part 2

Covers:

- Put business errors in RPC schemas
- Map cluster delivery errors at the boundary
- Treat defects as defects
- Persistence and delivery patterns
- HTTP/RPC proxy patterns
- What to avoid

---

### Put business errors in RPC schemas

Cluster transport errors and domain errors are different concerns. Define business failures as tagged schema errors and attach them to the RPC.

```ts
import { Effect, Schema } from "effect";
import { Rpc } from "effect/unstable/rpc";

export class CounterError extends Schema.TaggedErrorClass<CounterError>()("CounterError", {
  _tag: Schema.tag("CounterError"),
  reason: Schema.Literals(["NegativeAmount", "CounterClosed"]),
  detail: Schema.String,
}) {}

export const Add = Rpc.make("Add", {
  payload: { amount: Schema.Number },
  success: Schema.Number,
  error: CounterError,
});

const AddLayer = Counter.toLayer(
  Effect.gen(function* () {
    const count = yield* Ref.make(0);

    return Counter.of({
      Add: ({ payload }) =>
        Effect.gen(function* () {
          if (payload.amount < 0) {
            return yield* new CounterError({
              reason: "NegativeAmount",
              detail: "amount must be zero or greater",
            });
          }

          return yield* Ref.updateAndGet(count, (current) => current + payload.amount);
        }),
    });
  }),
);
```

Guidelines:

- Use `Schema.TaggedErrorClass` / `Schema.ErrorClass` with `_tag` discriminators.
- In `Effect.gen`, `return yield* new MyError(...)` for expected failures.
- Catch expected errors with `Effect.catchTag` / `Effect.catchTags` at service boundaries.
- Do not throw for expected domain failures.

### Map cluster delivery errors at the boundary

`Entity.client` calls can fail with delivery errors such as:

- `MailboxFull`
- `AlreadyProcessingMessage`
- `PersistenceError`

The proxy helpers also expose these client errors. Handle them explicitly where user-visible behavior is decided.

```ts
const mapCounterClientErrors = <A, E, R>(effect: Effect.Effect<A, E, R>) =>
  effect.pipe(
    Effect.catchTags({
      MailboxFull: () =>
        Effect.fail(
          new CounterError({
            reason: "CounterClosed",
            detail: "counter mailbox is full; retry later",
          }),
        ),
      AlreadyProcessingMessage: () =>
        Effect.fail(
          new CounterError({
            reason: "CounterClosed",
            detail: "a request with the same primary key is already processing",
          }),
        ),
      PersistenceError: () =>
        Effect.fail(
          new CounterError({
            reason: "CounterClosed",
            detail: "counter request could not be persisted",
          }),
        ),
    }),
  );
```

Adjust the domain error reasons to match the real service. Do not collapse all cluster failures into `UnknownError` or `XFailed`.

### Treat defects as defects

The Effect tests show that entity defects can restart the entity when a `defectRetryPolicy` is configured. Use this for unexpected crashes, not expected validation.

```ts
export const ResilientEntityLayer = Counter.toLayer(
  Effect.gen(function* () {
    return Counter.of({
      Increment: ({ payload }) => Effect.sync(() => payload.amount),
      GetCount: () => Effect.succeed(0),
    });
  }),
  { defectRetryPolicy: Schedule.forever },
);
```

Guidelines:

- Expected failures: typed error channel.
- Unexpected bugs or impossible states: defects, with an intentional retry policy if the entity should restart.
- Durable messages without `MessageStorage` are invalid and defect in the cluster runtime. Do not mark RPCs persisted unless storage is part of the layer.

## Persistence and delivery patterns

- Volatile RPCs are network delivery only. Annotate with `ClusterSchema.Persisted` when replay, resume, or deduplication is required.
- Use stable primary keys for durable commands where duplicate submissions must collapse to one in-flight request.
- `discard: true` is fire-and-forget from the client's perspective. It does not mean the durable work is skipped.
- For durable streams, use stream schemas and resume from `request.lastSentChunkValue` / `request.nextSequence` when implementing custom stream behavior.
- Use `ClusterSchema.WithTransaction` for handlers that need message-storage and SQL work committed atomically.
- Use `ClusterSchema.Uninterruptible` narrowly for operations that must not be interrupted on the client, server, or both.
- Use `ClusterSchema.ShardGroup` when a feature needs a non-default shard group.

```ts
export const StreamWithKey = Rpc.make("StreamWithKey", {
  success: RpcSchema.Stream(Schema.Number, Schema.Never),
  payload: { key: Schema.String },
  primaryKey: ({ key }) => key,
});

export const DurableEntity = Entity.make("DurableEntity", [
  Rpc.make("RequestWithKey", {
    payload: { key: Schema.String },
    primaryKey: ({ key }) => key,
  }),
  StreamWithKey,
]).annotateRpcs(ClusterSchema.Persisted, true);
```

## HTTP/RPC proxy patterns

Use `EntityProxy` when an entity should be exposed through an RPC group or HTTP API. Keep the generated proxy at the adapter edge.

```ts
import { EntityProxy, EntityProxyServer } from "effect/unstable/cluster";
import { RpcServer } from "effect/unstable/rpc";

export class CounterRpcs extends EntityProxy.toRpcGroup(Counter) {}

export const CounterRpcServerLayer = RpcServer.layer(CounterRpcs).pipe(
  Layer.provide(EntityProxyServer.layerRpcHandlers(Counter)),
);
```

Guidelines:

- Proxy layers require `Sharding` and the entity's server-side RPC services.
- Do not make generated proxy payload shapes the core domain model. They include adapter concerns such as `entityId`.
- Catch and map proxy-visible cluster errors at the HTTP/RPC adapter boundary.

## What to avoid

- Do not pass `Sharding`, entity clients, `MessageStorage`, or runner internals through domain APIs.
- Do not use Cluster for stateless CRUD or one-off background tasks when a normal service, queue, or workflow is simpler.
- Do not keep production entity state in module-level mutable variables. Put per-entity state in `toLayer` and shared dependencies in services.
- Do not use `Rpc.fork` for handlers that mutate the same state unless the mutation is safe under concurrency.
- Do not mark RPCs persisted without a storage layer and an idempotency/replay story.
- Do not throw global `Error` values for expected failures.
- Do not erase delivery failures into `unknown`, `Error`, or generic `InternalError` types.
- Do not use wall-clock sleeps in cluster tests unless the test is intentionally live/networked. Prefer `TestClock.adjust(...)`, explicit queues, scoped fibers, and `sharding.pollStorage`.
- Do not hand-roll socket clients, serialization, shard assignment, or message persistence. Use the provided runner layers and storage modules.
- Do not edit or import from `.dotai/repos/effect`; it is reference material only.
