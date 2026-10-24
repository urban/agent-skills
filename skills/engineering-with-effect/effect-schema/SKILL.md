---
name: effect-schema
description: Design Effect Schema boundaries by choosing decoded and encoded representations, normalization, absence semantics, compatibility, and useful validation failures. Use when modeling wire contracts, transformations, branded values, tagged errors, schema evolution, or schema behavior tests.
---

## Rules

- Design the decoded domain representation and encoded boundary representation separately before choosing constructors.
- Normalize compatibility quirks at the boundary so domain code has one vocabulary for absence, variants, dates, numbers, and identifiers.
- Treat decoding as validation and transformation, even for statically typed encoded input; a TypeScript shape does not establish runtime invariants.
- Choose missing, undefined, null, and default behavior from domain meaning, not convenience. Preserve distinctions when they represent different operations, such as an omitted patch field versus an explicit clear.
- Map schema failures only where the caller needs domain meaning; otherwise preserve the structured issue for precise diagnostics. Keep public error messages separate from sensitive diagnostic data.
- Prefer built-in checks and schema composition before custom predicates; a brand distinguishes values but does not supply a domain validity check.
- Treat compatibility as directional: accepting old input and emitting data old consumers accept are different obligations.

## Constraints

- A transformation must define credible behavior in both directions when the schema is used as a codec. Do not promise lossless round-trips for intentionally lossy normalization.
- Opaque values may remain unknown only when opacity itself is the contract.
- Runtime class identity is an intentional semantic choice for ordinary data, not a default replacement for plain schema structures.
- Defaults must not silently turn malformed input into valid data or fabricate domain facts that were never supplied.

## Knowledge Boundaries

Applies to:

- domain versus encoded shape
- external input validation and boundary normalization
- brands, checks, transformations, optional fields, null compatibility, and tagged variants
- schema error mapping, evolution, and semantic tests

Does not cover:

- lint-owned constructor/style preferences or type-checker-enforced API usage
- protocol-specific HTTP or AI behavior beyond their schema boundary

Decision inputs:

- source trust and compatibility obligations
- representation required by domain logic and storage/wire peers
- whether a boundary representation such as a database row differs from the domain value
- whether absence means missing key, explicit undefined, null, `Option`, or a tagged state
- whether encoding must round-trip losslessly or intentionally normalize
- which consumers must read newly encoded values

## Patterns

- Give raw database rows, provider payloads, and other differently shaped boundary values their own schemas. Put representation compatibility in the codec; keep authorization and application policy outside it.
- Use brands for identifiers that must not mix, checks for runtime invariants, and tagged unions when variants have different required data or behavior.
- Select a class for ordinary data only when methods, prototype identity, or class-based framework integration matter. For schema-backed errors needing Error identity and yieldability, use `Schema.TaggedError`.
- Reuse decoders/encoders at stable boundaries. Effectful checks, getters, and defaults make parsing runtime work: the caller owns service provision and execution, not a hidden runtime inside the codec.
- For JSON strings, compose parsing and domain validation with `Schema.fromJsonString` so syntax and shape failures share one boundary.
- Test acceptance, meaningful rejection, normalization, and the encode/decode laws promised to consumers; use historical fixtures when compatibility is contractual.

## Gotchas

- Reusing one shape for wire and domain data hides string dates, nullable fields, or legacy names. Model the two representations explicitly rather than scattering conversion through domain code.
- Treating missing, undefined, and null as interchangeable can turn a patch omission into a destructive clear. Collapse them only when they mean the same thing to the domain.
- Adding a constructor default does not make old payloads decode successfully: constructor defaults apply only to `make*`. Use a decoding default for wire compatibility and reject malformed present values.
- Choosing `encodingStrategy: "omit"` for a decoding default drops the field even when its value differs from the default. Use passthrough unless discarding every value is intentional.
- A lossy transform can pass decode tests while corrupting later encodes. Test the direction or canonical round-trip law the product relies on.
- Unknown struct keys are stripped by default, not preserved. Tolerant decoding therefore does not make a read-modify-write proxy lossless; explicitly model data that must survive.
- Turning every schema issue into a generic parse error removes paths needed for debugging; dumping the issue instead can expose input. Preserve structured diagnostics internally and map a safe public error at the boundary.
- A brand alone does not validate an identifier's syntax or business meaning. Add the actual check; keep existence and authorization decisions in the application layer.

## References

- [`references/representation-and-decoding.md`](./references/representation-and-decoding.md): Read when: choosing Type versus Encoded, absence/default behavior, brands, classes, or JSON codecs.
- [`references/transformations-and-errors.md`](./references/transformations-and-errors.md): Read when: designing bidirectional normalization, fallible transforms, schema error mapping, evolution, or semantic tests.
