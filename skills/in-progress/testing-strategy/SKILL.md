---
name: testing-strategy
description: Choose a small, high-value black-box-first test strategy for TypeScript systems. Use when deciding acceptance evidence, test levels, suite reduction, collaborator fidelity, persistence setup, property testing, or readable test design.
---

## Rules

- Prefer the smallest reliable set of high-value black-box tests that demonstrates agreed behavior and catches consequential regressions; optimize development speed and confidence, not test count or coverage percentage.
- Default to real application, API, CLI, or UI boundaries that exercise meaningful behavior across internal composition. Black-box does not require a fully deployed environment.
- Assert caller- or user-observable outcomes rather than private implementation, call choreography, or incidental counts.
- Add focused lower-level tests only when they provide important confidence that higher-level tests cannot provide reliably or economically.
- Keep deterministic, inexpensive in-process collaborators real; replace external, destructive, expensive, or nondeterministic boundaries.
- Match each substitute's fidelity to the contract, including relevant transport, persistence, ordering, concurrency, retry, and lifecycle semantics.
- Keep scenario-defining setup, action, and expected outcome visible together, even when that requires controlled repetition.
- Use property tests only for a contract-grounded law that examples cannot cover economically; retain canonical examples and reject vacuous properties.

## Constraints

- Do not require one test per acceptance criterion, one test per function, a fixed testing pyramid, or duplicate coverage at every layer.
- Do not pursue fewer tests by deleting distinct risk coverage or joining unrelated scenarios into one fragile mega-test.
- Do not use module replacement such as `vi.mock` or `jest.mock` as the default seam.
- Do not export internals or rewrite production architecture solely to spy on implementation details.
- Do not claim confidence from a substitute that omits semantics relevant to the test.
- Do not use sleeps, live external services, or uncontrolled randomness in the normal deterministic suite.
- An exact interaction assertion is valid only when that interaction or wire shape is itself the observable contract.
- Do not hide behavior-relevant values or steps behind shared setup, nested hooks, broad fixtures, or generic helpers solely to remove repetition.

## Knowledge Boundaries

Applies to:

- selecting high-value black-box/end-to-end coverage and justified integration, contract, focused, property, or unit supplements
- evaluating redundant coverage, feedback cost, assertion strength, and failure diagnostics
- choosing seams, substitutes, observable evidence, and justified interaction assertions
- protocol and persistence fidelity, deterministic boundary control, and test-data construction
- test readability, scenario locality, and helper or fixture design

Does not cover:

- red-green-refactor workflow
- framework- or runtime-specific test APIs and mechanisms
- coverage thresholds, CI orchestration, or performance benchmarking

Decision inputs:

- observable contract or failure that must be detected
- production semantics that must remain inside the test boundary
- externality, cost, destructiveness, and nondeterminism of collaborators
- scenario details that distinguish this behavior from neighboring cases

## Patterns

- Start from consequential user journeys and failure risks, then choose a compact set of scenarios through real public boundaries. Several related acceptance criteria can share one scenario when failures remain diagnosable.
- Before adding a test, identify the distinct confidence it adds; strengthen an existing scenario when that answers the same question without obscuring it.
- Observe returned values or failures, persisted state, emitted messages, rendered responses, or captured records at a boundary-owned fake.
- Choose a fake for simple semantics, a scripted substitute for response sequences, and a simulator or local service when protocol or runtime behavior matters.
- Escalate persistence fidelity when constraints, migrations, transactions, dialect, locking, isolation, or extensions affect the outcome.
- Keep canonical examples alongside properties. Construct valid data with parsers or smart constructors; generate invalid classes deliberately when testing rejection.
- Permit a spy or exact invocation assertion for a true contract such as HTTP method/path/body, CLI arguments, idempotency key, emitted message, audit record, or mandatory cleanup.
- Extract test mechanics only when a narrow, descriptive helper makes the scenario clearer; keep relevant overrides local and return fresh state.

## Gotchas

- If every collaborator is mocked, the test proves that configured return values flow through configured expectations, not that production composition works. Keep real internal collaborators and replace only true edges.
- If assertions target private call order, harmless refactors look like regressions. Assert the stable result, state transition, message, or protocol request instead.
- If a substitute omits relevant validation, ordering, uniqueness, transactions, retries, or cleanup, impossible production behavior passes. Raise fidelity or strengthen the substitute.
- If black-box-first becomes a separate full-stack journey for every assertion, setup and flakiness overwhelm development. Consolidate related acceptance evidence, use deterministic application-level black-box harnesses, and add focused tests only for important remaining gaps.
- If every discovered function earns a unit test, suite size grows without equivalent confidence and refactors become expensive. Require a distinct risk or contract that existing black-box coverage does not already establish.
- If tests construct branded or stateful values with casts, they can exercise states production cannot create. Use production constructors or schema-derived arbitraries.
- If a test sleeps to coordinate work, scheduler load turns correctness into timing luck. Expose readiness and control the clock or synchronization point.
- If shared setup, nested hooks, or flag-heavy helpers hide behavior-relevant state, readers must execute a second test language mentally. Keep causal context local and extract only narrow mechanics or lifecycle cleanup.
- If expected output is calculated with logic that mirrors production, the same defect can make both agree. State expectations independently and prefer literal examples.

## References

- [`references/test-levels-and-evidence.md`](./references/test-levels-and-evidence.md): Read when: selecting test level or deciding which observable evidence proves a behavior.
- [`references/seams-substitutes-and-interactions.md`](./references/seams-substitutes-and-interactions.md): Read when: replacing collaborators, considering module mocks or spies, or designing a fake/harness.
- [`references/persistence-and-generated-data.md`](./references/persistence-and-generated-data.md): Read when: choosing database fidelity, testing transaction semantics, or generating valid and invalid domain data.
- [`references/readable-self-contained-tests.md`](./references/readable-self-contained-tests.md): Read when: deciding whether to repeat setup, extract helpers, use shared hooks, introduce builders, or parameterize examples.
