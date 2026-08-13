---
name: effect-service
description: Design Effect service boundaries that hide implementation dependencies while exposing stable domain capabilities, actionable failures, and intentional resource ownership. Use when the primary task is shaping an application capability, dependency capture, or replaceability and no narrower integration skill applies.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Define a service around one coherent capability owned by a domain or integration boundary.
- Make the public shape describe what callers can do, not the client, repository, runtime, or state used to do it.
- Capture implementation dependencies during service construction unless pass-through requirements are intentionally part of the capability.
- Expose only failures callers can handle; translate provider and platform failures at the boundary where their meaning is known.

## Constraints

- A service must remain replaceable without reproducing its implementation details in callers or tests.
- Resource acquisition and release belong to the layer that constructs the service, not to unrelated call sites.
- A low-level `use` escape hatch is acceptable only when wrapping the full surface is impractical and leaking the client is an explicit tradeoff.

## Knowledge Boundaries

Applies to:

- service granularity and public method shape
- dependency capture versus intentional requirement pass-through
- constructor effects, live layers, parameterized layers, and test implementations
- service-level error taxonomy and normalization

Does not cover:

- detailed Layer graph composition or SDK-specific retry semantics
- repository path rules that happen to require service classes

Decision inputs:

- stable domain verbs and invariants
- dependencies and resources the implementation owns
- which failure distinctions change caller behavior
- whether configuration creates one implementation, a family of implementations, or a scoped resource

## Patterns

- Keep contract, construction, and default wiring distinct enough that tests can replace the boundary and applications can choose runtime dependencies.
- Capture dependencies once when every method uses the same implementation context. Leave requirements explicit only for reusable lower-level capabilities or request-bound services deliberately supplied by callers.
- Use parameterized layer factories when configuration or resource identity changes the service instance.
- Prefer a small full fake for behavior tests. Use partial mocks only when the test intentionally proves that unimplemented capabilities are unreachable.
- Preserve actionable distinctions such as not-found, conflict, unavailable, rejected, and invalid input; do not mirror every vendor error code in the domain.

## Gotchas

- A service shaped like its SDK becomes an alias rather than a boundary; provider changes then propagate through the application.
- Ad-hoc threading of contextual service implementations hides requirements from composition and makes replacement inconsistent; capture those dependencies in construction. Explicit functional dependency injection remains valid when it is the intended interface.
- Treating a constructor Effect as an already-wired layer leaves dependencies unresolved and ownership ambiguous; export the layer explicitly.
- A broad infrastructure error may be typed but still unusable; map only the distinctions callers can act on and retain diagnostic cause data.
- Shared mutable fake state can survive beyond one test scope; allocate it in a per-test layer unless sharing is the behavior under test.

## References

- [`references/service-boundaries.md`](./references/service-boundaries.md): Read when: splitting contract from construction, choosing dependency capture, parameterizing a layer, or designing a service test substitute.
- [`references/error-boundaries.md`](./references/error-boundaries.md): Read when: mapping dependency errors or deciding whether a failure belongs in the public service contract.
