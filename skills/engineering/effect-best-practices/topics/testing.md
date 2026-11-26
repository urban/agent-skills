# Testing

Exercise caller-visible behavior through the closest useful public composition. Replace genuine external uncertainty rather than every collaborator. A fake should preserve the ordering, uniqueness, transactions, failure, or cancellation semantics relevant to the claim; omitted behavior remains unproven.

Treat test sharing as an explicit ownership choice. Isolate mutable state and identity-specific dependencies unless sharing is part of the contract. For asynchronous behavior, identify the application milestone that makes the next assertion meaningful; elapsed time is not evidence of that milestone. Assert resource release only after its owner has actually closed.

Choose observations by contract. Exact calls matter for wire payloads, command arguments, idempotency keys, or release obligations. Incidental call order, private queues, and cache layout usually obscure the behavior. Preserve a concrete regression example when it expresses the bug more clearly than a broad property.

Use properties for named domain laws, with an independent oracle and input space covering the promised representation. A canonicalization law is different from lossless round-trip identity. Stateful Effect properties need a fresh system and model for every evaluation, including shrinking; reproducing generated inputs does not reproduce uncontrolled external state.

**Tradeoff:** handler-level evidence may be sufficient for domain and protocol interpretation, while transport, restart, persistence, or shutdown claims need their actual owners exercised. Use Effect's testing documentation for APIs and harness setup; this topic determines what those tests must establish.
