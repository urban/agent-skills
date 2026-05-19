# Effect `Layer` patterns for agents — part 2

Covers:

- Compose with the right operator
- Resource and lifetime patterns
- Use scoped acquisition in Layer.effect
- Be explicit about shared vs per-request lifetimes
- Use Layer.fresh sparingly
- Dynamic and optional layers
- Error handling patterns

---

### Compose with the right operator

- `Layer.mergeAll(a, b, c)` builds independent layers concurrently and exposes all their services.
- `Layer.provide(deps)` supplies dependencies to a layer and hides those dependency services from the output.
- `Layer.provideMerge(deps)` supplies dependencies and keeps them in the output. Use this for tests or middleware stacks that still need direct access to lower-level services.

```ts
import { Layer } from "effect";

const DbLive = DbService.Live;
const UserStoreLive = UserStoreService.Live.pipe(Layer.provide(DbLive));

export const RequestScopedServicesLive = Layer.mergeAll(DbLive, UserStoreLive);

export const BootSharedServices = Layer.mergeAll(
  CoreSharedServices,
  HttpServer.layerServices,
  TelemetryLive,
);

export const NonProtectedApiLive = HttpApiBuilder.layer(NonProtectedApi).pipe(
  Layer.provide(Layer.mergeAll(CloudAuthPublicHandlers, CloudSessionAuthHandlers)),
  Layer.provideMerge(ApiKeyService.WorkOS),
  Layer.provide(requestScopedMiddleware(RequestScopedServicesLive).layer),
  Layer.provideMerge(SessionAuthLive),
);
```

Example pattern:

## Resource and lifetime patterns

### Use scoped acquisition in `Layer.effect`

If a service owns a socket, file handle, process, client, or subscription, acquire it inside the layer and register release with `Effect.acquireRelease`. Effect's layer tests verify that finalizers run when the scope closes, that `provide` releases nested resources in reverse dependency order, and that interruption releases anything already acquired.

```ts
import { Context, Effect, Layer } from "effect";

export interface DbServiceShape {
  readonly query: (sql: string) => Effect.Effect<ReadonlyArray<unknown>>;
}

interface DbResource extends DbServiceShape {
  readonly close: Effect.Effect<void>;
}

const makeDbResource = Effect.sync(
  (): DbResource => ({
    query: () => Effect.succeed([]),
    close: Effect.void,
  }),
);

export class DbService extends Context.Service<DbService, DbServiceShape>()("myapp/DbService") {
  static readonly Live: Layer.Layer<DbService> = Layer.effect(
    DbService,
    Effect.acquireRelease(makeDbResource, (resource) => resource.close),
  );
}
```

### Be explicit about shared vs per-request lifetimes

Default layer memoization is usually desirable. It is wrong for request-bound resources in runtimes that forbid cross-request I/O reuse. In that case, build the request-scoped layer inside request handling with a fresh `MemoMap` and the request scope.

```ts
import { Effect, Layer } from "effect";
import { HttpRouter } from "effect/unstable/http";

export const requestScopedMiddleware = <A>(layer: Layer.Layer<A>) =>
  HttpRouter.middleware<{ provides: A }>()((httpEffect) =>
    Effect.scoped(
      Effect.gen(function* () {
        const memoMap = yield* Layer.makeMemoMap;
        const scope = yield* Effect.scope;
        const services = yield* Layer.buildWithMemoMap(layer, memoMap, scope);
        return yield* Effect.provideContext(httpEffect, services);
      }),
    ),
  );
```

The important rule is not “always manual-build layers”; it is “manual-build only at a lifetime boundary that Effect's normal application composition cannot express.”

### Use `Layer.fresh` sparingly

`Layer.fresh(layer)` disables sharing for that layer value. The Effect tests show it causes a duplicated acquisition when the same layer is merged or provided more than once. Use it only when each consumer must have independent state or an independent resource.

## Dynamic and optional layers

Use `Layer.unwrap` when an Effect decides which layer should exist. Good uses include configuration, optional telemetry, and environment-specific implementations.

```ts
import { Effect, Layer } from "effect";

const buildTelemetryLayer = (attributes: Record<string, string>): Layer.Layer<never> =>
  Layer.mergeAll(TracerLayer(attributes), MetricsLayer(attributes), LoggerLayer(attributes)).pipe(
    Layer.provide(JsonSerializationLayer),
    Layer.provide(HttpClientLayer),
  );

export const TelemetryLive: Layer.Layer<never> = Layer.unwrap(
  Effect.gen(function* () {
    const disabled = yield* isTelemetryDisabled;
    if (disabled) {
      return Layer.empty;
    }

    const attributes = yield* collectTelemetryAttributes;
    return buildTelemetryLayer(attributes);
  }),
);
```

Example pattern:

## Error handling patterns

- Services should expose typed errors for actionable failures. Use `Schema.TaggedErrorClass` and narrow with `Effect.catchTag` / `Effect.catchTags` in callers.
- Map lower-level dependency errors at the service boundary, inside `make` or method implementations.
- Layer construction errors should remain typed unless they are truly unrecoverable at final composition.
- Use `Layer.catchTag` when a layer has a meaningful fallback implementation.
- Use `Layer.orDie` only on final live compositions whose remaining construction errors are defects from the application's point of view.
- Do not use `Effect.orDie`. If a typed failure is non-actionable at a service boundary, handle that specific tag and die deliberately.

```ts
import { Context, Effect, Layer, Schema } from "effect";

export class PrimaryUnavailable extends Schema.TaggedErrorClass<PrimaryUnavailable>()(
  "PrimaryUnavailable",
  { detail: Schema.String },
) {}

export class MessageStore extends Context.Service<
  MessageStore,
  {
    readonly append: (message: string) => Effect.Effect<void>;
    readonly all: Effect.Effect<ReadonlyArray<string>>;
  }
>()("myapp/MessageStore") {}

const inMemoryStore = Layer.effect(
  MessageStore,
  Effect.sync(() => {
    const messages: Array<string> = [];
    return MessageStore.of({
      append: (message) =>
        Effect.sync(() => {
          messages.push(message);
        }),
      all: Effect.sync(() => [...messages]),
    });
  }),
);

const remoteStore = Layer.effect(
  MessageStore,
  Effect.gen(function* () {
    return yield* new PrimaryUnavailable({ detail: "remote store is unavailable" });
  }),
);

export const MessageStoreLive: Layer.Layer<MessageStore> = remoteStore.pipe(
  Layer.catchTag("PrimaryUnavailable", () => inMemoryStore),
);
```
