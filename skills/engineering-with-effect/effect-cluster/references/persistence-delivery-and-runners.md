# Persistence, delivery, and runners

Persist only with storage and a replay story. External side effects inside replayable handlers need idempotency keys, transactions, or deduplication.

Separate:

- business error declared by the RPC
- mailbox/backpressure failure
- duplicate in-flight primary key
- persistence/storage failure
- transport/runner unavailability

Map these at the domain or proxy boundary according to caller action.

Use a test runner or test client for public behavior, a local runner for single-node durability, and cluster transports for live placement. Keep runner and storage layers outside entity definitions.

Inspect storage directly only when verifying persistence, replay, resume, deduplication, or transaction semantics.
