# Persistence, delivery, and runners

## Durable commands and duplicate calls

Persistence is opt-in via `ClusterSchema.Persisted`. It saves requests and replies so unfinished work can be redelivered; it does not checkpoint handler memory or atomically include arbitrary external effects.

For a persisted RPC, choose `primaryKey` from logical command identity. Storage composes it with entity type, entity ID, and RPC tag. Duplicate calls are rewritten to the original request ID and can wait on that operation or receive its stored terminal reply. This is not a generic reject-duplicate-in-flight mechanism, nor a check that two payloads with the same key are equal.

For example, a reservation command's key should identify the reservation attempt, not merely the SKU. Reuse the attempt key for retries of identical intent; use a new key for a new attempt. A key based only on SKU would collapse legitimate later reservations into the original result. If conflicting reuse must be rejected, enforce that in the durable domain model. Deduplication lasts only as long as the relevant storage records are retained; cleanup and replay policies are part of the domain contract.

## Transactions and external effects

`ClusterSchema.WithTransaction` uses the configured `MessageStorage` transaction implementation. With SQL storage, keep domain SQL work on the participating client/transaction if it must commit with the reply. An HTTP payment call is not rolled back by that transaction; use an external idempotency key or an outbox-style boundary.

For persisted requests, success replies are saved inside the transaction and delivered after commit. Business failures roll back first, then save the failure reply. Commit/rollback failures can cause retries without a reply; a success already stored despite a commit error can be recovered. Do not assume a handler runs once.

Two important exceptions: stream chunks are saved/delivered immediately even if the transaction later rolls back, and a handler returning a `Deferred` commits before the eventual reply is saved. Neither is an atomic stream-of-results transaction.

## Delivery outcomes and adapters

Map errors according to caller action rather than collapsing them into one internal error:

- Business rejection is a completed protocol outcome, not a transport retry signal.
- Capacity pressure can surface as `MailboxFull` for volatile requests, including when the runner's resident-entity cap prevents a new activation. Persisted messages remain recoverable and are retried when capacity is available.
- `AlreadyProcessingMessage` identifies an already-processing envelope, not a business lock; durable duplicate handling usually reads the original operation's replies from storage.
- `PersistenceError` means mailbox storage failed. A retry policy still needs a stable operation identity and must not promise completion on an ambiguous submission.
- Runner unavailability and assignment changes are normally retried internally. `EntityNotAssignedToRunner` can surface when delivery can no longer continue, such as teardown; do not invent a public `RunnerUnavailable` branch for ordinary entity clients.

`EntityProxy`/`EntityProxyServer` expose entity protocols through RPC or HTTP while retaining cluster delivery semantics. Keep domain translation at that boundary. Generated discard operations omit the business result/error because they do not wait for it. Persisted discard stores the command without waiting for the handler; volatile discard may return while processing continues, but provides no crash durability.

## Who owns execution

- `TestRunner.layer` provides real sharding with in-memory message/runner storage and no-op transport/health. It exercises local runtime behavior, not database durability or network behavior.
- `SingleRunner.layer` is single-process infrastructure with SQL message storage. `runnerStorage: "memory"` changes runner storage only; SQL is still required. No-op communication/health do not coordinate separate processes.
- Distributed `HttpRunner` or `SocketRunner` composition needs runner membership/shard-lock storage, message storage for durable requests, health checks, transport, and consistent shard configuration. Message storage and runner storage solve different problems: mailbox/reply recovery versus membership and ownership.
- Client-only participants send requests without hosting shards. Keep that role separate from a runner registering entity handlers, and share one intended sharding runtime rather than accidentally constructing isolated runtimes at each client/service edge.

## Tests that establish the intended guarantee

`Entity.makeTestClient` creates per-ID in-memory RPC servers without serialization or the cluster delivery/storage loop. Use it for business transitions, ID isolation, handler-construction resources, and concurrency decisions. It cannot establish mailbox capacity, passivation timing, persistence, or handoff behavior.

Use `TestRunner.layer` and the entity's real `.client` for public delivery behavior: repeat the same logical command while in flight and after completion; force a defect/restart; verify that durable work survives and volatile capacity failures surface appropriately. Control handler progress with latches/queues rather than sleeps so the test distinguishes submission from completion.

For durable state, close/reconstruct an activation and assert authoritative state, not just a cached reply. Test the actual SQL backend for rollback/commit behavior and the deployed transport for encoding and ownership changes. In-memory storage has no SQL transaction isolation. Inspect storage directly only when the assertion concerns claims, stored replies, replay, deduplication, or transaction semantics.

## Source anchors

- `packages/effect/src/cluster/Envelope.ts`: `primaryKeyByAddress` scopes command keys.
- `packages/effect/src/cluster/Runners.ts`: `notifyWith` rewrites duplicates and reuses stored replies.
- `packages/effect/src/cluster/ClusterSchema.ts` and `internal/entityManager.ts`: transaction reply timing and retry behavior.
- `packages/effect/src/cluster/SqlMessageStorage.ts`: SQL transaction and storage implementation.
- `packages/effect/src/cluster/Sharding.ts`: outgoing routing retries, teardown, and persistence requirements.
- `packages/effect/src/cluster/{TestRunner,SingleRunner,HttpRunner,SocketRunner,RunnerStorage,EntityProxy}.ts`: infrastructure roles and adapter contracts.
- `packages/effect/test/cluster/MessageStorage.test.ts`: duplicate storage behavior.
- `packages/effect/test/cluster/Sharding.test.ts`: persisted recovery, mailbox pressure, discard, restart, and transaction failure tests.
