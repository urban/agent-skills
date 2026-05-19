# Effect Cluster patterns for agents

These notes capture the project patterns for writing with Effect's Cluster modules. They are based on:

- `repos/effect/ai-docs/src/80_cluster/10_entities.ts`
- `repos/effect/packages/effect/src/unstable/cluster/*`
- cluster tests in `repos/effect/packages/effect/test/cluster` and `repos/effect/packages/platform-node/test/cluster`
- platform cluster layers in `repos/effect/packages/platform-node/src` and `repos/effect/packages/platform-bun/src`
- a search of the other vendored repos. `repos/t3code` and `repos/executor` do not currently use Cluster modules. `repos/alchemy-effect` only recognizes `@effect/cluster` as a package name in bundle tooling, so the reusable implementation patterns come from the Effect repo itself.

## First principles

- Treat Cluster as an actor/entity runtime for stateful, per-identity behavior. Do not use it as a generic RPC wrapper for stateless services.
- Model the public message protocol with `Rpc.make` and `Schema` before writing handlers. The protocol is the durable boundary.
- Keep domain behavior behind `Context.Service` services. Entity clients are an infrastructure detail that services can use internally.
- Use `Entity.make("Name", [rpcs])` for the entity definition and `Entity.toLayer(...)` for the implementation.
- Prefer `TestRunner.layer` or `Entity.makeTestClient` for tests, `SingleRunner.layer` for local durable single-node workflows, and `NodeClusterSocket.layer` / `NodeClusterHttp.layer` for live runners.
- Use `ClusterSchema.Persisted` only when the message can be replayed safely and the environment provides `MessageStorage`.
- Keep error channels precise. Business failures belong in RPC error schemas. Cluster delivery failures are typed as cluster errors such as `MailboxFull`, `AlreadyProcessingMessage`, and `PersistenceError`.

## Behavior encapsulation

### Put per-entity state inside the entity layer

`Entity.toLayer` builds behavior for an active entity. Keep in-memory state in the build effect so passivation and restart boundaries are clear.

Adapted from `repos/effect/ai-docs/src/80_cluster/10_entities.ts`:

```ts
import { Effect, Layer, Ref, Schema } from "effect";
import { ClusterSchema, Entity } from "effect/unstable/cluster";
import { Rpc } from "effect/unstable/rpc";

export const Increment = Rpc.make("Increment", {
  payload: { amount: Schema.Number },
  success: Schema.Number,
});

export const GetCount = Rpc.make("GetCount", {
  success: Schema.Number,
}).annotate(ClusterSchema.Persisted, true);

export const Counter = Entity.make("Counter", [Increment, GetCount]);

export const CounterEntityLayer = Counter.toLayer(
  Effect.gen(function* () {
    const count = yield* Ref.make(0);

    return Counter.of({
      Increment: ({ payload }) => Ref.updateAndGet(count, (current) => current + payload.amount),
      GetCount: () => Ref.get(count).pipe(Rpc.fork),
    });
  }),
  { maxIdleTime: "5 minutes" },
);
```

Guidelines:

- Let the entity own mutable in-memory state such as `Ref`, `Queue`, local caches, and per-entity coordination.
- Keep state transitions in handlers small and explicit.
- Use `maxIdleTime` to make passivation intentional.
- Use `Rpc.fork` only for handlers that are safe to run concurrently with other handlers. The default sequential processing is the safer actor-style choice.
- Use `toLayerQueue` only when the entity needs a custom mailbox loop or dispatcher. Return replies through the provided `replier` instead of leaking queues to callers.

### Wrap entity clients in domain services

Application code should usually depend on a service, not on `Sharding` or raw entity clients.

```ts
import { Context, Effect, Layer } from "effect";
import { Sharding } from "effect/unstable/cluster";

export class CounterService extends Context.Service<
  CounterService,
  {
    readonly increment: (input: {
      readonly counterId: string;
      readonly amount: number;
    }) => Effect.Effect<number, CounterError>;

    readonly getCount: (counterId: string) => Effect.Effect<number, CounterError>;
  }
>()("app/counter/CounterService") {
  static readonly layer: Layer.Layer<CounterService, never, Sharding.Sharding> = Layer.effect(
    CounterService,
    Effect.gen(function* () {
      const clientFor = yield* Counter.client;

      return CounterService.of({
        increment: ({ counterId, amount }) =>
          clientFor(counterId).Increment({ amount }).pipe(mapCounterClientErrors),
        getCount: (counterId) => clientFor(counterId).GetCount().pipe(mapCounterClientErrors),
      });
    }),
  );
}
```

Map cluster delivery errors into domain errors at this service boundary.

## Modular, testable, maintainable services

### Split entity definitions, handlers, and runner composition

A maintainable cluster feature normally has:

1. schemas and tagged errors,
2. RPC definitions,
3. `Entity.make(...)`,
4. entity handler layer,
5. domain service layer that uses the entity client,
6. runner composition at the application edge.

Adapted from `repos/effect/ai-docs/src/80_cluster/10_entities.ts` and `repos/effect/packages/effect/src/unstable/cluster/TestRunner.ts`:

```ts
import { NodeClusterSocket } from "@effect/platform-node";
import { Layer } from "effect";
import { TestRunner } from "effect/unstable/cluster";

const EntitiesLayer = Layer.mergeAll(CounterEntityLayer);

export const TestLayer = EntitiesLayer.pipe(Layer.provideMerge(TestRunner.layer));

export const ProductionLayer = EntitiesLayer.pipe(Layer.provide(NodeClusterSocket.layer()));
```

Guidelines:

- Compose all entity layers separately from the cluster runtime layer.
- Use `Layer.provideMerge` in tests when assertions need direct access to `MessageStorage`, `MemoryDriver`, or `Sharding`.
- Keep final live layers explicitly typed in application code.
- Use `ShardingConfig.layer(...)` in tests to make mailbox capacity, termination timeout, polling, and retry intervals deterministic.

### Test through public clients

Adapted from `repos/effect/packages/effect/test/cluster/Entity.test.ts`:

```ts
import { assert, it } from "@effect/vitest";
import { Effect } from "effect";
import { Entity, ShardingConfig } from "effect/unstable/cluster";

const TestShardingConfig = ShardingConfig.layer({
  shardsPerGroup: 300,
  entityMailboxCapacity: 10,
  entityTerminationTimeout: 0,
  entityMessagePollInterval: 5000,
  sendRetryInterval: 100,
});

it.effect("round trips through the entity client", () =>
  Effect.gen(function* () {
    const makeClient = yield* Entity.makeTestClient(Counter, CounterEntityLayer);
    const client = yield* makeClient("counter-1");

    const count = yield* client.Increment({ amount: 1 });

    assert.strictEqual(count, 1);
  }).pipe(Effect.provide(TestShardingConfig)),
);
```

Prefer this style over constructing handlers directly in tests. Use lower-level storage assertions only when testing persistence, replay, or delivery semantics.

## Error handling patterns

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

Adapted from `repos/effect/packages/effect/test/cluster/TestEntity.ts`:

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

Adapted from `repos/effect/packages/effect/test/cluster/TestEntity.ts`:

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

Adapted from `repos/effect/packages/effect/src/unstable/cluster/EntityProxy.ts`:

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
- Do not edit or import from `repos/effect`; it is reference material only.
