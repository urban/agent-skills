---
name: codebase-architecture
description: Design framework-neutral TypeScript architecture around deep domain and application modules, narrow dependency seams, cohesive adapters, explicit composition roots, persistence boundaries, thin entrypoints, and transaction or idempotency policy. Use when deciding framework-neutral module boundaries, dependency seams, runtime assembly, persistence ownership, or transaction policy.
---

## Rules

- Preserve correctness, safety, and debuggability first; then follow established project architecture, improve the local design, and avoid unrelated migrations.
- Inspect existing domain types, modules, services, adapters, persistence conventions, error handling, tests, and observability before introducing another pattern or dependency.
- Build deep modules that hide meaningful behavior and invariants behind a cohesive, low-burden interface.
- Keep domain modules focused on valid values and pure behavior; keep application modules focused on capabilities that coordinate dependencies and effects.
- Let a consumer depend on the smallest meaningful capability it uses while allowing a wider concrete adapter to satisfy that structural shape.
- Audit existing adapters before creating one: reuse when possible, extend when the capability remains cohesive, and create a new adapter only for a genuinely separate reason to change.
- Keep transport, framework, ORM, and provider representations at their owning edge; parse them into domain values before application logic uses them.
- Keep entrypoints thin and place authorization and business policy in shared application or domain modules.
- Choose ordinary calls, a database transaction, or a durable workflow from the actual atomicity, duration, retry, and recovery requirements.

## Constraints

- Do not force a broad architecture migration while delivering an unrelated local change.
- Do not keep a database transaction open across a network call, human wait, timer, or other long-running operation.
- Do not create an adapter per table, SDK method, or call site unless those are genuinely cohesive capabilities.
- Do not duplicate business or authorization rules across HTTP handlers, resolvers, CLI commands, and workers.
- A retryable state change must have idempotency or deduplication, unless the operation is demonstrably repeat-safe by its semantics.

## Knowledge Boundaries

Applies to:

- deep module and seam placement
- domain versus application module responsibilities
- dependency shape, adapter reuse, and persistence design
- composition roots, runtime dependency assembly, and resource ownership
- entrypoint translation, shared authorization, transactions, workflows, and idempotency

Does not cover:

- TypeScript expression style, compiler flags, imports, or file hygiene
- test-level selection and mocking policy
- framework-specific API syntax or a step-by-step architecture migration

Decision inputs:

- established project vocabulary and module conventions
- invariants and caller decisions the interface must preserve
- existing adapters and their cohesive reasons to change
- executable boundaries, configuration sources, and resource lifetimes
- transaction boundaries, retry sources, durability needs, and external side effects

Failure modes this knowledge helps avoid:

- pass-through modules that add names without hiding complexity
- duplicate adapters and repositories that fragment one capability
- ORM, protocol, or authorization policy leaking into every caller
- unsafe retries and transactions spanning unreliable boundaries

## Patterns

- Use the deletion test: if deleting a module makes complexity disappear, it was probably pass-through; if the complexity spreads across callers, the module was earning its keep.
- Center a domain module on one value or tightly related family, with its parsers, smart constructors, transitions, predicates, formatting, and other cohesive pure operations.
- Give an application module a domain capability name such as `PasswordReset` or `SubscriptionLifecycle`; inject dependencies once rather than passing a generic dependency bag through every call.
- Let the consuming module declare a narrow structural dependency. Do not split the concrete adapter merely to make its interface textually identical to each consumer shape.
- Treat raw rows and ORM entities as infrastructure DTOs. Persistence adapters expose meaningful domain operations, parsed values, and caller-actionable failures.
- Before adding a meaningful adapter, record what was inspected and why reuse or extension would create bad coupling. Preserve the decision in the repository's established ADR or decision-log format when the choice is difficult to reverse or surprising without context.
- Parse and authenticate at an entrypoint, then pass a domain-specific principal such as `Session`, `AdminUser`, or `CommandActor` to shared policy.
- For retryable state changes that are not inherently repeat-safe, use an idempotency key, natural unique constraint, deduplication record, guarded state transition, or transactional outbox/inbox where duplicates can occur.

## Gotchas

- If a wrapper mirrors every dependency method, callers learn the wrapper and the dependency while gaining no locality. Move normalization, policy, or invariants behind it, or remove it.
- If an agent creates a new adapter before inspecting existing ones, one remote system acquires several inconsistent error, retry, and telemetry policies. Reuse or cohesively extend the existing owner first.
- If repository methods return ORM rows, schema and storage changes propagate into application logic. Decode at the persistence seam and return domain values.
- If controllers enforce authorization independently, a CLI or worker eventually bypasses a rule. Authenticate at the edge but keep authorization decisions in shared policy.
- If a network call occurs inside a database transaction, latency and partial failure hold locks while atomicity still stops at the network. Commit local intent and coordinate the external effect separately.
- If every retry generates a new identity, at-least-once delivery becomes duplicate business action. Derive identity from the logical command and enforce it at the state-changing boundary.
- If every new adapter demands process ceremony, trivial fakes and framework glue become slower than the risk warrants. Reserve durable rationale for meaningful, non-obvious capability seams.

## References

- [`references/modules-and-dependencies.md`](./references/modules-and-dependencies.md): Read when: deciding module depth, domain versus application ownership, class use, dependency injection, or split criteria.
- [`references/adapters-and-persistence.md`](./references/adapters-and-persistence.md): Read when: reusing or creating an adapter, shaping consumer dependencies, designing repositories, or recording a seam decision.
- [`references/composition-and-runtime-ownership.md`](./references/composition-and-runtime-ownership.md): Read when: assembling an executable or runtime, deciding who constructs configuration and resources, or hiding infrastructure behind a public application surface.
- [`references/entrypoints-transactions-and-idempotency.md`](./references/entrypoints-transactions-and-idempotency.md): Read when: sharing behavior across entrypoints, placing authorization, selecting transactions versus workflows, or making retries safe.
