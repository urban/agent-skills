# Effect `Context.Service` patterns for agents — part 3

Covers:

- Use layer factories for parameterized resources
- Use scoped acquisition for owned resources
- Provide small test services

---

### Use layer factories for parameterized resources

When a service needs test options, configuration, or a resource handle, expose a function that returns a layer.

```ts
import { Context, Effect, Layer, Ref } from "effect";

export interface GraphqlTestServerShape {
  readonly endpoint: string;
  readonly requests: Effect.Effect<ReadonlyArray<string>>;
  readonly clearRequests: Effect.Effect<void>;
}

export interface GraphqlTestServerOptions {
  readonly path: string;
}

const serveGraphqlTestServer = (
  options: GraphqlTestServerOptions,
): Effect.Effect<GraphqlTestServerShape> =>
  Effect.gen(function* () {
    const requests = yield* Ref.make<ReadonlyArray<string>>([]);

    return {
      endpoint: `http://127.0.0.1${options.path}`,
      requests: Ref.get(requests),
      clearRequests: Ref.set(requests, []),
    };
  });

export class GraphqlTestServer extends Context.Service<GraphqlTestServer, GraphqlTestServerShape>()(
  "@app/plugin-graphql/testing/GraphqlTestServer",
) {
  static readonly layer = (options: GraphqlTestServerOptions): Layer.Layer<GraphqlTestServer> =>
    Layer.effect(GraphqlTestServer, serveGraphqlTestServer(options));
}
```

Example pattern:

### Use scoped acquisition for owned resources

If a service owns a resource with a lifetime, acquire and release it in the layer with `Effect.acquireRelease`, `Layer.scoped`, or an effect passed to `Layer.effect` that contains acquisition and finalization.

```ts
import { Context, Effect, Layer } from "effect";

export interface TestHarness {
  readonly run: Effect.Effect<void>;
  readonly close: Effect.Effect<void>;
}

export class TestHarnessService extends Context.Service<TestHarnessService, TestHarness>()(
  "app/testing/TestHarness",
) {}

const makeTestHarness: Effect.Effect<TestHarness> = Effect.acquireRelease(
  Effect.sync(() => ({
    run: Effect.void,
    close: Effect.void,
  })),
  (harness) => harness.close,
);

export const makeTestHarnessLayer = (): Layer.Layer<TestHarnessService> =>
  Layer.effect(TestHarnessService, makeTestHarness);
```

Example pattern:

### Provide small test services

Prefer test layers over global mocks. Test services can use `Ref`, `Queue`, `PubSub`, or in-memory repositories while preserving the production contract.

```ts
import { Array, Context, Effect, Layer, Ref } from "effect";

export interface Todo {
  readonly id: number;
  readonly title: string;
}

export class TodoRepoTestRef extends Context.Service<
  TodoRepoTestRef,
  Ref.Ref<ReadonlyArray<Todo>>
>()("app/TodoRepoTestRef") {
  static readonly layer: Layer.Layer<TodoRepoTestRef> = Layer.effect(
    TodoRepoTestRef,
    Ref.make(Array.empty<Todo>()),
  );
}

export interface TodoRepoShape {
  readonly create: (title: string) => Effect.Effect<Todo>;
  readonly list: Effect.Effect<ReadonlyArray<Todo>>;
}

export class TodoRepo extends Context.Service<TodoRepo, TodoRepoShape>()("app/TodoRepo") {
  static readonly layerTest: Layer.Layer<TodoRepo | TodoRepoTestRef> = Layer.effect(
    TodoRepo,
    Effect.gen(function* () {
      const store = yield* TodoRepoTestRef;

      const create = Effect.fnUntraced(function* (title: string) {
        const todos = yield* Ref.get(store);
        const todo = { id: todos.length + 1, title };
        yield* Ref.set(store, [...todos, todo]);
        return todo;
      });

      return TodoRepo.of({ create, list: Ref.get(store) });
    }),
  ).pipe(Layer.provideMerge(TodoRepoTestRef.layer));
}
```

For very small behavior tests, `Layer.mock(Service)` can provide a partial service. Missing members intentionally fail when called, so this is only appropriate when the test proves the path uses a narrow capability.

```ts
import { Context, Effect, Layer, Stream } from "effect";

class ExampleService extends Context.Service<
  ExampleService,
  {
    readonly one: Effect.Effect<number>;
    readonly two: () => Effect.Effect<number>;
    readonly events: Stream.Stream<number>;
  }
>()("ExampleService") {}

const program = Effect.gen(function* () {
  const service = yield* ExampleService;
  return yield* service.one;
}).pipe(
  Effect.provide(
    Layer.mock(ExampleService)({
      one: Effect.succeed(123),
    }),
  ),
);
```
