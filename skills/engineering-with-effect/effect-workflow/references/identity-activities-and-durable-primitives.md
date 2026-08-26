# Identity, activities, and durable primitives

Derive workflow execution identity from logical payload fields. Stable activity/deferred/queue names are part of replay identity.

| Primitive | Use |
| --- | --- |
| Activity | Encoded retryable/replayable side-effect step |
| Durable clock | Wait that survives suspension or runner movement |
| Durable deferred | External actor completes a suspended execution |
| Durable queue | Worker pool owns asynchronous processing |

Every activity needs retry classification and idempotency. Compensation is a business reversal after a completed step, not proof that retries are safe. Verify where compensation finalizers are registered and when suspension versus failure triggers them.

Use approval gates or external completion tokens for human/authority decisions rather than polling mutable process state.
