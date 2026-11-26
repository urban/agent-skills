# Seams, substitutes, and interactions

## Domain capabilities and production composition

Name the domain action and its promised result before choosing dependencies to replace. Keep the domain rules, application orchestration, and internal collaborators that implement that promise inside the test. A supported pure domain operation can be tested directly when it owns a distinct law; an internal helper does not become a separate contract merely because it is exported.

In an effect system or dependency-injection graph, assemble the relevant production layers and supply controlled implementations at true external edges. Replace a clock, provider, or persistence capability when externality, cost, destructiveness, or nondeterminism warrants it. Do not replace every injectable service or introduce a new layer solely to make mocking convenient.

Retain the resource owner and runtime semantics when the claim involves acquisition, interruption, cancellation, finalization, retries, or concurrent state. A fake success value cannot establish that production composition releases a resource or classifies a failure correctly. Assert the failure variant callers handle; assert message text only when that text is itself a contract.

## Prefer explicit seams

Useful test seams include:

- constructor-injected capability interfaces
- service or dependency-injection containers
- handler-backed HTTP clients
- temporary files, processes, or databases
- local protocol simulators
- boundary-owned fakes with an observation harness
- explicit clock, random, scheduler, or ID-generator capabilities

Control synchronization through readiness signals or explicit scheduling points; do not use sleeps to coordinate a deterministic test.

Module replacement with `vi.mock` or `jest.mock` patches dependency lookup after design. It obscures the production graph, can depend on import order and module caching, and encourages tests to mirror private calls. Prefer an explicit seam that production also uses.

## Substitute semantics

A substitute need not reproduce every implementation detail. It must preserve the contract relevant to its consumers, including any tested:

- validation and normalization
- ordering and concurrency
- uniqueness or consistency
- retry and idempotency behavior
- failure classification
- acquisition and cleanup

Use an in-memory fake when the semantics are simple and intentionally represented. Use a scripted adapter when a sequence of external responses matters. Use a local real service when wire, runtime, or engine behavior is the reason for the test.

Allocate mutable fake state per test unless shared state is itself under test. Expose observations through a harness rather than allowing tests to reach into private implementation state.

## Interaction assertions

Do not use spies to ask whether the implementation followed the path you expected. Ask whether the public outcome is correct.

An interaction assertion is justified when no more direct state/result exists because the interaction itself is the contract, such as:

- sent email or payment request recorded by a fake boundary
- serialized event on a queue
- required audit record
- CLI invocation arguments
- protocol method/path/body/headers
- resource close, rollback, or cancellation

Prefer asserting the captured boundary record over spying on an internal method. If a spy is unavoidable, attach it at the true boundary and assert only contract-significant details, not incidental count or ordering.
