---
name: effect-schema
description: Design Effect Schema contracts for runtime validation, typed boundaries, transformations, JSON codecs, tagged errors, HTTP APIs, and semantic schema tests. Use when defining or refactoring schemas, decoding untrusted data, encoding boundary data, modeling tagged errors, designing transformations, handling JSON, or deriving API and test contracts.
---

## Native Effect Standards

- Define schemas at boundaries and reuse them for both runtime validation and TypeScript types.
- Treat `Schema.Type` as the decoded/domain representation and `Schema.Encoded` as the input/output representation.
- Decode untrusted data with `Schema.decodeUnknownEffect` or `Schema.decodeUnknownSync`; decode statically typed encoded data with `Schema.decodeEffect` or `Schema.decodeSync`.
- Hoist compiled decoders and encoders to module scope because compiler calls allocate.
- Prefer `Schema.Struct` / `Schema.TaggedStruct` plus `export type X = typeof X.Type` for plain data. Use `Schema.Class` only when runtime class instances, methods, or `instanceof` semantics are intentional.
- Use `Schema.TaggedErrorClass` for Effect errors that should be caught with `Effect.catchTag` / `Effect.catchTags`.
- Use `Schema.fromJsonString(...)` instead of `JSON.parse` at implementation boundaries.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not call `Schema.decode*` / `Schema.encode*` compiler functions inside hot functions. Hoist them.
- Do not use `JSON.parse` / `JSON.stringify` for typed boundary data. Use `Schema.fromJsonString`, `Schema.UnknownFromJsonString`, and schema encoders.
- Do not use `Schema.Any` or `Schema.Unknown` inside domain models unless the data is intentionally opaque. Keep unknown shapes at boundaries.
- Do not use `Schema.String` where a literal union, brand, or constrained string expresses the domain.
- Do not represent domain absence with `null`. Accept `Schema.NullOr(...)` only for external wire compatibility and normalize it.
- Do not throw for expected validation failures. Use `decodeUnknownEffect`, `decodeUnknownExit`, `decodeUnknownOption`, or map `Schema.SchemaError` into a tagged error.
- Do not use `Schema.Class` for plain DTOs unless runtime class identity is required. Prefer `Struct` / `TaggedStruct` for serializable shapes.
- Do not hide schema errors by catching them and returning broad fallbacks unless the fallback is part of the product contract.
- Do not add type assertions to force schema types. If inference is hard, introduce a named schema, `typeof Schema.Type`, `typeof Schema.Encoded`, or a narrower helper.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- boundary data source and trusted/untrusted status
- decoded domain shape and encoded wire shape
- constraints, brands, literals, optionality, and absence semantics
- error mapping and test expectations

Effect-native code should tend toward:

- schemas reused for runtime validation and TypeScript types
- hoisted encoders/decoders and JSON codecs
- precise tagged errors and domain error mapping
- tests for successful decoding, rejection, round trips, and custom filters

Applies to:

- applying Effect Schema patterns to implementation, refactoring, review, or tests
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

- Bundled `references/patterns-*` files contain source-pattern detail for changing schemas, transformations, codecs, tagged errors, or API contracts.
- Define schemas at boundaries and export `type X = typeof X.Type` for decoded domain values.
- Choose optionality and absence vocabulary deliberately: optional key, present undefined, null compatibility, `Option`, or tagged variant.
- Use literal unions, brands, and checks to model domain constraints instead of loose strings and numbers.
- Decode unknown input with `decodeUnknownEffect`, statically typed encoded input with `decodeEffect`, and JSON strings with `Schema.fromJsonString`.
- Hoist compiled decoders and encoders to module scope and map `SchemaError` to domain tagged errors at boundaries.
- Test semantic success/failure and round trips, using parse options where strict behavior matters.

## Gotchas

- If schemas are only TypeScript annotations, untrusted inputs still cross unchecked. Use schemas for both runtime validation and types.
- If compiler functions are rebuilt inside hot paths, validation allocates unnecessary work. Hoist decoders and encoders.
- If `null` is introduced for convenience, the domain gains a second absence model. Accept null only for wire compatibility and normalize it.
- If `Schema.Unknown` spreads into domain models, callers lose shape guarantees. Keep unknown data at boundaries unless it is intentionally opaque.
- If JSON is parsed directly, schema validation and decoding errors are bypassed. Use `Schema.fromJsonString` or schema encoders/decoders.
- If expected validation failures throw, Effect callers cannot pattern-match or recover. Keep failures as `SchemaError` or map them to tagged errors.

## References

- [`references/patterns-01-effect-schema-patterns-for-agents.md`](./references/patterns-01-effect-schema-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Schema patterns for agents, First principles, Common constructors and combinators.
- [`references/patterns-02-decode-json-strings-with-schemas.md`](./references/patterns-02-decode-json-strings-with-schemas.md): Read when: you need source-pattern detail for Decode JSON strings with schemas, Encode typed values, Hoist compilers.
- [`references/patterns-03-schema-decode-errors.md`](./references/patterns-03-schema-decode-errors.md): Read when: you need source-pattern detail for Schema decode errors, Tagged errors for Effect programs, Custom validation messages.
