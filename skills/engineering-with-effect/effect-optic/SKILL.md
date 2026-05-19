---
name: effect-optic
description: Use Effect Optic for pure immutable updates and reads over nested data, optional focuses, union variants, traversals, schema classes, custom types, and service error mapping. Use when replacing repeated nested immutable updates, designing reusable optics, updating optional or union-shaped state, traversing arrays or records, working with schema-backed classes, or mapping optic failures in services.
---

## Native Effect Standards

- Use `Optic` for repeated or complex immutable updates to nested data, union variants, optional fields, records, arrays, and schema-backed custom types.
- Keep optics pure. An optic is a reusable focus plus pure read/replace/modify behavior. It should not perform I/O, read services, log, mutate external state, or decode untrusted input.
- Hoist reusable optics or optic builders to the owning domain module. Do not repeat long property paths across services, components, tests, or reducers.
- Let services own behavior and effects. Services may call pure optic helpers, but they should expose domain operations and typed domain errors rather than exposing raw optics.
- Choose explicit failure semantics. `replace` and `modify` silently return the original value when an optional focus fails; use `getResult` or `replaceResult` when missing focus is actionable.
- Prefer `Schema.toIso` when updating schema classes, newtypes, maps, sets, URLs, headers, cookies, or other non-plain structures. Path optics clone plain objects and arrays only; class instances should be converted through an `Iso`.
- Prefer `readonly` domain shapes and pure functions. `Optic` preserves immutability and reuses unrelated branches, but no-op updates may still allocate, so do not use reference identity as a no-op detector.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

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
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- domain data shape and update/read operation
- whether missing focus is a no-op or actionable failure
- optional deletion versus preservation semantics
- custom type or schema class conversion needs

Effect-native code should tend toward:

- named pure optics or domain transition helpers
- explicit failure/no-op semantics using `Result` where needed
- service-level typed error mapping for missing focuses
- tests for present, absent, optional, union, traversal, and custom-type cases

Applies to:

- applying Effect Optic patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for using optional focuses, traversals, schema classes, or custom type optics.
- Hoist reusable optics or optic builders to the owning domain module; expose domain verbs rather than raw optic chains.
- Choose focus operators deliberately: `key`, `optionalKey`, `at`, `tag`, `refine`, `check`, `notUndefined`, and traversal combinators have different absence semantics.
- Use `replaceResult` or `getResult` when missing focus is actionable; use `replace` or `modify` only for intentional no-op behavior.
- Use `Schema.toIso`, `Newtype.makeIso`, or a lossless `Optic.makeIso` for schema classes and custom prototypes.
- Map optic `Result.Failure<string>` into specific tagged service errors at boundaries.
- Test pure transitions directly, including absent-focus and optional deletion/preservation cases.

## Gotchas

- If long optic chains are inlined at every call site, path details become duplicated implementation API. Name the transition near the domain type.
- If `replace` or `modify` is used where absence should fail, required updates silently no-op. Use `replaceResult` or `getResult` and map the failure.
- If `.key` is used for dynamic indexes or record keys, missing values are modeled incorrectly. Use `.at` when absence matters.
- If unions are updated without narrowing, the type system rejects or the logic becomes ambiguous. Narrow with `.tag` or `.refine` first.
- If plain path optics update schema classes or custom prototypes, instances can lose their intended construction semantics. Use schema or newtype isos.
- If optic failure strings escape through service APIs, callers get brittle text instead of domain errors. Translate them to tagged errors.

## References

- [`references/patterns-01-effect-optic-patterns-for-agents.md`](./references/patterns-01-effect-optic-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Optic patterns for agents, First principles, Optic kinds and when to use them.
- [`references/patterns-02-use-replace-or-modify-for-intentional-no-op-beha.md`](./references/patterns-02-use-replace-or-modify-for-intentional-no-op-beha.md): Read when: you need source-pattern detail for Use replace or modify for intentional no-op behavior, Use getResult for diagnostics and branching, Optional fields: choose deletion or preservation deliberately.
- [`references/patterns-03-testing-guidance.md`](./references/patterns-03-testing-guidance.md): Read when: you need source-pattern detail for Testing guidance, What to avoid.
