---
name: effect-service
description: Design one coherent Effect capability contract that hides implementation dependencies and exposes stable operations, actionable failures, and intentional replaceability. Use when that service boundary is the primary decision and no narrower integration specialist applies. Do not use for whole-application topology, Layer graph mechanics, or test strategy.
---

## Rules

- Define a service around one coherent capability owned by a domain or integration boundary.
- Make the public shape describe what callers can do, not the client, repository, runtime, or state used to do it.
- Capture stable implementation dependencies during service construction; keep request-specific identity or transactions explicit rather than freezing them into a long-lived service.
- When a concrete service has construction policy, keep its default constructor and Layer discoverable as class-owned `make` and `layer` members.
- Expose only failures callers can handle; translate provider and platform failures at the boundary where their meaning is known.
- Keep public failure variants fixed and safe. Include observed external values only when callers need them to act and the contract defines their sensitivity and size bounds.

## Constraints

- A service must remain replaceable without reproducing its implementation details in callers or tests.
- Service-owned resources must remain inside their constructing layer's lifetime; request-owned resources belong to the request scope.
- A low-level `use` escape hatch is acceptable only when wrapping the full surface is impractical and leaking the client is an explicit tradeoff.

## Knowledge Boundaries

Applies to:

- service granularity and public method shape
- dependency capture versus intentional requirement pass-through
- constructor effects, default Layers, parameterized Layers, and test implementations
- service-level error taxonomy and normalization

Does not cover:

- whole-application capability topology, composition roots, or public application facades
- detailed Layer graph composition or SDK-specific retry semantics
- test seam selection, deterministic coordination, or integration-test evidence
- repository path rules that happen to require service classes

Decision inputs:

- stable domain verbs and invariants
- dependencies and resources the implementation owns
- which failure distinctions change caller behavior
- whether configuration creates one implementation, a family of implementations, or a scoped resource

## Patterns

- Separate the capability contract from implementation construction; colocate supported default `make` and `layer` members on the concrete service class.
- Capture dependencies once when every method uses the same implementation context. Leave requirements explicit only for reusable lower-level capabilities or request-bound services deliberately supplied by callers.
- Keep construction failures separate from operation failures: callers of an already-built service should not inherit its startup dependencies or errors.
- Use matching `make(options)` and `layer(options)` members when explicit domain options change service behavior or Layer identity; choose and reuse the resulting Layer at the composition boundary where sharing is intended.
- Choose `Context.Reference` only when absence should select a valid default. Choose a required service when missing provision is a wiring error; behavior versus data is not the deciding distinction.
- Prefer a small full fake for behavior tests. Use partial mocks only when the test intentionally proves that unimplemented capabilities are unreachable.
- Preserve actionable distinctions such as not-found, conflict, unavailable, rejected, and invalid input; do not mirror every vendor error code in the domain.
- Preserve two failure distinctions only when they lead to different recovery, rendering, retry, or remediation; retain safe diagnostic causes separately for operators.

## Gotchas

- A service shaped like its SDK becomes an alias rather than a boundary; provider changes then propagate through the application.
- A service whose only job is wrapping arbitrary Effects to install context or own resources makes every caller responsible for coverage; use the complete invocation's provision boundary instead. Keep a service when its methods expose coherent application or integration behavior.
- Capturing the current user or transaction in an application-lived constructor freezes request context and can cross tenant boundaries; accept it per operation or resolve it in deliberately request-bound effects.
- Treating a constructor Effect as an already-wired layer leaves dependencies unresolved and ownership ambiguous; export the layer explicitly.
- Different classes or option sets do not create distinct Context slots when the string key is the same; use meaningful package-qualified keys and explicit instance selection when implementations must coexist.
- A reference default is computed lazily and cached on the reference, not allocated per request or test; keep defaults safe to share and acquire owned resources in a layer.
- A broad infrastructure error may be typed but still unusable; map only the distinctions callers can act on and retain diagnostic cause data.
- Public errors assembled from untrusted rows, paths, payloads, or exception text can leak sensitive or unbounded data; expose fixed variants and keep bounded evidence in operator diagnostics.
- A fresh layer around an already-created mutable fake still shares that fake; allocate state inside the constructor effect for each independently built test layer.

## References

- [`references/service-boundaries.md`](./references/service-boundaries.md): Read when: choosing service versus reference, dependency capture, or a service test substitute.
- [`references/construction-and-wiring.md`](./references/construction-and-wiring.md): Read when: authoring class-owned constructors and Layers, pure or parameterized construction, stable keys, variants, or public Layer aliases.
- [`references/error-boundaries.md`](./references/error-boundaries.md): Read when: mapping dependency errors or deciding whether a failure belongs in the public service contract.
