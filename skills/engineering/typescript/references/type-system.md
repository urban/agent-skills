# Type System

Use this reference when deciding how much TypeScript to write explicitly versus letting inference work.

## Inference defaults

Let the compiler infer implementation details:

```ts
const count = 5
const names = users.map((user) => user.name)
const isActive = (user: User) => user.active
```

Avoid redundant annotations:

```ts
// Avoid.
const count: number = 5
const isActive = (user: User): boolean => user.active
```

Annotate an exported/public return type when it defines a deliberate abstraction or stabilizes an otherwise implementation-sensitive API:

```ts
export const fetchUser = (id: UserId): Promise<User> =>
  repository.findUser(id)
```

Preserve inference when the implementation is itself the authoritative contract, such as a typed builder, class factory, or declaration helper whose inferred literals, brands, dependencies, failures, or input/output representations would be duplicated or widened by a broad annotation. Verify the inferred public type with the compiler rather than widening the implementation to satisfy a redundant annotation.

Prefer exported `const` functions over named function declarations unless the surrounding code has a strong existing convention or a platform requires declarations.

## Break-glass annotations

Add explicit types when inference cannot communicate the intended contract:

- public functions whose intended abstraction is not already expressed by an authoritative implementation
- recursive functions
- empty arrays or objects that are populated later
- intentional literal unions or narrower types
- complex inferred unions that should be simplified or named
- boundary assertions after validation

```ts
const emptyUsers: User[] = []

const walkTree = (node: Tree): readonly NodeId[] => [
  node.id,
  ...node.children.flatMap(walkTree),
]
```

## `satisfies`

Use `satisfies` when a value must conform to a shape without losing its specific inferred properties.

```ts
const config = {
  port: 8080,
  host: "localhost",
} satisfies ServerConfig
```

Prefer this over annotating the variable when callers benefit from the exact inferred shape.

## Discriminated unions

Use discriminated unions for domain states and variants.

```ts
type LoadState<T> =
  | { _tag: "Idle" }
  | { _tag: "Loading" }
  | { _tag: "Loaded"; value: T }
  | { _tag: "Failed"; reason: string }

const getMessage = (state: LoadState<User>) => {
  switch (state._tag) {
    case "Idle":
      return "Not started"
    case "Loading":
      return "Loading"
    case "Loaded":
      return state.value.name
    case "Failed":
      return state.reason
  }
}
```

Use exhaustive handling when the branch result matters. If a project has an `assertNever` helper, match it; otherwise keep the union simple enough for TypeScript to prove the switch.

## Branded types

Use branded types when primitive values have domain meaning that should not be mixed accidentally.

```ts
type Brand<T, Name extends string> = T & { readonly __brand: Name }

type UserId = Brand<string, "UserId">
type TeamId = Brand<string, "TeamId">

const UserId = (value: string): UserId => value as UserId
```

Keep branding lightweight. Brand at validated boundaries and avoid spreading assertions throughout business logic.

## Generics

Use generics to preserve relationships between inputs and outputs, not to make code look abstract.

```ts
const first = <T>(xs: readonly T[]) => xs[0]

const byId = <T extends { id: string }>(xs: readonly T[]) =>
  Object.fromEntries(xs.map((x) => [x.id, x]))
```

Short names like `x`, `xs`, `T`, `K`, and `V` are fine in small generic utilities where their role is obvious.

## Advanced type boundary

Use mapped types, conditional types, template literal types, and inference helpers when they simplify caller-facing types or prevent invalid states.

Avoid type-level puzzles when:

- the runtime code is simple but the type takes longer to understand than the behavior
- the type error becomes unreadable for normal callers
- one-off cleverness replaces a named domain type
- a smaller discriminated union would express the same idea

Prefer clear domain names over clever generic names once a type represents business meaning.
