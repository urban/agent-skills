---
name: denotational-design
description: "Apply a lightweight denotational-design pass before coding or reviewing abstractions: define domain meanings, semantic equality, operations, and laws before representation. Use when designing APIs, data types, DSLs, state models, refactors, or reviewing abstractions for representation leaks."
---

## Rules

- Define meaning before mechanism because representation-first work turns incidental storage or control flow into the API contract.
- Model each core type as a simple semantic object such as a set, function, relation, tuple, state, event trace, or state transition.
- State the meaning function informally as `meaning(value) = ...` unless formal notation would be clearer.
- Define operations by how they transform meanings, not by how they mutate fields, call services, or traverse data.
- Define semantic equality before choosing serialized shape, object identity, ordering, or caching behavior.
- State laws or invariants only when they follow from the meaning and can guide tests or review.
- Treat hidden time, identity, authorization, ordering, failure, randomness, and external I/O as part of the semantic model when they affect behavior.
- Add implementation notes only after the denotational contract is clear.

## Constraints

- Do not use algebraic or category-theory labels unless the relevant laws are stated plainly.
- Do not invent meanings for unclear product behavior; mark them `TODO: Confirm`.
- Do not replace requirements discovery with denotational design; use it when the behavior boundary is known enough to model.
- Do not make representation details normative unless the user-facing meaning requires them.

## Requirements

Inputs:

- the abstraction, API, type, state model, DSL, or refactor under design or review
- known domain behavior and boundaries
- constraints that affect meaning, especially time, order, identity, failure, consistency, permissions, privacy, or nondeterminism

Outputs:

- core types with concise meanings
- semantic equality rules
- operation meanings over those semantic models
- laws, invariants, or checkable properties when useful
- representation notes, abstraction leaks, and `TODO: Confirm` items

In scope:

- lightweight architecture and API design before implementation
- reviewing existing abstractions for representation leaks
- deriving testable properties from meanings
- clarifying what changes are semantic versus representational

Out of scope:

- full formal verification
- broad product discovery
- low-level implementation planning before meanings are stable
- performance work unless performance changes observable meaning

## Workflow

1. Decide whether the task needs denotational design: use it for abstractions whose meaning must stay stable across implementations.
2. Read existing requirements, code, types, tests, or docs if available.
3. List only the core domain concepts that need stable meaning; skip incidental helpers.
4. For each core type, write `meaning(Type) = ...` using a simple semantic model.
5. Define semantic equality: when do two values mean the same thing, regardless of representation?
6. Define each operation by its effect on meanings: `meaning(op(args)) = ...`.
7. Call out hidden context that affects meaning, then either include it in the model or mark it as a leak.
8. Add laws, invariants, and example properties only where they are useful for implementation or review.
9. After meanings are stable, add representation and implementation notes as non-normative guidance.
10. Deliver a concise denotational pass using this shape:

```md
## Denotational Design

### Types and meanings

- `Type`: `meaning(Type) = ...`

### Semantic equality

- `Type`: two values are equal when ...

### Operations

- `operation(args) -> Result`: `meaning(result) = ...`

### Laws / invariants

- ...

### Representation notes

- ...

### TODO: Confirm

- ...
```

## Gotchas

- If the design starts with tables, classes, JSON, or endpoints, agents tend to preserve accidental shape as the abstraction. Restart from domain meaning, then reintroduce representation as an implementation option.
- If a type lacks a meaning, examples silently become the spec and edge cases drift. Give the type a model or mark the missing behavior `TODO: Confirm`.
- If equality is based on object identity, insertion order, or serialization when users only care about meaning, harmless refactors become breaking changes. Define semantic equality first.
- If an operation depends on current time, permissions, retries, cache state, randomness, or external services without modeling that dependency, the denotation is incomplete. Add the context or split the operation.
- If algebraic names are added for style, downstream agents infer guarantees that were never promised. State the actual law or remove the label.
- If representation notes appear before operation meanings, implementation agents optimize the wrong thing. Move implementation details after the denotational contract.
- If the output has no invariants or examples, the design is hard to test. Add a small set of properties derived from the meanings.

## Deliverables

- a concise denotational design section or review note
- core type meanings and semantic equality
- operation meanings stated over semantic models
- useful laws, invariants, or properties
- representation notes that do not override meaning
- explicit abstraction leaks and `TODO: Confirm` items

## Validation Checklist

- each core type has a stated meaning or `TODO: Confirm`
- semantic equality is defined before representation details
- each core operation is defined by its effect on meanings
- hidden context that affects behavior is modeled or called out
- laws and invariants are plain, useful, and not decorative
- implementation notes are secondary to the denotational contract
- the result is concise enough to guide an agent before coding or review
