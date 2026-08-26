# Entrypoints, transactions, and idempotency

## Thin entrypoints

Keep application behavior reusable across HTTP, GraphQL, CLI, workers, and scheduled jobs. An entrypoint should:

- parse and authenticate protocol input
- translate it into domain values and a domain-specific principal
- invoke a shared application capability
- render success and expected failures in the protocol's vocabulary

Do not duplicate business transitions, authorization rules, or integration orchestration in each controller or handler. Authentication may be protocol-specific; authorization policy should be shared. Prefer inputs such as `Session`, `Principal`, `AdminUser`, or `CommandActor` over raw headers or framework request objects.

## Coordination choice

Use ordinary program flow when no cross-write atomicity or durable process-loss recovery is required. It may include bounded remote I/O.

Use one database transaction when the required atomic state changes live in one transactional store and can complete without remote calls or long waits. Make race-sensitive decisions from transaction-current reads after establishing the required consistency or writer position; previews and pre-transaction reads do not reserve state.

Use a saga or durable workflow when work spans transaction boundaries and needs one or more of:

- retry after process loss
- compensation
- resumability or timers
- human or external completion
- cross-service progress or recovery that must survive process loss
- durable progress and status

Classify coordination by its guarantees, not its API imports. An in-memory Workflow engine is process-scoped orchestration, not a durable workflow.

Never hold a database transaction open during a remote call or long wait. A transaction cannot make the remote side atomic, and holding locks increases contention while preserving the partial-failure problem.

## Retry identity

For every retried state-changing command, job, message, or workflow step, identify where duplicate execution can occur. Either prove the operation is inherently repeat-safe or enforce one strategy at the state-changing boundary:

- idempotency key tied to logical operation identity
- natural unique constraint
- deduplication record
- guarded state-machine transition
- transactional inbox for consumed messages
- transactional outbox for intended messages or external work

An outbox makes local state and intent atomic; it does not make the eventual external side effect exactly once. The external operation still needs idempotency or deduplication where duplicates matter.

When a commit outcome is unknown, reread authoritative state and reconcile the logical operation before retrying; do not treat uncertainty as proof that no commit occurred.

Compensation reverses a completed business action. It is not evidence that replaying the original action is safe.
