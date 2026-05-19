# Effect `Optic` patterns for agents — part 2

Covers:

- Use replace or modify for intentional no-op behavior
- Use getResult for diagnostics and branching
- Optional fields: choose deletion or preservation deliberately
- Traversal patterns
- Schema and custom type patterns

---

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
