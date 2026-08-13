---
name: effect-fast-check
description: Design property tests for Effect behavior by choosing meaningful laws, valid generators, schema-derived arbitraries, model-based state, shrinking boundaries, and deterministic services. Use when examples cannot cover the relevant input or transition space.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Use a property only when the behavior has a law that should hold across many inputs or command sequences.
- Keep one named law per property so a shrunk counterexample identifies the broken contract.
- Generate valid domain values directly; generate invalid classes deliberately when testing rejection.
- Exercise Effect behavior through Effect-aware property tests and replace nondeterministic boundaries.

## Constraints

- Generator constraints must reflect the domain or a documented performance bound, not merely make the test pass.
- Stateful properties need a fresh system/model state for each generated run.
- Live providers, networks, random side channels, and wall-clock time do not belong in deterministic properties.

## Knowledge Boundaries

Applies to:

- invariants, round trips, idempotence, ordering, commutativity, monotonicity, and error classification
- schema-derived and custom arbitraries
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

## Patterns

- Keep examples for canonical cases and properties for general laws; neither replaces the other.
- Derive generators from schemas when the schema defines the valid space. Add custom generation only when built-in generation cannot reach useful values efficiently.
- Construct related inputs directly instead of discarding most generated cases with filters or preconditions.
- For codecs, state the promised law precisely: decode-encode normalization, encode-decode identity, or full losslessness are different properties.
- For stateful services, generate commands and compare observable results with a simpler model, rebuilding both per run.
- Tune run count after measuring cost and failure value; expensive integration-shaped properties need fewer, sharper cases than pure laws.

## Gotchas

- A property that reimplements the production algorithm can agree with the same bug.
- Heavy filtering produces few useful cases and poor shrinking; generate the constrained space directly.
- Over-constrained generators omit edge cases that property testing was meant to discover.
- Combining several laws makes the minimal counterexample ambiguous even after shrinking.
- Reusing mutable layer state across generated cases introduces order dependence and invalid shrinks.
- A round-trip assertion can be wrong when normalization is intentional; choose the correct direction and equivalence relation.

## References

- [`references/properties-and-arbitraries.md`](./references/properties-and-arbitraries.md): Read when: selecting a law, schema-derived arbitrary, custom generator, or round-trip direction.
- [`references/effectful-and-stateful-properties.md`](./references/effectful-and-stateful-properties.md): Read when: testing services, typed failures, state machines, time, streams, or other Effectful properties.
