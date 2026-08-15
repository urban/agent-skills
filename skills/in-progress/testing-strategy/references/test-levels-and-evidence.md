# Test levels and evidence

## Choose from the confidence question

A useful default order is:

1. a small number of end-to-end tests for critical user or operational flows,
2. integration and contract tests through real application seams,
3. focused examples and properties for pure domain behavior,
4. unit tests where one module's contract is meaningful in isolation.

This is not a quota. Choose the lowest-cost boundary that still includes the semantics whose failure must be detected.

| Confidence needed | Useful boundary |
| --- | --- |
| Critical flow works across deployed components | End-to-end |
| Modules compose and real infrastructure semantics matter | In-process or local integration |
| One adapter honors a remote or persistence protocol | Contract or adapter integration |
| Domain decision or invariant holds | Focused example or property |
| One deep module presents stable behavior | Unit test through its public interface |

Escalate fidelity when routing, serialization, middleware, runtime lifecycle, database constraints, transaction isolation, or concurrency is the behavior. Reduce fidelity when the relevant rule is a pure value transformation.

## Observable evidence

Prefer evidence a caller or operator could observe:

- returned value or typed failure
- persisted row or domain state loaded through a public query
- emitted event, message, or job
- rendered HTTP/CLI/UI response
- captured outbound protocol request at a boundary harness
- acquired and released resource

An exact interaction is observable when the interaction is the product or protocol contract. For example, an adapter contract may require one particular HTTP method, path, serialized body, idempotency key, or cleanup call. Internal helper call count is not equivalent.

## Suite roles

Keep live external checks separately named and scheduled as smoke or compatibility tests. They provide evidence about credentials, deployment, provider behavior, and network integration but should not make the normal suite nondeterministic.

When a regression is found, reproduce it at the smallest public boundary that still exhibits the failure. Name the broken behavior and assert the stable outcome; avoid freezing incidental implementation that happened to be present in the fix.
