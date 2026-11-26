---
name: principle-test-capabilities
description: Test capabilities through their public contracts and real production composition. Use when writing, reviewing, keeping, or reducing tests, choosing test boundaries, or substituting dependencies.
---

# Test Capabilities

## Rules

- Test what a capability promises through the closest public boundary that owns the behavior. Keep its relevant production composition real and control genuine external dependencies.
- Assert caller-observable outcomes: values, failures, readable state, messages, protocol requests, or resource lifecycle. Derive expectations independently from the implementation.
- Choose substitutes by the semantics the claim depends on, including persistence, ordering, concurrency, retries, and cleanup. Keep inexpensive, deterministic internal collaborators real.
- Add evidence for a distinct consequential failure; optimize confidence and feedback cost rather than test count, coverage percentage, or a fixed testing pyramid.
- Keep scenario-defining inputs, actions, and expectations visible together. Construct valid domain values through production constructors or parsers; generate invalid categories deliberately.

## Constraints

- Do not replace internal domain behavior or layer wiring with mocks merely because dependencies are injectable. Do not use module replacement as the default seam.
- Do not export internals or introduce services, layers, or abstractions solely to spy on implementation details.
- Do not freeze internal call order or counts. Exact interactions are valid evidence when the interaction itself is the public contract.
- Do not trade away distinct risk coverage to reduce a suite, or repeat the same behavioral proof at every layer.
- Keep routine suites deterministic; control clocks, randomness, and synchronization, and invoke live external evaluations separately.

## Knowledge Boundaries

A capability is behavior offered to consumers, such as placing an order or loading configuration. Its public boundary is a supported consumer interface, not every exported symbol or necessarily the entire application. A pure domain operation can be a capability; no particular language, effect system, service shape, or layer count is required.

Applies to observable contracts, production composition, test fidelity, evidence selection, and readable scenarios. Test-runner APIs, red-green-refactor workflow, CI orchestration, coverage thresholds, and benchmarking are outside this principle.

## Patterns

Judge each test against two changes: breaking the promised behavior must fail it; rearranging internals while preserving that behavior must leave it passing.

Exercise domain rules and application orchestration through their real composition. In an effect system, supply controlled external capabilities while retaining the relevant production layers, failure handling, scopes, and cancellation behavior. Broaden to an adapter, runtime, API, CLI, UI, or deployed journey when a named guarantee belongs there.

Strengthen an existing scenario when it answers the same confidence question clearly. Add focused examples or contract-grounded properties for distinct laws, preserving canonical examples and rejecting vacuous properties.

## Gotchas

- Mocking each service leaves only configured answers flowing through configured expectations. Assemble the relevant production capability and substitute true external edges.
- Treating public-contract testing as a full-stack requirement makes every assertion expensive and fragile. Use the closest composition that owns the claimed guarantee.
- Treating every exported function as a separate obligation duplicates proof and penalizes refactoring. Require a distinct contract or consequential risk.
- A substitute that omits relevant constraints, ordering, retries, or cleanup admits impossible production behavior. Raise fidelity or exercise the real resource owner.
- Expected values computed with production logic can share its defect. State outcomes independently and confirm the test detects the intended break.
- Broad fixtures, nested hooks, or flag-heavy helpers hide why a scenario behaves differently. Keep causal details local and extract narrow mechanics or lifecycle cleanup.

## References

- [`references/test-levels-and-evidence.md`](./references/test-levels-and-evidence.md): Read when: choosing test level, reducing redundant proof, or separating deterministic suites from live evaluation.
- [`references/seams-substitutes-and-interactions.md`](./references/seams-substitutes-and-interactions.md): Read when: composing effect or service layers, replacing collaborators, or asserting interactions and lifecycle behavior.
- [`references/persistence-and-generated-data.md`](./references/persistence-and-generated-data.md): Read when: choosing database fidelity or constructing and generating domain values.
- [`references/readable-self-contained-tests.md`](./references/readable-self-contained-tests.md): Read when: designing fixtures, helpers, shared hooks, parameterized examples, or independent expectations.
