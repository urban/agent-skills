---
name: testing-strategy
description: Choose test boundaries, seams, substitutes, and evidence for TypeScript systems. Use when deciding test level, collaborator fidelity, persistence setup, property testing, interaction assertions, or readable test design.
---

## Rules

- Test through the smallest public boundary that preserves the behavior and failure semantics whose confidence matters.
- Assert caller- or user-observable outcomes rather than private implementation, call choreography, or incidental counts.
- Keep deterministic, inexpensive in-process collaborators real; replace external, destructive, expensive, or nondeterministic boundaries.
- Match each substitute's fidelity to the contract, including relevant transport, persistence, ordering, concurrency, retry, and lifecycle semantics.
- Keep scenario-defining setup, action, and expected outcome visible together, even when that requires controlled repetition.
- Use property tests only for a contract-grounded law that examples cannot cover economically; retain canonical examples and reject vacuous properties.

## Constraints

- Do not use module replacement such as `vi.mock` or `jest.mock` as the default seam.
- Do not export internals or rewrite production architecture solely to spy on implementation details.
- Do not claim confidence from a substitute that omits semantics relevant to the test.
- Do not use sleeps, live external services, or uncontrolled randomness in the normal deterministic suite.
- An exact interaction assertion is valid only when that interaction or wire shape is itself the observable contract.
- Do not hide behavior-relevant values or steps behind shared setup, nested hooks, broad fixtures, or generic helpers solely to remove repetition.

## Knowledge Boundaries

Applies to:

- selecting end-to-end, integration, contract, focused, property, and unit boundaries
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

- Start from the confidence question, not a fixed test pyramid, and choose the narrowest public boundary that can answer it.
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
- If every behavior is tested end to end, failures become slow and hard to localize. Move invariant and decision logic to focused boundaries while retaining a small set of critical flows.
- If tests construct branded or stateful values with casts, they can exercise states production cannot create. Use production constructors or schema-derived arbitraries.
- If a test sleeps to coordinate work, scheduler load turns correctness into timing luck. Expose readiness and control the clock or synchronization point.
- If shared setup or nested hooks provide behavior-relevant state, readers must execute the suite mentally before understanding one test. Inline that context and reserve hooks for unavoidable lifecycle or cleanup.
- If a helper grows flags, branches, or vague defaults, it becomes a second test language that hides the scenario. Split it, rename it around one concept, or inline it.
- If expected output is calculated with logic that mirrors production, the same defect can make both agree. State expectations independently and prefer literal examples.

## References

- [`references/test-levels-and-evidence.md`](./references/test-levels-and-evidence.md): Read when: selecting test level or deciding which observable evidence proves a behavior.
- [`references/seams-substitutes-and-interactions.md`](./references/seams-substitutes-and-interactions.md): Read when: replacing collaborators, considering module mocks or spies, or designing a fake/harness.
- [`references/persistence-and-generated-data.md`](./references/persistence-and-generated-data.md): Read when: choosing database fidelity, testing transaction semantics, or generating valid and invalid domain data.
- [`references/readable-self-contained-tests.md`](./references/readable-self-contained-tests.md): Read when: deciding whether to repeat setup, extract helpers, use shared hooks, introduce builders, or parameterize examples.
