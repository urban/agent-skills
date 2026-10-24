---
name: effect-optic
description: Choose Effect Optic focus, absence, no-op, traversal, and iso semantics for reusable immutable domain transitions. Use when nested updates, union variants, optional fields, records, arrays, schema classes, or custom types make ordinary spreads error-prone.
---

## Rules

- Use optics for repeated or semantically meaningful focus paths; keep one-off shallow updates simple.
- Name reusable optics or domain transitions near the type they update.
- Choose explicitly whether a missing focus is a no-op, a returned failure, or domain absence.
- Enter custom prototypes and schema-backed types through a lawful iso rather than plain-object path updates.

## Constraints

- Optics remain pure: no I/O, service lookup, logging, or untrusted decoding inside modifiers.
- A custom iso must be lossless in both directions for the represented domain.
- Optic failures are structured `SchemaIssue.Issue` values; translate them to stable domain errors rather than exposing formatter text as a service contract.

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

Failure modes this knowledge helps avoid:

- silently accepting a required update that found no focus
- treating read-side checks as write-side invariant enforcement
- losing representation invariants or confusing a failed traversal with no matches

## Patterns

- Choose `.at(key)` for update-only-if-present semantics on records or arrays; choose `.optionalKey(key)` when insertion and deletion are intended. `.key(key)` can also represent an optional field whose absence reads as `undefined`.
- Narrow unions by tag/refinement to make the transition apply only to the intended variant.
- Use `.modify` for conditional transitions. `.replace` falls back on reported write failure, but a Prism's source-free replacement can construct a value even when the source does not match. Use `getResult`/`replaceResult` when failure is actionable.
- Treat `.check` as focus selection, not replacement validation; enforce domain invariants in the transition or at a schema boundary.
- Use `.modifyAll` for element-wise traversal updates; `.modify` transforms the collected array. Collection resizing belongs outside a filtered traversal.
- Test domain absence, rejected transitions, traversal cardinality, and representation round trips as described in the references.

## Gotchas

- A required business update implemented with `.modify` can silently do nothing when focus fails. Use explicit Results and map failure to a domain decision.
- A Prism's `.replace` is construction, not a presence check. Use `.modify` or an explicit read when a wrong variant must remain unchanged.
- A successful check on the old value does not validate the replacement; an update can leave the checked subset. Validate the proposed state separately when that subset is an invariant.
- `.optionalKey(index).replace(undefined, array)` splices and shifts later elements; use `.key(index)` when an explicit `undefined` slot is intended.
- Plain path replacement through a class instance throws rather than reconstructing the class. Enter through a representation-aware iso; `replaceResult` does not catch arbitrary exceptions.
- `Optic.getAll` returns `[]` for both no matches and failed outer focus. Use traversal `getResult` when those have different business meanings.
- Equal-value updates may still allocate. Test state values and deliberate sharing contracts, not reference identity as a universal no-op signal.

## References

- [`references/focus-and-absence.md`](./references/focus-and-absence.md): Read when: choosing key/index/optional/union/refinement focus or no-op versus failure semantics.
- [`references/traversals-isos-and-tests.md`](./references/traversals-isos-and-tests.md): Read when: updating many focuses, handling schema classes/newtypes/custom structures, or designing optic tests.
