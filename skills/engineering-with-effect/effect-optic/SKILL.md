---
name: effect-optic
description: Choose Effect Optic focus, absence, no-op, traversal, and iso semantics for reusable immutable domain transitions. Use when nested updates, union variants, optional fields, records, arrays, schema classes, or custom types make ordinary spreads error-prone.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Use optics for repeated or semantically meaningful focus paths; keep one-off shallow updates simple.
- Name reusable optics or domain transitions near the type they update.
- Choose explicitly whether a missing focus is a no-op, a returned failure, or domain absence.
- Enter custom prototypes and schema-backed types through a lawful iso rather than plain-object path updates.

## Constraints

- Optics remain pure: no I/O, service lookup, logging, or untrusted decoding inside modifiers.
- A custom iso must be lossless in both directions for the represented domain.
- Raw optic failure text is implementation detail; map it before exposing a service contract.

## Knowledge Boundaries

Applies to:

- required, optional, indexed, record, union, refined, and traversal focuses
- replace/modify versus result-returning operations
- optional deletion/preservation and custom-type isos
- pure transition and service-boundary tests

Does not cover:

- generic immutability style or service architecture
- cases where direct access or object spread is clearer

Decision inputs:

- focus cardinality and possible absence
- business meaning of missing focus
- optional-key deletion versus explicit undefined
- plain structure versus class/newtype/custom representation

## Patterns

- Use required-field focus only when the field is structurally guaranteed. Use index/key focus that models absence when records or arrays may not contain the target.
- Narrow unions before focusing variant fields.
- Use plain replace/modify for intentional best-effort no-op behavior. Use result-returning reads/updates when absence is actionable.
- Distinguish preserving an optional key with undefined from deleting/splicing it; pick the optic that matches domain absence.
- Use traversal element modification when changing each focus; do not accidentally transform the collected array as one value.
- Test present and absent focus, wrong union variant, failed refinement, optional deletion/preservation, and custom-type round trips.

## Gotchas

- A required business update implemented with no-op semantics can silently report success while changing nothing.
- Dynamic record keys and array indexes modeled as required focuses misrepresent absence.
- Focusing a union before narrowing either fails typing or produces ambiguous behavior.
- Plain path updates over class instances can lose construction/prototype semantics.
- Traversal modify and modify-all operations have different targets; confusing them changes arrays rather than elements.
- Relying on reference identity to detect no-op updates is unsafe when an optic may allocate while preserving value equality.

## References

- [`references/focus-and-absence.md`](./references/focus-and-absence.md): Read when: choosing key/index/optional/union/refinement focus or no-op versus failure semantics.
- [`references/traversals-isos-and-tests.md`](./references/traversals-isos-and-tests.md): Read when: updating many focuses, handling schema classes/newtypes/custom structures, or designing optic tests.
