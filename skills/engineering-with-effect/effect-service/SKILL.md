---
name: effect-service
description: Design Effect service boundaries that hide implementation dependencies while exposing stable domain capabilities, actionable failures, and intentional resource ownership. Use when the primary task is shaping an application capability, dependency capture, or replaceability and no narrower integration skill applies.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Verify `Context.Service`, `Context.Reference`, and Layer APIs against the installed Effect v4 release before authoring construction examples.
- Define a service around one coherent capability owned by a domain or integration boundary.
- Make the public shape describe what callers can do, not the client, repository, runtime, or state used to do it.
- Capture implementation dependencies during service construction unless pass-through requirements are intentionally part of the capability.
- Keep a concrete service's default constructor and default Layer discoverable as class-owned `make` and `layer` members.
- Expose only failures callers can handle; translate provider and platform failures at the boundary where their meaning is known.
- Keep public failure variants fixed and safe. Include observed external values only when callers need them to act and the contract defines their sensitivity and size bounds.

## Constraints

- A service must remain replaceable without reproducing its implementation details in callers or tests.
- Resource acquisition and release belong to the layer that constructs the service, not to unrelated call sites.
- A low-level `use` escape hatch is acceptable only when wrapping the full surface is impractical and leaking the client is an explicit tradeoff.

## Knowledge Boundaries

Applies to:

- service granularity and public method shape
- dependency capture versus intentional requirement pass-through
- constructor effects, default Layers, parameterized Layers, and test implementations
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

- Keep the capability contract, constructor Effect, and default Layer distinct as artifacts while colocating the default `make` and `layer` on the concrete service class.
- Capture dependencies once when every method uses the same implementation context. Leave requirements explicit only for reusable lower-level capabilities or request-bound services deliberately supplied by callers.
- Construct the service value with `Service.of`, and define its default Layer from the class-owned constructor.
- Use matching `make(options)` and `layer(options)` members when explicit domain options change service behavior or Layer identity; choose and reuse the resulting Layer at the composition boundary where sharing is intended.
- Use `Context.Reference` for a contextual value with a default that has no coherent capability or owned resource; use a service when the boundary owns reusable behavior, dependencies, or resources.
- Prefer a small full fake for behavior tests. Use partial mocks only when the test intentionally proves that unimplemented capabilities are unreachable.
- Preserve actionable distinctions such as not-found, conflict, unavailable, rejected, and invalid input; do not mirror every vendor error code in the domain.
- Preserve two failure distinctions only when they lead to different recovery, rendering, retry, or remediation; retain safe diagnostic causes separately for operators.

## Gotchas

- A service shaped like its SDK becomes an alias rather than a boundary; provider changes then propagate through the application.
- Ad-hoc threading of contextual service implementations hides requirements from composition and makes replacement inconsistent; capture those dependencies in construction. Explicit functional dependency injection remains valid when it is the intended interface.
- Treating a constructor Effect as an already-wired layer leaves dependencies unresolved and ownership ambiguous; export the layer explicitly.
- An unstructured options bag makes service identity and sharing ambiguous; accept explicit domain options and let the composition boundary choose them.
- Promoting every contextual value to a service adds construction topology without a capability boundary; use a reference when a replaceable default value or recipe is the actual abstraction.
- A broad infrastructure error may be typed but still unusable; map only the distinctions callers can act on and retain diagnostic cause data.
- Public errors assembled from untrusted rows, paths, payloads, or exception text can leak sensitive or unbounded data; expose fixed variants and keep bounded evidence in operator diagnostics.
- Shared mutable fake state can survive beyond one test scope; allocate it in a per-test layer unless sharing is the behavior under test.

## References

- [`references/service-boundaries.md`](./references/service-boundaries.md): Read when: choosing service versus reference, dependency capture, or a service test substitute.
- [`references/construction-and-wiring.md`](./references/construction-and-wiring.md): Read when: authoring class-owned constructors and Layers, pure or parameterized construction, stable keys, variants, or public Layer aliases.
- [`references/error-boundaries.md`](./references/error-boundaries.md): Read when: mapping dependency errors or deciding whether a failure belongs in the public service contract.
