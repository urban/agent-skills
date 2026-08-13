# Entity protocols and state

Use Cluster when state or coordination is partitioned by a stable identity and benefits from serialized messages, passivation, or distributed placement.

Define each RPC's payload, success, business error, primary key, persistence, and streaming semantics before implementation. Protocol changes may affect stored messages and rolling compatibility.

Allocate Ref, Queue, cache, and other per-identity state inside entity construction. Keep default sequential handling for state transitions. Concurrent handlers require read-only, commutative, or otherwise proven-safe behavior.

Choose passivation from reconstruction cost, idle resource cost, and whether state is recoverable. Module globals do not follow entity passivation or restart semantics.
