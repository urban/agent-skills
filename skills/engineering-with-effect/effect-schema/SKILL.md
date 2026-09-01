---
name: effect-schema
description: Design Effect Schema boundaries by choosing decoded and encoded representations, trust level, normalization, absence semantics, compatibility, and useful validation failures. Use when modeling wire contracts, transformations, branded values, tagged errors, or schema behavior tests.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Design the decoded domain representation and encoded boundary representation separately before choosing constructors.
- Let schema implementations own schema-backed domain types: derive decoded and encoded types from the schema rather than repeating their shapes or widening initialized schemas with broad annotations.
- Choose decoding APIs from the actual trust boundary: unknown external input and statically typed encoded input are different contracts.
- Normalize compatibility quirks at the boundary so domain code has one vocabulary for absence, variants, dates, numbers, and identifiers.
- Map schema failures only where the caller needs domain meaning; otherwise preserve the schema error for precise diagnostics.
- Prefer built-in constraints and schema composition before custom predicates, and use the native self-typed tagged-error class pattern for failures that need both schema and Error behavior.

## Constraints

- A transformation must define credible behavior in both directions when the schema is used as a codec.
- Opaque values may remain unknown only when opacity itself is the contract.
- Runtime class identity is an intentional semantic choice for ordinary data, not a default replacement for plain schema structures. Schema-backed yieldable errors use the native tagged-error class pattern without a parallel type alias or project wrapper.

## Knowledge Boundaries

Applies to:

- domain versus encoded shape
- trusted versus untrusted decode paths
- brands, refinements, transformations, optional fields, null compatibility, and tagged variants
- schema error mapping and semantic tests

Does not cover:

- lint-owned constructor/style preferences
- protocol-specific HTTP or AI behavior beyond their schema boundary

Decision inputs:

- source trust and compatibility obligations
- representation required by domain logic and storage/wire peers
- whether a boundary representation such as a database row differs from the trusted domain value
- whether absence means missing key, explicit undefined, null, `Option`, or a tagged state
- whether encoding must round-trip losslessly or intentionally normalize

## Patterns

- Put wire compatibility in the encoded side and return a canonical domain value from decoding.
- Derive `Type` and `Encoded` from the schema implementation. Compose schema unions from their member schemas, and use `satisfies` when configuration needs checking without replacing its precise inferred type.
- Give raw database rows, provider payloads, and other differently shaped boundary values their own schemas. Decode there, then keep only compatibility decisions that depend on application policy in the application layer.
- Use brands and checks for invariants that must survive module boundaries; use tagged unions when variants have different required data or behavior.
- Select a class for ordinary data only when methods, prototype identity, or class-based framework integration matter. Prefer plain structures for ordinary serializable values; use `Schema.TaggedError<Self>()` directly for schema-backed yieldable errors.
- Compile and reuse decoders/encoders on hot paths; the important judgment is where the boundary lives, not merely which helper spelling is used.
- For JSON strings, compose JSON parsing and domain validation into one schema codec so syntax and shape failures share a typed boundary.
- Test representative valid values, meaningful rejection cases, normalization, excess-property policy where relevant, and encode/decode laws promised by the contract.

## Gotchas

- Reusing one TypeScript shape for both wire and domain data can hide transformations such as string dates, nullable fields, or legacy names.
- Handwriting a type beside its schema or annotating the initialized schema broadly can erase literals, brands, field modifiers, and encoded differences; derive from the implementation and preserve inference.
- Accepting `null` for compatibility without normalizing it creates multiple absence vocabularies throughout the domain.
- A lossy transform can pass decode tests while corrupting later encodes; test the direction or round-trip law the product relies on.
- Turning every schema issue into a generic parse error removes paths and causes needed for debugging; map only at the domain-facing boundary.
- A local tagged-error wrapper or broad self type can erase the tag and fields that make failure unions narrowable; use the native self-typed factory directly and let the class be both schema and type.
- A custom predicate that restates built-in constraints makes diagnostics and encoded semantics harder to inspect; compose native constraints first and add a stable message annotation only when callers need one.
- Generating only valid values proves acceptance but not rejection policy; add focused invalid cases for important invariants.

## References

- [`references/representation-and-decoding.md`](./references/representation-and-decoding.md): Read when: choosing Type versus Encoded, trust-aware decoders, optionality, brands, classes, or JSON codecs.
- [`references/transformations-and-errors.md`](./references/transformations-and-errors.md): Read when: designing reversible normalization, fallible transforms, schema error mapping, or semantic tests.
