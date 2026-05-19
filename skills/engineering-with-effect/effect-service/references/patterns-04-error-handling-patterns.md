# Effect `Context.Service` patterns for agents — part 4

Covers:

- Error handling patterns
- Accessing services
- What to avoid

---

## Error handling patterns

- Services must expose typed errors for actionable failures that callers can handle.
- Prefer `Schema.TaggedErrorClass` for app errors so callers can use `Effect.catchTag` / `Effect.catchTags` and schemas can describe the error shape.
- If a tagged error has a `reason`, use `Schema.Literals(...)` with PascalCase values.
- Map lower-level errors to service-level errors inside the service method or adapter boundary.
- Non-actionable failures should remain defects or be converted to defects at the service definition, not exposed as generic `UnknownError` / `InternalError` service failures.
- Do not widen service methods to `Effect<A, unknown>`. Keep expected failures precise.
- Do not throw, use raw `Promise`, or use `async` service methods for expected failures. Use `Effect.try`, `Effect.tryPromise`, `Schema.decodeEffect`, and typed errors.
- When converting a full `Cause` to text for a response or event, use `Cause.pretty(...)` instead of bespoke failure-to-message helpers.

```ts
import { Context, Effect, Schema } from "effect";
import { HttpClient, HttpClientResponse } from "effect/unstable/http";

export class Todo extends Schema.Class<Todo>("Todo")({
  id: Schema.Number,
  title: Schema.String,
  completed: Schema.Boolean,
}) {}

export class TodoApiError extends Schema.TaggedErrorClass<TodoApiError>()("TodoApiError", {
  reason: Schema.Literals(["RequestFailed", "InvalidResponse"]),
  detail: Schema.String,
}) {}

export interface TodoApiShape {
  readonly getTodo: (id: number) => Effect.Effect<Todo, TodoApiError>;
}

export class TodoApi extends Context.Service<TodoApi, TodoApiShape>()("app/TodoApi") {}

export const makeTodoApi = Effect.fnUntraced(function* () {
  const client = yield* HttpClient.HttpClient;

  const getTodo = Effect.fnUntraced(function* (id: number) {
    return yield* client.get(`/todos/${id}`).pipe(
      Effect.flatMap(HttpClientResponse.schemaBodyJson(Todo)),
      Effect.mapError(
        (cause) =>
          new TodoApiError({
            reason: "RequestFailed",
            detail: cause._tag,
          }),
      ),
    );
  });

  return TodoApi.of({ getTodo });
});
```

## Accessing services

Prefer yielding services inside effect bodies:

```ts
const program = Effect.gen(function* () {
  const notifications = yield* Notifications;
  yield* notifications.notify("hello");
  yield* notifications.notify("world");
});
```

Use `Service.use` or `Service.useSync` only for short one-liners:

```ts
const notifyOnce = Notifications.use((notifications) => notifications.notify("hello"));
const configuredPort = ConfigService.useSync((config) => config.port);
```

`Context.Service` implements `use` and `useSync` in `.dotai/repos/effect/packages/effect/src/Context.ts`, but `.dotai/repos/effect/migration/services.md` recommends `yield*` for most workflows because it keeps dependencies visible.

## What to avoid

- Do not create giant service bags. Split by behavior boundary and compose layers.
- Do not pass service implementations as function arguments. Yield required services from context inside effect bodies.
- Do not expose low-level dependencies through high-level service shapes unless callers truly need them.
- Do not create stateful globals outside layers. Use `Layer`, `Ref`, `Queue`, `PubSub`, `Scope`, and finalizers so tests can replace and tear down services safely.
- Do not use `Context.Service(..., { make })` expecting it to auto-wire dependencies or create a layer.
- Do not use direct `JSON.parse` / `JSON.stringify` at implementation boundaries. Use `Schema.fromJsonString(...)` codecs.
- Do not use web `fetch` / `Response` at package boundaries. Prefer first-party Effect HTTP services.
- Do not expose generic failures like `XFailed`, `UnknownError`, or `InternalError` from service methods.
- Do not use `Effect.orDie`; handle typed errors with `Effect.catchTag` / `Effect.catchTags`, then `Effect.die` only for genuinely unrecoverable failures.
- Do not erase errors with `unknown`, `any`, broad catches, or untyped defects.
- Do not use non-null assertions or type assertions in service shapes or implementations.
- Do not overuse `Service.use` for workflows. Prefer `yield* Service` in `Effect.gen`.
