---
name: effect-best-practices
description: Apply Effect-specific design judgment for capability boundaries, runtime ownership, failure contracts, replay safety, and behavioral evidence. Use when writing, refactoring, or reviewing Effect code and the decision goes beyond API usage or TypeScript style.
---

## Rules

- Use `typescript-best-practices` for general TypeScript guidance, resolving that skill by name through the host's skill discovery. Extend it with Effect-specific contracts and ownership decisions here; let Effect-native representations and library conventions specialize the language defaults.
- Choose abstractions from caller needs and runtime ownership. A module, an Effect-returning function, a service, and a public facade solve different problems.
- Keep application policy with the capability that understands its meaning. Composition selects implementations and lifetimes; it must not become a second implementation of domain behavior.
- Read the applicable principle leaves and the topic owning the current decision. Add another topic only for a separate substantive question; do not load the whole library.

## Constraints

- Do not infer product requirements from a library feature, example, or default. Preserve the project's accepted contracts and architecture.
- Do not prescribe workflows, deliverables, new dependencies, or configuration changes merely to apply these standards.
- Do not reproduce API manuals, constructor catalogs, framework setup, or behavior directly answerable from Effect's documentation, source, and tests. Keep this skill focused on choosing the intended application behavior among valid implementations.

## Knowledge Boundaries

This skill owns Effect-specific architectural preferences and tradeoffs that can remain wrong after code compiles: capability cohesion, captured identity, resource ownership, public failure vocabulary, replay boundaries, and evidence for those contracts.

Effect itself owns API facts. Start with the consuming project's `.dotai/repos/effect/LLMS.md` when available, then follow only the relevant documentation and source/test links. Resolve another checkout location from project guidance. Confirm that it matches the installed packages; installed definitions and implementation determine available behavior when versions differ. If no checkout is available, use the installed package's available documentation and source rather than inventing signatures or requiring a new clone.

General TypeScript style belongs to `typescript-best-practices`; framework-neutral architecture and project execution policy belong to their existing owners. These standards apply inside implementation, review, and design tasks without introducing an ordered procedure.

When available, use `project-hygiene` for compiler and diagnostic policy, module ownership, and Node type-stripping compatibility; use `principle-test-capabilities` for general test boundaries, composition, and substitute fidelity. Resolve companion skills by name through host discovery; the testing topic here specializes evidence for Effect semantics.

## Patterns

### Select internal principles

Read each applicable leaf before applying it. Explain a consequential choice it changed when useful; do not report principle scores or recite the index.

| Principle | Read when |
| --- | --- |
| [Capabilities follow callers](principles/capabilities-follow-callers.md) | Read when: choosing an ordinary function, service, facade, or public surface. |
| [Ownership before wiring](principles/ownership-before-wiring.md) | Read when: choosing dependency capture, sharing, scope, or background-work authority. |
| [Failures follow recovery](principles/failures-follow-recovery.md) | Read when: deciding which failures become part of a caller's contract. |
| [Replay follows intent](principles/replay-follows-intent.md) | Read when: retries, reconnects, duplicate delivery, or durable work can repeat effects. |
| [Evidence follows the claim](principles/evidence-follows-the-claim.md) | Read when: choosing a test seam, fake, or evidence for a semantic guarantee. |

### Select the primary topic

Choose by the decision, not every package imported by the code. A test accompanying an HTTP change does not automatically require the testing topic.

| Topic | Read when |
| --- | --- |
| [Application architecture](topics/application-architecture.md) | Read when: capability topology, service granularity, public exports, or composition placement is the decision. |
| [Lifetime and isolation](topics/lifetime-and-isolation.md) | Read when: deciding who owns resources, dependency identity, activation, or concurrent work. |
| [Representations and failures](topics/representations-and-failures.md) | Read when: domain/wire compatibility, absence, transitions, or public errors need a policy. |
| [External integrations](topics/external-integrations.md) | Read when: defining an HTTP, SDK, or platform adapter's responsibility and guarantees. |
| [Streams](topics/streams.md) | Read when: delivery, loss, ordering, recovery, or subscription semantics need a decision. |
| [Reactive state](topics/reactive-state.md) | Read when: choosing cache identity, stale-data behavior, or optimistic mutation policy. |
| [Durable execution](topics/durable-execution.md) | Read when: entity coordination, durable orchestration, persisted protocols, or recovery is required. |
| [AI capabilities](topics/ai-capabilities.md) | Read when: choosing domain behavior, provider equivalence, tool authority, or model failure policy. |
| [Observability](topics/observability.md) | Read when: deciding operator-visible boundaries, telemetry failure policy, or audit requirements. |
| [Testing](topics/testing.md) | Read when: test boundaries, replacement fidelity, deterministic coordination, or property laws are the primary question. |

## Gotchas

- Turning every Effect-returning function into a service replaces domain structure with construction structure. Introduce service identity when it owns meaningful configuration, state, resources, or replacement.
- Hiding an implementation module does not hide a dependency mentioned in public requirements or errors. Design the entire caller contract, including what callers must provide and recover from.
- Moving provision inward to make a type disappear can change sharing and lifetime. Name the intended owner before changing the graph.
- A library's retryable classification does not establish permission to repeat a business action. Define logical operation identity and uncertain-outcome handling at the domain boundary.
- A convincing fake can omit the property being claimed. Use it for the behavior it preserves and choose evidence at the owning runtime or protocol when the guarantee crosses that seam.
