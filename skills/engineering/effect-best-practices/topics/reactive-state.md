# Reactive state

Treat registry placement and cache identity as application boundaries. Include every identity dimension that separates state, especially tenant, entity, authorization scope, and meaningful query parameters. Shared consumers need an intentional shared owner; unrelated consumers should not inherit cached authority accidentally.

Give atom modules responsibility for queries, mutations, derived views, invalidation, and cache policy. Components render the lifecycle and dispatch intent rather than maintaining another copy of successful data. Use Effect's current atom documentation for lifecycle and retention mechanics.

Choose the user-visible meaning of initial loading, refreshing with prior data, failed refresh, and successful emptiness. Preserve those distinctions when they change user action. Retention and acceptable data age are separate policies; keeping a value available does not decide when it should be refreshed.

Decide mutation overlap before applying optimism: serialize conflicting intent, isolate independent writes, or define an explicit reconciliation rule. A failed older mutation must not restore a snapshot over newer accepted state. Optimism is a provisional display policy; server-side concurrency and idempotency still need their own contracts.

**Tradeoff:** immediate feedback can be useful even when perfect rollback is impossible, but the UI must represent uncertainty honestly. Exercise reversed completion orders and identity changes when they can invalidate the chosen policy.
