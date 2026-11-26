# Let capabilities follow callers

**Apply when:** choosing service granularity, a public facade, or an ordinary Effect-returning function.

Introduce a capability boundary when it gives callers a coherent vocabulary and hides meaningful implementation decisions. Keep pure policy, immutable decisions, and operation-local values ordinary. Returning an Effect alone does not justify contextual identity.

**Example:** a fulfillment capability may own reservation and dispatch policy without exposing both private services. A deterministic reservation calculation needs no service merely because fulfillment calls it.

**Tradeoff:** one caller does not make a useful boundary unnecessary, and several callers do not make a shallow wrapper useful. Favor the surface that reduces caller knowledge while preserving intentional replacement and ownership.
