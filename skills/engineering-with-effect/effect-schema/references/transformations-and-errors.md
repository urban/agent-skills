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

## Tests

- representative successful decode and encode
- rejection at important invariant boundaries
- excess-property behavior when compatibility depends on it
- normalization examples
- encode/decode law promised by the codec
- custom generator validity when the schema supplies arbitrary generation
