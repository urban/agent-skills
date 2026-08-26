# Properties and arbitraries

Useful laws include idempotence, round trip, normalization, ordering, commutativity, monotonicity, invariant preservation, and error classification.

Prefer schema-derived arbitrary generation when the schema owns the valid space. Add custom generation when constraints are relational, generation is too sparse, or a declaration cannot generate useful values.

Avoid broad filtering. Generate constrained values directly or construct related tuples so shrinking preserves the relationship.

For codecs, choose the law:

- encode(decode(encoded)) equals canonical encoded value
- decode(encode(domain)) equals domain value
- both directions are lossless

These are not interchangeable when normalization is intentional.
