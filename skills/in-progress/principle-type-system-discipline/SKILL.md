---
name: principle-type-system-discipline
description: 'Apply when designing types, reviewing component APIs or function signatures, or parsing external data in a statically typed language. Encode valid states, distinguish semantic values, derive types from authoritative contracts, and handle variants exhaustively.'
disable-model-invocation: true
---

# Type System Discipline

Make the compiler reject impossible states, mismatched semantic values, and unhandled variants.

- **Model valid combinations.** Use explicit variants for mutually exclusive modes and require dependent values together. Avoid independent booleans and optional fields that admit contradictory states.
- **Distinguish semantic primitives.** Use distinct or branded types when interchanging otherwise identical primitives would be a domain error. Validate at creation.
- **Use one bidirectional schema per boundary contract.** Treat the schema or codec as the source of truth for both the boundary representation and its domain value. Decode and validate on input; encode on output. Apply this to CLI arguments, environment variables, config files, RPC, persistence, and other boundaries.
- **Keep editing drafts separate from domain values.** A draft may be incomplete or invalid while someone is editing it. Decode it into a validated domain value when it’s ready to apply or submit.
- **Derive from the authority.** Infer types from the owning schema or contract instead of maintaining parallel shapes. Handle every variant; avoid assertions that conceal missing guarantees.

Verify important rejected combinations with compile-time checks. Static completeness does not establish runtime validity or visual correctness.

For TypeScript syntax, see the **typescript-best-practices** skill.
