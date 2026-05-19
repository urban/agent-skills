# Effect Cluster patterns for agents — part 1

Covers:

- Effect Cluster patterns for agents
- First principles
- Behavior encapsulation
- Put per-entity state inside the entity layer
- Wrap entity clients in domain services
- Modular, testable, maintainable services
- Split entity definitions, handlers, and runner composition
- Test through public clients

---

# Effect Cluster patterns for agents

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
