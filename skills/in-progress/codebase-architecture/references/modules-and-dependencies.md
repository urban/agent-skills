# Modules and dependencies

## Deep modules

Depth is caller leverage, not a method or line count. A deep module hides behavior, invariants, compatibility, or coordination that would otherwise burden each caller. A cohesive module may expose many operations around one concept.

Use these questions:

- What must every caller currently know?
- Which invariants or ordering rules can the module own once?
- Would removing the module eliminate complexity or redistribute it?
- Do methods share vocabulary, dependencies, and reasons to change?
- Can one decision vary without forcing unrelated changes elsewhere?
- When files or modules repeatedly change together, are they enforcing one capability or exposing misplaced responsibility?

Use orthogonality as a diagnostic for unrelated co-change, not as a demand that components never interact or overlap. Change amplification, shotgun surgery, and tests that require unrelated setup are reasons to inspect the seam; they are not automatic proof that a module should split. Co-change is appropriate when operations uphold the same invariant or product capability.

Split a module when its operations use unrelated dependencies, express unrelated capabilities, or change for independent product reasons. Do not split merely because a file or class crossed an arbitrary size.

Apply the same test to helpers inside an application operation. Extract a helper when it owns one coherent concern, such as one query plus structural decoding, one remote interaction, or one policy transformation. Keep the public operation readable as the ordered application decision, and keep identity, compatibility, authorization, version, and value-range policy visible there when those choices define its behavior. A line-count limit alone does not create a responsibility.

## Domain modules

A domain module centers on one valid concept or tightly related type family. Its surface may include:

- parser from untrusted or less-structured input
- smart constructor from already-typed parts
- transitions and combinators
- predicates and comparisons
- rendering or serialization owned by the concept
- focused test-data generators or arbitraries

Construction should preserve invariants. A value class is appropriate when runtime identity or cohesive methods add value; keep construction controlled, state immutable to callers, and I/O or dependencies outside the value.

Keep one authoritative representation for independently mutable facts and derive redundant projections by default. Persist a derived value intentionally when it represents a historical snapshot, audit fact, compatibility contract, index, performance trade-off, or the calculation that applied at transaction time.

Prefer composition of values and operations over inheritance hierarchies. Inheritance spreads implicit contracts through subclasses and makes invalid construction or override behavior harder to see.

## Application modules

An application module owns a real capability such as invitations, billing, password reset, or subscription lifecycle. It coordinates domain behavior, persistence, external calls, authorization, workflows, and telemetry without exposing those steps as its interface.

Constructor injection is a useful non-Effect default when an application module has dependencies, configuration, stateful resources, or several cohesive operations. Explicit functional dependency injection is also valid. Avoid passing the same undifferentiated `deps` bag into every function; it obscures which operation needs which capability and encourages broad dependency surfaces.

Choose names from domain capabilities. Names such as `Manager`, `Processor`, `Helper`, or generic `UserService` hide responsibility unless the project or framework gives them a precise established meaning.

## Structural dependency shapes

Let the consumer state the smallest meaningful shape it uses:

```ts
type UsersForPasswordReset = {
  readonly findActiveByEmail: (
    email: EmailAddress,
  ) => Promise<UserLookupResult>
}
```

A wider `PostgresUsers` adapter can satisfy this shape structurally. The consumer stays narrow without forcing one-method adapter proliferation.

Use a named interface or type when it communicates a stable seam. Inline a tiny shape when naming it would add no domain meaning. A narrow shape must still be semantically complete: include the failure, consistency, transaction, and lifecycle behavior the caller relies on, not only the method signature.
