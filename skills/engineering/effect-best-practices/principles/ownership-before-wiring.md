# Decide ownership before wiring

**Apply when:** selecting dependency capture, resource scope, shared identity, or background-work lifetime.

Decide who owns the capability, which operations should share it, and who observes failure and shutdown. Then choose Effect's construction and lifetime mechanisms. Visibility, sharing, and release are separate application decisions even when one graph expresses them.

**Example:** a host owns its shared connection pool; a transaction owner supplies a transaction-current view only to work valid inside that transaction. Neither becomes request-independent merely because it is reachable through Context.

**Tradeoff:** narrow ownership can require a nested graph, while excessive isolation duplicates infrastructure. Isolate identity-specific state and intentionally reuse infrastructure whose lifetime and semantics permit sharing.
