# Make replay follow logical intent

**Apply when:** retries, reconnects, duplicate commands, or durable steps can repeat an external action.

Define one logical operation, its identity, and which repeated observations should join it. Carry that identity across attempts and external boundaries. Decide what the application does when the action may have committed but its result is unknown.

**Example:** a payment retry retains the same business operation key; a separately authorized second payment gets a different identity. A provider switch must preserve that distinction too.

**Tradeoff:** an overly broad key merges distinct intent; a per-attempt key defeats deduplication. Neither a retry policy nor persisted step bookkeeping substitutes for an external system's idempotency or reconciliation contract.
