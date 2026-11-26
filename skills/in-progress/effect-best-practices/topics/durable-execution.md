# Durable execution

Choose durability from the required lifetime of intent. Use an entity when per-identity coordination is central, a workflow when orchestration must survive execution loss, and ordinary scoped work when process lifetime is sufficient. Avoid introducing distributed machinery solely because the library offers it.

Treat persisted identities and schemas as protocols with existing consumers: entity and workflow names, command keys, payloads, results, and logical step identity. Decide how deployed changes interact with in-flight work. An implementation rename may be a data-compatibility change.

Identify authoritative state and how it is reconstructed. Activation-local memory is useful for coordination or caching only when losing it does not lose committed domain facts. Define concurrency from transition safety and cross-entity invariants; local serialization does not settle a business invariant spanning owners.

Choose the replay boundary around one logical external action. Keep downstream idempotency identity stable across its attempts, and distinguish a repeated attempt from newly authorized intent. Compensation belongs to business policy: it may require a new action with its own failures and cannot substitute for atomicity or replay safety.

Make caller acknowledgments truthful: submission, durable acceptance, and successful completion are different contracts. Decide how callers observe progress and reconcile unknown outcomes.

**Tradeoff:** test only the guarantee supplied by the actual engine, backing store, and transport under consideration. Use source documentation for persistence and delivery mechanics; establish the application's required restart and handoff behavior at the owning boundary.
