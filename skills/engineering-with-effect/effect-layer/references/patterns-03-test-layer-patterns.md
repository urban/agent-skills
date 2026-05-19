# Effect `Layer` patterns for agents — part 3

Covers:

- Test-layer patterns
- Background and entrypoint layers
- What to avoid

---

## Test-layer patterns

- Prefer production composition in tests. Replace true external boundaries with `Layer.succeed` or `Layer.mock`.
- Use `Layer.provideMerge` in test layers when assertions need access to lower-level test state.
- Keep test state in services such as `Ref.Ref<ReadonlyArray<T>>` rather than module globals when the state belongs to the layer.
- Use a shared test layer only when shared state across tests is intentional. Otherwise, build/provide a fresh layer per test.

```ts
import { assert, it, vi } from "@effect/vitest";
import { Context, Effect, Layer, Ref } from "effect";

interface Todo {
  readonly id: number;
  readonly title: string;
}

export class TodoRepoTestRef extends Context.Service<
  TodoRepoTestRef,
  Ref.Ref<ReadonlyArray<Todo>>
>()("myapp/TodoRepoTestRef") {
  static readonly layer = Layer.effect(TodoRepoTestRef, Ref.make<ReadonlyArray<Todo>>([]));
}

export class TodoRepo extends Context.Service<
  TodoRepo,
  {
    readonly create: (title: string) => Effect.Effect<Todo>;
    readonly list: Effect.Effect<ReadonlyArray<Todo>>;
  }
>()("myapp/TodoRepo") {
  static readonly layerTest = Layer.effect(
    TodoRepo,
    Effect.gen(function* () {
      const store = yield* TodoRepoTestRef;

      return TodoRepo.of({
        create: (title) =>
          Ref.modify(store, (todos) => {
            const todo = { id: todos.length + 1, title };
            return [todo, [...todos, todo]];
          }),
        list: Ref.get(store),
      });
    }),
  ).pipe(Layer.provideMerge(TodoRepoTestRef.layer));
}

const mockRun = vi.fn<(command: string) => Effect.Effect<string>>();

const ExternalBoundaryTest = Layer.mock(ExternalBoundary)({
  run: mockRun,
});

it.effect("uses the test repository", () =>
  Effect.gen(function* () {
    const repo = yield* TodoRepo;
    yield* repo.create("Write docs");
    assert.deepStrictEqual(yield* repo.list, [{ id: 1, title: "Write docs" }]);
  }).pipe(Effect.provide(TodoRepo.layerTest)),
);
```

## Background and entrypoint layers

Use `Layer.effectDiscard` for scoped background work that does not provide a service. Fork long-running work with `Effect.forkScoped` so it is interrupted when the layer scope closes.

```ts
import { Effect, Layer } from "effect";

export const BackgroundSync = Layer.effectDiscard(
  Effect.gen(function* () {
    yield* Effect.gen(function* () {
      while (true) {
        yield* Effect.sleep("5 seconds");
        yield* runSyncOnce;
      }
    }).pipe(Effect.forkScoped);
  }),
);
```

Use `Layer.launch` only at process/application entrypoints where the application is represented as a long-running layer, such as an HTTP server or worker.

## What to avoid

- Do not put domain branching, parsing, or orchestration directly in a top-level application layer. Put it in services and provide those services with layers.
- Do not build layers manually inside ordinary service methods. Manual `Layer.build`, `Layer.buildWithScope`, or `Layer.buildWithMemoMap` belongs at runtime lifetime boundaries.
- Do not rely on default sharing for request-bound resources, sockets, streams, or Worker I/O objects that must be scoped to one request.
- Do not use `Layer.provideMerge` by default. If callers should not see dependency services, use `Layer.provide`.
- Do not use `Layer.orDie` to hide recoverable configuration, validation, network, SQL, or auth failures.
- Do not expose `unknown` error channels from layers. Keep layer and service errors precise.
- Do not create generic errors like `ServiceFailed` or `UnknownError`; define specific tagged errors with actionable fields.
- Do not use partial mocks as a substitute for behavior tests. `Layer.mock` is for replacing external boundaries or services irrelevant to the assertion.
- Do not use module-level mutable state for test doubles when the state should be tied to layer lifetime. Use `Ref`, `Layer.effect`, and scoped test layers.
- Do not add spans around every layer by habit. Use `Layer.withSpan` only when layer construction or lifetime needs explicit observability; method-level spans should use `Effect.fn` when required by the project rules.
