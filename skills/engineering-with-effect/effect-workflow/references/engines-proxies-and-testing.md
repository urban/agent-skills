# Engines, proxies, and testing

Separate definition, implementation, workers, persistence/storage, engine, and proxy layers. Memory engines support deterministic local tests; cluster-backed engines provide cross-runner durability.

Clarify public semantics:

- execute and wait for success/failure
- start/discard and receive execution identity
- poll unknown/running/suspended/completed state
- interrupt and resume

Generated proxies are useful when they preserve these semantics and reuse workflow schemas. Keep them at RPC/HTTP composition edges.

Test through public execute/poll/resume APIs. Use logical time for durable waits and polling. Add lower-level assertions only for replay, idempotency, deduplication, persistence, transaction, or compensation behavior.
