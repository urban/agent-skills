---
name: denotational-design
description: Write denotational architecture and API specs that define domain types by precise mathematical meaning, compositional operations, semantic equality, and laws before implementation. Use when designing abstractions, implementation specs, agent handoff docs, or reviewing APIs for representation leaks.
---

## Rules

- Define meaning before mechanism because representation-first specs hard-code accidents as architecture.
- Introduce a domain type only when it has a clear semantic model such as a set, function, relation, tuple, algebra, or state transition system.
- Write a meaning function `μ : Type -> Model` for every core domain type before naming fields, storage, algorithms, or classes.
- Define each operation by `μ(operation arguments)` using only the meanings of its arguments and explicitly modeled context.
- Treat equality as semantic equality because pointer equality, serialized shape, and operational trace are usually representation details.
- Prefer standard algebraic structures when the model actually satisfies their laws, because lawful vocabularies make specs smaller and easier to verify.
- Mark failed compositionality as an abstraction leak instead of explaining it away.
- Use [`assets/denotational-spec-template.md`](./assets/denotational-spec-template.md) when producing a spec artifact.
- Record unresolved high-impact interpretation as `TODO: Confirm` instead of inventing denotations.

## Constraints

- Do not start by proposing data structures, database tables, endpoints, classes, queues, or algorithms.
- Do not define an operation using private representation, mutation order, cache state, wall-clock time, global configuration, or caller identity unless that context is part of the semantic model.
- Do not force Functor, Monoid, Applicative, Category, or other algebraic labels when the required laws cannot be stated over semantic equality.
- Do not claim deterministic verification unless the spec includes laws, example properties, or observable checks derived from the denotation.
- Do not use denotational design to replace product requirements; use it after the behavior boundary and domain vocabulary are known enough to model.

## Requirements

Inputs:

- domain goal, architecture question, API surface, or existing spec to review
- known domain vocabulary and behavior boundaries
- non-functional constraints that affect meanings, such as ordering, consistency, time, identity, privacy, or failure semantics
- target artifact path or response-only handoff preference when known

Outputs:

- denotational spec using [`assets/denotational-spec-template.md`](./assets/denotational-spec-template.md)
- core domain types with `Model` and `μ` definitions
- operations defined compositionally over models
- semantic equality and laws or explicit reasons they do not apply
- abstraction leaks, representation constraints, and `TODO: Confirm` items

In scope:

- designing architecture/API abstractions before implementation
- refactoring vague specs into precise mathematical contracts
- reviewing existing APIs for representation leakage or ad-hoc operations
- preparing agent handoff docs that separate meaning from implementation

Out of scope:

- product discovery without enough domain behavior to model
- low-level implementation planning before denotations are stable
- performance tuning unless performance changes the semantic contract
- proving formal correctness beyond lightweight laws and checkable properties

Failure modes to prevent:

- replacing meaning with implementation vocabulary
- hiding state, time, identity, or authorization dependencies outside the model
- writing laws over serialized shape instead of semantic equality
- using algebraic terminology as decoration rather than as a law-bearing contract
- producing a polished spec that cannot drive tests, review, or agent decomposition

Routing guidance:

| Task                                          | Read first                                                                       |
| --------------------------------------------- | -------------------------------------------------------------------------------- |
| Choose domain models or write `μ` definitions | [`references/denotational-method.md`](./references/denotational-method.md)       |
| Review laws, equality, and abstraction leaks  | [`references/laws-and-review.md`](./references/laws-and-review.md)               |
| Produce a stable spec artifact                | [`assets/denotational-spec-template.md`](./assets/denotational-spec-template.md) |

## Workflow

1. Confirm the task is a denotational architecture/API/spec task and identify the artifact to create or review.
2. Read local source material when it exists: requirements, current API docs, type definitions, tests, architecture notes, and constraints.
3. Extract candidate domain nouns and behaviors, then keep only types that can be assigned a precise semantic model.
4. For each kept type, define `Model` and `μ : Type -> Model`; mark unclear meanings as `TODO: Confirm`.
5. Define operations by type signature and denotational equation: `μ(op x y ...) = ...` using only `μ(x)`, `μ(y)`, and explicitly modeled context.
6. Define semantic equality for each model and state how observable behavior should respect it.
7. Identify lawful standard structures only after the equations support them; list the laws over semantic equality.
8. Run the abstraction-leak review: find representation dependencies, hidden context, non-compositional operations, and ad-hoc combinators that should be redesigned.
9. Add implementation guidance only after the denotational contract is stable, and label representations as candidates rather than the source of truth.
10. Deliver the spec, review findings, validation properties, and remaining `TODO: Confirm` items.

## Gotchas

- If the spec begins with tables, endpoints, or classes, later “abstractions” merely rename implementation details. Start again from domain meanings and let representation appear only after the equations are stable.
- If `μ` is missing for a type, agents fill the gap with examples and prose, then disagree about edge cases. Give every core type a model or mark the type as `TODO: Confirm`.
- If an operation mentions cache state, current time, authorization, retries, or ordering without modeling that context, the denotation is lying. Add the context to the model or split the operation.
- If equality is defined by JSON shape, object identity, or event ordering when users only care about meaning, harmless implementation changes become breaking changes. Define equality at the model level first.
- If algebraic names are added because they sound elegant, reviewers inherit fake guarantees. State the laws and remove the label when the model cannot satisfy them.
- If a non-compositional operation is kept for convenience, downstream agents cannot verify local changes because meaning depends on hidden representation. Treat the failure as a design signal and redesign the abstraction boundary.
- If the skill relies on external articles or talks to explain a concept, agents lose the critical context when offline or when links rot. Inline the smallest useful example and keep citations out of execution-critical guidance.
- If the final artifact lacks checkable properties, implementation agents translate the spec back into preferences. Add laws, examples, or observable invariants that can become tests or review criteria.

## Deliverables

- a denotational spec or review using [`assets/denotational-spec-template.md`](./assets/denotational-spec-template.md)
- explicit domain types, models, and `μ` definitions
- compositional operation equations and semantic equality rules
- lawful algebraic structures or rationale for omitting them
- inline examples or local diagrams for non-obvious denotations
- abstraction leaks, implementation constraints, validation properties, and `TODO: Confirm` items

## References

- [`references/denotational-method.md`](./references/denotational-method.md): Read when: selecting models, writing meaning functions, decomposing types, or translating vague domain nouns into semantic objects.
- [`references/laws-and-review.md`](./references/laws-and-review.md): Read when: assigning algebraic structures, defining semantic equality, reviewing compositionality, or deriving validation properties.

## Validation Checklist

- the task has enough domain behavior to model, or missing behavior is marked `TODO: Confirm`
- every core type has a `Model` and `μ : Type -> Model`
- every operation has a type signature and denotational equation
- operation meanings depend only on argument meanings and explicitly modeled context
- equality is semantic, not representation-based by default
- laws are stated only for structures the model supports
- abstraction leaks and ad-hoc operations are called out rather than hidden
- implementation notes do not precede or override the denotational contract
- output includes validation properties that can guide tests or review
- denotational-design files and generated specs avoid external links in favor of inline examples or local bundled resources
