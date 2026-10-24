---
name: effect-fast-check
description: Design property tests for Effect behavior by choosing meaningful laws, valid generators, schema-derived arbitraries, model-based state, shrinking boundaries, and deterministic services. Use when examples cannot cover the relevant input or transition space.
---

## Rules

- Use a property only when the behavior has a law that should hold across many inputs or command sequences.
- Keep one named law per property so a shrunk counterexample identifies the broken contract.
- Generate valid domain values directly; generate invalid classes deliberately when testing rejection.
- Exercise Effect behavior through Effect-aware property tests and replace nondeterministic boundaries.
- Make each evaluation repeatable, including shrink attempts: own mutable fixtures inside the property and treat generated inputs as immutable.

## Constraints

- Generator constraints must reflect the domain or a documented performance bound, not merely make the test pass.
- Stateful properties need fresh system/model state for every evaluation, not just each initially generated case.
- Live providers, networks, random side channels, and wall-clock time do not belong in deterministic properties.

## Knowledge Boundaries

Applies to:

- invariants, round trips, idempotence, ordering, commutativity, monotonicity, and error classification
- Effect v4 native `Arbitrary` and `@effect/vitest` properties, schema-derived and custom generators
- state-machine/model-based properties for Effect services
- shrinking, run-count, and deterministic-layer decisions

Does not cover:

- generic example-test design
- fuzzing without a named behavioral oracle

Decision inputs:

- law and observation boundary
- valid and invalid input spaces
- cost per generated case and shrink behavior
- state reset and external services required

Failure modes this knowledge helps avoid:

- confusing decoded domain values with accepted wire representations
- shrinking against state left behind by earlier evaluations
- mistaking generator exhaustion or a returned check result for a passing law

## Patterns

- Keep examples for canonical cases and properties for general laws; neither replaces the other.
- Derive generators from schemas when the schema defines the valid space. Schema inputs generate decoded values; wire-format and rejection properties need their own input spaces.
- Construct related inputs directly instead of discarding most generated cases with filters or preconditions.
- For codecs, state the promised law precisely: decode-encode normalization, encode-decode identity, or full losslessness are different properties.
- For stateful services, generate commands and compare observable results with a simpler model, rebuilding both for every evaluation.
- Tune run count after measuring cost and failure value; expensive integration-shaped properties need fewer, sharper cases than pure laws.

## Gotchas

- A model that copies the production algorithm can agree with the same bug; use a simpler representation or independently observable invariant.
- Heavy filtering exhausts generation and wastes shrinking effort; construct the constrained space rather than merely raising discard limits.
- Over-constrained generators hide domain boundaries; retain explicit examples for important extremes and rejection classes.
- Combining unrelated laws obscures what a shrunk failure means; name and isolate each behavioral contract.
- Shared mutable layers or mutated generated arrays make shrinks depend on earlier evaluations; rebuild fixtures and copy inputs before destructive operations.
- A schema-derived property over a codec exercises decoded values, not every accepted spelling; generate noncanonical wire forms separately.
- Exact wire round trips fail under intentional normalization; assert canonicalization or domain equivalence instead of assuming full losslessness.
- A replay token reproduces generation and shrinking, not external state or execution schedules; keep deterministic boundaries and preserve a concrete regression example.

## References

- [`references/properties-and-arbitraries.md`](./references/properties-and-arbitraries.md): Read when: selecting a law, schema-derived arbitrary, custom generator, or round-trip direction.
- [`references/effectful-and-stateful-properties.md`](./references/effectful-and-stateful-properties.md): Read when: testing services, typed failures, state machines, time, streams, or other Effectful properties.
