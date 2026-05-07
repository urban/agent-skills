# Failures and Absence

Use this reference when replacing `null`, `any`, or exception-driven control flow with explicit TypeScript models.

## Absence

Do not introduce `null`.

Prefer `undefined` or optional properties for simple absence:

```ts
type User = {
  id: UserId
  email?: string
}

const findUser = (id: UserId): User | undefined =>
  users.find((user) => user.id === id)
```

Use a discriminated union when absence has meaning or needs a reason:

```ts
type LookupUserResult =
  | { _tag: "Found"; user: User }
  | { _tag: "NotFound"; id: UserId }
```

When editing legacy code that already uses `null`, isolate it at the boundary and convert into the local project model as soon as possible.

## Expected failures

Do not use `throw` for expected validation, parsing, lookup, permission, or domain failures. Put the failure in the return type.

```ts
type ParseAgeError =
  | { _tag: "NotANumber"; input: string }
  | { _tag: "NegativeAge"; value: number }

type ParseAgeResult =
  | { _tag: "Valid"; age: number }
  | { _tag: "Invalid"; error: ParseAgeError }

const parseAge = (input: string): ParseAgeResult => {
  const age = Number(input)

  if (!Number.isFinite(age)) {
    return { _tag: "Invalid", error: { _tag: "NotANumber", input } }
  }

  if (age < 0) {
    return { _tag: "Invalid", error: { _tag: "NegativeAge", value: age } }
  }

  return { _tag: "Valid", age }
}
```

Use the smallest result shape that accurately models the domain. Do not invent a generic `Result` type unless it improves multiple call sites in the current project.

## Boundary errors

Frameworks, runtimes, and third-party APIs may throw. Catch or adapt at the boundary, then return an explicit domain type inside the codebase.

```ts
type DecodeJsonResult =
  | { _tag: "Decoded"; value: unknown }
  | { _tag: "InvalidJson"; input: string }

const decodeJson = (input: string): DecodeJsonResult => {
  try {
    return { _tag: "Decoded", value: JSON.parse(input) }
  } catch {
    return { _tag: "InvalidJson", input }
  }
}
```

The `try`/`catch` here is a boundary adapter. Do not let exceptions become the internal domain model.

## Avoiding `any`

Use `unknown` for untrusted data and narrow it.

```ts
type UserInput = {
  email: string
}

const isUserInput = (x: unknown): x is UserInput =>
  typeof x === "object" &&
  x !== null &&
  "email" in x &&
  typeof x.email === "string"
```

If `x !== null` appears in a guard, that is interop with JavaScript's runtime object model, not permission to introduce `null` as a domain value.

Prefer generic constraints when data is trusted but shape-dependent:

```ts
const getId = <T extends { id: string }>(x: T) => x.id
```

Avoid assertions except at verified boundaries. If an assertion appears in core business logic, first try to model or narrow the type properly.
