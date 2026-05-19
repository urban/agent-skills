# Functional Style

Use this reference when implementing or refactoring TypeScript transformations.

## Defaults

- Prefer declarative transformations that describe what changes, not imperative code that forces readers to simulate each step.
- Prefer expressions over statements because expressions produce values, compose naturally, and keep side effects visible at boundaries.
- Prefer pure functions: same input, same output, no observable side effects.
- Make dependencies explicit parameters instead of closing over mutable globals, time, randomness, config, or I/O.
- Push effects to program edges: parse at boundaries, perform I/O at boundaries, transform with pure functions in the middle.
- Prefer `const fn = (...) => ...` for nearly all functions.
- Prefer native collection methods before introducing a helper.
- Use named intermediate functions or variables when they clarify the transformation.

## Expression-oriented code

Prefer code where branches and transformations produce values directly:

```ts
const label = user.active ? `Active: ${user.name}` : `Inactive: ${user.name}`

const status = (() => {
  switch (state._tag) {
    case "Loading":
      return "Loading"
    case "Loaded":
      return `Loaded ${state.count}`
    case "Failed":
      return state.reason
  }
})()
```

Avoid statement-heavy code that hides the produced value behind mutation:

```ts
// Avoid.
let label = ""

if (user.active) {
  label = `Active: ${user.name}`
} else {
  label = `Inactive: ${user.name}`
}
```

Do not force expressions when they become unreadable. Extract a named helper instead of stacking nested ternaries or immediately invoked functions everywhere:

```ts
const getStatus = (state: LoadState) => {
  switch (state._tag) {
    case "Loading":
      return "Loading"
    case "Loaded":
      return `Loaded ${state.count}`
    case "Failed":
      return state.reason
  }
}

const status = getStatus(state)
```

## Immutability and mutation

Prefer immutable updates:

```ts
const addItem = <T>(item: T) => (xs: readonly T[]) => [...xs, item]
```

Local mutation is acceptable when it is hidden inside an otherwise pure function:

```ts
const groupByKind = <T extends { kind: string }>(xs: readonly T[]) => {
  const groups: Record<string, T[]> = {}

  for (const x of xs) {
    groups[x.kind] = [...(groups[x.kind] ?? []), x]
  }

  return groups
}
```

Avoid mutation that leaks to callers:

```ts
// Avoid: mutates caller-owned array.
const sortNumbers = (xs: number[]) => xs.sort((a, b) => a - b)

// Prefer: returns a new sorted array.
const sortNumbers = (xs: readonly number[]) => xs.toSorted((a, b) => a - b)
```

## Native collection methods first

Prefer native methods when they communicate the pipeline clearly:

```ts
const activeNames = users
  .filter((user) => user.active)
  .map((user) => user.name)
  .toSorted()
```

Do not create wrappers just to look functional:

```ts
// Avoid unless reused enough to pay for itself.
const map = <A, B>(fn: (x: A) => B) => (xs: readonly A[]) => xs.map(fn)
```

Create wrappers when partial application improves reuse:

```ts
const hasRole = (role: Role) => (user: User) => user.roles.includes(role)

const admins = users.filter(hasRole("admin"))
const editors = users.filter(hasRole("editor"))
```

## Manual currying and partial application

Use manual currying for reusable specialization. Put stable configuration first and data last.

```ts
const formatCurrency =
  (currency: string) =>
  (amount: number) =>
    `${currency}${amount.toFixed(2)}`

const formatUsd = formatCurrency("$")
```

Prefer grouped parameters when full currying becomes awkward:

```ts
const clamp =
  ({ min, max }: { min: number; max: number }) =>
  (value: number) =>
    Math.max(min, Math.min(max, value))

const clampPercent = clamp({ min: 0, max: 100 })
```

## Pointed versus pointfree

Pointfree style is allowed when it remains obvious:

```ts
const getName = (user: User) => user.name
const names = users.map(getName)
```

Use pointed callbacks when they are clearer:

```ts
const labels = users.map((user) => `${user.name} <${user.email}>`)
```

Avoid clever chains that hide the business rule. Prefer readable callbacks, named helpers, and small transformations.
