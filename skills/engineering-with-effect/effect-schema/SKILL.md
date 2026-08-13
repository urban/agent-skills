---
name: effect-schema
description: Design Effect Schema boundaries by choosing decoded and encoded representations, trust level, normalization, absence semantics, compatibility, and useful validation failures. Use when modeling wire contracts, transformations, branded values, tagged errors, or schema behavior tests.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Design the decoded domain representation and encoded boundary representation separately before choosing constructors.
- Choose decoding APIs from the actual trust boundary: unknown external input and statically typed encoded input are different contracts.
- Normalize compatibility quirks at the boundary so domain code has one vocabulary for absence, variants, dates, numbers, and identifiers.
- Map schema failures only where the caller needs domain meaning; otherwise preserve the schema error for precise diagnostics.

## Constraints

- A transformation must define credible behavior in both directions when the schema is used as a codec.
- Opaque values may remain unknown only when opacity itself is the contract.
- Runtime class identity is an intentional semantic choice, not a default replacement for plain schema data.

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
- whether absence means missing key, explicit undefined, null, `Option`, or a tagged state
- whether encoding must round-trip losslessly or intentionally normalize

## Patterns

- Put wire compatibility in the encoded side and return a canonical domain value from decoding.
- Use brands and checks for invariants that must survive module boundaries; use tagged unions when variants have different required data or behavior.
- Select a class only when methods, prototype identity, or class-based framework integration matter. Prefer plain structures for ordinary serializable values.
- Compile and reuse decoders/encoders on hot paths; the important judgment is where the boundary lives, not merely which helper spelling is used.
- For JSON strings, compose JSON parsing and domain validation into one schema codec so syntax and shape failures share a typed boundary.
- Test representative valid values, meaningful rejection cases, normalization, excess-property policy where relevant, and encode/decode laws promised by the contract.

## Gotchas

- Reusing one TypeScript shape for both wire and domain data can hide transformations such as string dates, nullable fields, or legacy names.
- Accepting `null` for compatibility without normalizing it creates multiple absence vocabularies throughout the domain.
- A lossy transform can pass decode tests while corrupting later encodes; test the direction or round-trip law the product relies on.
- Turning every schema issue into a generic parse error removes paths and causes needed for debugging; map only at the domain-facing boundary.
- Class schemas used for plain DTOs add identity and construction semantics callers may accidentally depend on.
- Generating only valid values proves acceptance but not rejection policy; add focused invalid cases for important invariants.

## References

- [`references/representation-and-decoding.md`](./references/representation-and-decoding.md): Read when: choosing Type versus Encoded, trust-aware decoders, optionality, brands, classes, or JSON codecs.
- [`references/transformations-and-errors.md`](./references/transformations-and-errors.md): Read when: designing reversible normalization, fallible transforms, schema error mapping, or semantic tests.
