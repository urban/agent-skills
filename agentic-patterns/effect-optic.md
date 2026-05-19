# Effect `Optic` patterns for agents

## First principles

- Use `Optic` for repeated or complex immutable updates to nested data, union variants, optional fields, records, arrays, and schema-backed custom types.
- Keep optics pure. An optic is a reusable focus plus pure read/replace/modify behavior. It should not perform I/O, read services, log, mutate external state, or decode untrusted input.
- Hoist reusable optics or optic builders to the owning domain module. Do not repeat long property paths across services, components, tests, or reducers.
- Let services own behavior and effects. Services may call pure optic helpers, but they should expose domain operations and typed domain errors rather than exposing raw optics.
- Choose explicit failure semantics. `replace` and `modify` silently return the original value when an optional focus fails; use `getResult` or `replaceResult` when missing focus is actionable.
- Prefer `Schema.toIso` when updating schema classes, newtypes, maps, sets, URLs, headers, cookies, or other non-plain structures. Path optics clone plain objects and arrays only; class instances should be converted through an `Iso`.
- Prefer `readonly` domain shapes and pure functions. `Optic` preserves immutability and reuses unrelated branches, but no-op updates may still allocate, so do not use reference identity as a no-op detector.

## Optic kinds and when to use them

| Shape                                                            | Pattern                                          |
| ---------------------------------------------------------------- | ------------------------------------------------ |
| Whole value                                                      | `Optic.id<State>()`                              |
| Always-present struct or tuple field                             | `.key("field")` / `.key(0)`                      |
| Optional field where setting `undefined` should preserve the key | `.key("field")`                                  |
| Optional field where setting `undefined` should delete/splice    | `.optionalKey("field")` / `.optionalKey(index)`  |
| Record key or array index that may not exist                     | `.at(key)` / `.at(index)`                        |
| Tagged union variant                                             | `.tag("Variant")` before `.key(...)`             |
| Predicate or schema check                                        | `.refine(...)` or `.check(...)`                  |
| Drop `undefined` before updating                                 | `.notUndefined()`                                |
| Array traversal                                                  | `.forEach(...)` plus `.modifyAll(...)`           |
| Record traversal                                                 | `Optic.entries<A>().forEach(...)`                |
| Class/custom schema/newtype                                      | `Schema.toIso(schema)` or `Newtype.makeIso<T>()` |

`key`, `optionalKey`, `pick`, `omit`, and `at` intentionally reject union focuses at the type level. Narrow with `.tag(...)` or `.refine(...)` first.

## Encapsulate behavior behind domain functions

Define named optics and transition functions near the domain type they update. Callers should not know the path details.

```ts
import { Optic } from "effect";

interface Task {
  readonly id: number;
  readonly done: boolean;
  readonly title: string;
}

interface Project {
  readonly id: number;
  readonly name: string;
  readonly tasks: ReadonlyArray<Task>;
}

interface State {
  readonly user: { readonly id: string; readonly name: string };
  readonly settings: { readonly theme: "light" | "dark" };
  readonly projects: ReadonlyArray<Project>;
}

const taskDone = (projectIndex: number, taskIndex: number) =>
  Optic.id<State>().key("projects").at(projectIndex).key("tasks").at(taskIndex).key("done");

export const completeTask = (projectIndex: number, taskIndex: number) =>
  taskDone(projectIndex, taskIndex).replaceResult(true);
```

Use this shape because:

- path construction is centralized;
- callers receive a named behavior, not a chain of implementation details;
- tests can cover the pure transition directly;
- dynamic indexes use `.at(...)`, so absent elements are explicit failures instead of accidental `undefined` path updates.

## Keep services modular, testable, and maintainable

Services should depend on domain transition helpers, not inline nested updates. A service boundary maps optic failure strings into typed, actionable domain errors.

```ts
import { Context, Effect, Layer, Result, Schema } from "effect";

export class ProjectStateError extends Schema.TaggedErrorClass<ProjectStateError>()(
  "ProjectStateError",
  {
    reason: Schema.Literals(["MissingTask"]),
    detail: Schema.String,
  },
) {}

export interface CompleteTaskInput {
  readonly state: State;
  readonly projectIndex: number;
  readonly taskIndex: number;
}

export interface ProjectStateShape {
  readonly completeTask: (input: CompleteTaskInput) => Effect.Effect<State, ProjectStateError>;
}

export class ProjectState extends Context.Service<ProjectState, ProjectStateShape>()(
  "app/project/ProjectState",
) {
  static readonly layer: Layer.Layer<ProjectState> = Layer.succeed(
    ProjectState,
    ProjectState.of({
      completeTask: Effect.fnUntraced(function* (input) {
        const result = completeTask(input.projectIndex, input.taskIndex)(input.state);

        if (Result.isFailure(result)) {
          return yield* new ProjectStateError({
            reason: "MissingTask",
            detail: result.failure,
          });
        }

        return result.success;
      }),
    }),
  );
}
```

Follow this pattern:

- Keep `Optic` chains in pure helpers.
- Expose domain verbs from services, such as `completeTask`, not `replaceAtPath` or raw optics.
- Yield services from context inside effect bodies when a transition needs external dependencies.
- Use `Effect.fnUntraced` for effectful wrappers unless spans are needed.
- Test pure transitions without layers, then test service wiring with layer substitution only at true external boundaries.

## Error handling patterns

### Use `replaceResult` when missing focus is an error

`replace` and `modify` never throw on focus failure. They return the original source unchanged. That is useful for best-effort transformations, but dangerous for required business invariants.

```ts
import { Optic, Result } from "effect";

type Env = { readonly [key: string]: number };

const port = Optic.id<Env>().at("PORT");

const updated = port.replaceResult(8080, { PORT: 3000 });
// success({ PORT: 8080 })

const missing = port.replaceResult(8080, {});
// failure('Key "PORT" not found')

const message = Result.match(missing, {
  onSuccess: () => "updated",
  onFailure: (detail) => detail,
});
```

Map the failure string to a specific `Schema.TaggedErrorClass` at service boundaries. Do not expose generic errors such as `UpdateFailed`, do not use `unknown` error channels, and do not convert expected optic failures into defects.

### Use `replace` or `modify` for intentional no-op behavior

Use no-op semantics when the business rule is “update this only if it exists.” Tagged-union and validation filters often fit this pattern.

```ts
import { Optic, Schema } from "effect";

type Shape =
  | { readonly _tag: "Circle"; readonly radius: number }
  | { readonly _tag: "Rect"; readonly width: number };

const positiveCircleRadius = Optic.id<Shape>()
  .tag("Circle")
  .key("radius")
  .check(Schema.isGreaterThan(0));

const grow = positiveCircleRadius.modify((radius) => radius + 1);

grow({ _tag: "Circle", radius: 2 });
// { _tag: "Circle", radius: 3 }

grow({ _tag: "Rect", width: 10 });
// unchanged

grow({ _tag: "Circle", radius: 0 });
// unchanged because the check failed
```

### Use `getResult` for diagnostics and branching

`getResult` returns `Result.Result<A, string>`. Use it when a caller must distinguish “not focused” from a present value.

```ts
import { Optic, Result } from "effect";

type Draft = { readonly title?: string };

const title = Optic.id<Draft>().key("title").notUndefined();

const label = Result.match(title.getResult({}), {
  onSuccess: (value) => `title: ${value}`,
  onFailure: () => "untitled",
});
```

## Optional fields: choose deletion or preservation deliberately

```ts
import { Optic } from "effect";

type Draft = { readonly title?: string | undefined };

const preservingTitle = Optic.id<Draft>().key("title");
const deletingTitle = Optic.id<Draft>().optionalKey("title");

preservingTitle.replace(undefined, { title: "old" });
// { title: undefined }

deletingTitle.replace(undefined, { title: "old" });
// {}
```

Guideline:

- Use `.key(...)` when `undefined` is a meaningful stored value or the key must remain present.
- Use `.optionalKey(...)` when `undefined` means absence and should delete an object key or splice an array element.
- Use `.notUndefined()` when a later update should only run for present values.

## Traversal patterns

A `Traversal<S, A>` is modeled as `Optional<S, ReadonlyArray<A>>`. This makes two operations easy to confuse:

- `.modify(...)` transforms the entire collected array of focused values.
- `.modifyAll(...)` transforms each focused value independently.

```ts
import { Optic, Schema } from "effect";

interface Post {
  readonly title: string;
  readonly likes: number;
}

interface State {
  readonly user: { readonly posts: ReadonlyArray<Post> };
}

const positiveLikes = Optic.id<State>()
  .key("user")
  .key("posts")
  .forEach((post) => post.key("likes").check(Schema.isGreaterThan(0)));

const addLike = positiveLikes.modifyAll((likes) => likes + 1);

addLike({
  user: {
    posts: [
      { title: "a", likes: 0 },
      { title: "b", likes: 1 },
    ],
  },
});
// only the positive like count changes
```

For records, use `Optic.entries`:

```ts
import { Optic, Schema } from "effect";

const positiveRecordValues = Optic.entries<number>().forEach((entry) =>
  entry.key(1).check(Schema.isGreaterThan(0)),
);

const increment = positiveRecordValues.modifyAll((value) => value + 1);

increment({ a: 0, b: 1, c: -1 });
// { a: 0, b: 2, c: -1 }
```

Use `Optic.getAll(traversal)` when extraction is enough. It returns a fresh array and returns `[]` if the traversal cannot focus.

## Schema and custom type patterns

Plain path optics clone arrays and plain objects. They should not be used directly to update class instances. Use `Schema.toIso` or a manually defined `Optic.makeIso` to convert to a plain focus and back.

```ts
import { Schema } from "effect";

class Value extends Schema.Class<Value>("Value")({
  a: Schema.DateValid,
}) {}

class Box extends Schema.Class<Box>("Box")({
  value: Value,
}) {}

const valueDate = Schema.toIso(Box).key("value").key("a");

const addOneDay = valueDate.modify((date) => new Date(date.getTime() + 24 * 60 * 60 * 1000));

addOneDay(Box.make({ value: Value.make({ a: new Date(0) }) }));
// Box.make({ value: Value.make({ a: new Date(86_400_000) }) })
```

For schema-derived structures such as `Option`, `Result`, `Cause`, `Exit`, `ReadonlySet`, `ReadonlyMap`, and HTTP types, use the schema iso to enter the representation, then compose smaller optics.

```ts
import { Schema } from "effect";
import { Headers } from "effect/unstable/http";

const accept = Schema.toIso(Headers.HeadersSchema).at("Accept");

const result = accept.replaceResult(
  "application/json",
  Headers.fromRecordUnsafe({ Accept: "text/plain" }),
);
```

For newtypes, use `Newtype.makeIso<T>()` rather than casting:

```ts
import { Newtype } from "effect";

interface Label extends Newtype.Newtype<"Label", string> {}

const labelIso = Newtype.makeIso<Label>();
const label = labelIso.set("ready");
const raw = labelIso.get(label);
```

## Testing guidance

- Test the public behavior: `get`, `getResult`, `replaceResult`, `replace`, `modify`, or `modifyAll` outputs.
- Include absent-focus cases whenever using `.at`, `.tag`, `.check`, `.refine`, `.some`, `.success`, or `.failure`.
- Include optional deletion/preservation cases when using `.optionalKey` or optional `.key`.
- For important immutable-update behavior, assert changed branches and reused unrelated branches. Do not depend on no-op reference identity.
- For service tests, verify typed error mapping at the service boundary; do not test Effect internals or the Optic implementation itself.

## What to avoid

- Do not mutate source objects, arrays, maps, or class instances in a modifier.
- Do not inline long optic chains at every call site. Name them or wrap them in domain transition functions.
- Do not use `.key(...)` for dynamic record keys or array indexes that may be absent. Use `.at(...)` when absence matters.
- Do not call `.key(...)`, `.optionalKey(...)`, `.pick(...)`, `.omit(...)`, or `.at(...)` on unions. Narrow with `.tag(...)` or `.refine(...)` first.
- Do not rely on `replace` / `modify` to report failures. They intentionally return the original value on optional focus failure.
- Do not leak `Result.Failure<string>` messages as service error contracts. Map them to specific tagged errors.
- Do not use optics as service dependencies. Services expose capabilities; optics are pure implementation helpers.
- Do not use direct path optics on schema classes or other custom prototypes. Use `Schema.toIso`, `Newtype.makeIso`, or `Optic.makeIso`.
- Do not use `Optic.makeIso` unless the conversion is genuinely lossless in both directions.
- Do not use `Optic` for one-off shallow updates where a simple object spread is clearer.
