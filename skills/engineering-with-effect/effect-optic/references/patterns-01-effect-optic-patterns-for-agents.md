# Effect `Optic` patterns for agents — part 1

Covers:

- Effect Optic patterns for agents
- First principles
- Optic kinds and when to use them
- Encapsulate behavior behind domain functions
- Keep services modular, testable, and maintainable
- Error handling patterns
- Use replaceResult when missing focus is an error

---

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
