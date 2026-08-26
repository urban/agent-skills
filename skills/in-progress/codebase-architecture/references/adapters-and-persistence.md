# Adapters and persistence

## Adapter reuse decision

Before creating a production adapter or service:

1. Search for existing owners of the dependency or capability.
2. Reuse an existing adapter through a narrow consumer-owned shape when its behavior already fits.
3. Extend the existing adapter when the operation shares its protocol, policy, dependencies, and reason to change.
4. Create a separate adapter when reuse or extension would merge unrelated capabilities, lifetimes, security policy, or deployment ownership.

Do not confuse a consumer's narrow dependency with a requirement for a separate concrete adapter. Structural typing lets one cohesive implementation satisfy several narrow consumers.

Record a durable decision only when the new seam is meaningful: difficult to reverse, surprising without rationale, or selected after a real trade-off. Follow the repository's existing ADR or decision-log convention. Capture:

- existing adapters and services inspected
- why direct reuse did not fit
- why extension would reduce cohesion or create coupling
- the independent capability owned by the new adapter
- consequences and known risks

Tiny test adapters, obvious in-memory substitutes, and trivial framework glue normally do not justify an ADR.

## Persistence capability

Avoid repository-per-table as a default. A repository or persistence adapter should represent a cohesive domain storage capability and expose operations callers actually need, such as reserving an identifier, loading an aggregate, or atomically recording a transition.

Keep these inside the persistence implementation:

- SQL and query builders
- ORM entities and relation-loading rules
- migration-era column compatibility
- transaction and isolation mechanics
- database error codes

Return parsed domain values and caller-actionable failures. Preserve safe diagnostic causes where operators need them, but do not make every caller interpret raw rows, driver errors, or ORM exceptions.

## Representation boundary

Treat raw rows and ORM models as infrastructure DTOs. Decode or construct domain values before they cross into application logic. This catches corrupt or legacy data at the boundary and prevents storage optionality from becoming domain optionality.

A persistence substitute must preserve the semantics under test. Use a real local database when behavior depends on SQL, constraints, isolation, transactions, or query ordering; an in-memory map is suitable only when those details are irrelevant to the capability contract.
