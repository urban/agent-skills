# Effect Core architecture standards for agents — part 2

Source: `/Volumes/Code/personal/agent-skills/RULES.md`. This chunk is vendored so the skill remains atomic.

Covers:
- purity and immutability
- readonly data and Effect collection modules
- optics for immutable updates
- domain colocation and flat directory structure
- TanStack Router file placement
- branded IDs
- imports, navigation semantics, optionality, piping, and schema identifiers

---

# Architecture standards

## Pure and immutable defaults

- Prefer referentially transparent and pure functions.
- Immutability is required unless code is truly performance critical, which is rare.
- Default props, params, and collections to readonly shapes such as `readonly` properties and `ReadonlyArray`.
- Prefer Effect collection modules such as `Array` for immutable collection transforms.
- For repeated or complex nested immutable updates, use Effect `Optic`.

## Module and domain structure

- Prefer flat directory structures.
- Each module should have its own directory with its files directly inside it instead of extra nesting layers.
- Follow DDD style colocation.
- Define domain modules inside the directory for that domain, export them there, and import them from that domain location instead of creating global shared domain modules.
- No barrel `index.ts` files. Import from the defining module.

## TanStack Router placement

- With TanStack Router, keep each route's file and its page-specific code colocated in that route directory.
- Put non-route page files in a nested directory whose name starts with `-` so TanStack Router ignores it recursively.

## Branded IDs

- Entity IDs are branded with `Schema.brand` in the owning RPC module.
- Construct branded IDs with `EntityId.makeUnsafe()`.
- Never cast with `as EntityId`.

## Navigation semantics

- Navigation actions must use real links, not buttons.
- Preserve normal link semantics like middle click, open in a new tab, and copy link target.
- When a destination should open in a new tab, use a real link with `target="_blank"`.

## Optionality

- Do not use optional properties when every consumer passes the value.
- Reserve optional properties for generic primitive-level modules or genuine absence.

## Piping and composition style

- Pipeable values must use `.pipe(...)`.
- Non-pipeable values must use Effect `pipe()` and `flow()`.
- Do not write nested application like `f(g(x))`.

## Schema naming

- Named schemas must add `.annotate({ identifier: "MySchemaName" })`.
