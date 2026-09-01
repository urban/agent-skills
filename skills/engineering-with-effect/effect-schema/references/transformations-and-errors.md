# Transformations and errors

## Transformation law

Before adding a transform, state:

- decode input and normalized output
- encode input and emitted output
- whether both directions can fail
- whether round-trip is lossless or intentionally canonicalizing

For canonicalization, compare against the canonical equivalence relation rather than raw original bytes.

## Error mapping

Keep schema issues intact inside boundary code. Map them to a domain error when callers need a stable category or public-safe message. Retain path/cause information in safe diagnostic fields where useful.

Avoid catch-all fallback. Recover only a named semantic failure, such as a missing optional file; malformed content and access failures should remain observable.

## Constraints and tagged errors

Prefer built-in Schema constraints and compositions before introducing a custom predicate. When several constraints form one caller-facing invariant, compose them and attach a stable message annotation to the composition only when callers need that diagnostic.

Define schema-backed yieldable errors with the native self-typed class pattern:

```ts
export class RecordDecodeError extends Schema.TaggedError<RecordDecodeError>()(
  "RecordDecodeError",
  {},
) {}
```

The exported class is both the schema constructor and instance type. Do not add a parallel type alias, manually intersect it with another yieldable-error type, pass a broad shared self type that loses the tag and fields, or hide the pattern behind a project-specific wrapper. Related error classes may remain together when they form one cohesive error family.

## Tests

- representative successful decode and encode
- rejection at important invariant boundaries
- excess-property behavior when compatibility depends on it
- normalization examples
- encode/decode law promised by the codec
- custom generator validity when the schema supplies arbitrary generation
