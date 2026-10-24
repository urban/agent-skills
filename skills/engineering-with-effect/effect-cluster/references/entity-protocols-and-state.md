# Entity protocols and state

## Identity and protocol lifetime

Choose an entity ID for the aggregate whose transitions must coordinate. Two IDs do not share a mailbox or serialization boundary; a multi-entity invariant needs a separate consistency design.

The entity type names the protocol; the ID is routed through a shard group and shard number. Keep routing configuration consistent across runners, especially `shardsPerGroup`. Changing identity, RPC tags, schemas, or command keys is a compatibility decision for stored messages and replies, not merely a source refactor.

Declare expected domain rejection in the RPC error schema. A defect is not a substitute: by default a handler defect restarts the entity's handlers and replays unfinished requests, potentially affecting concurrent work for that identity. `disableFatalDefects` changes isolation behavior, not the need to model business failures.

## Activation-local state

An effect passed to `toLayer` builds handlers for each activation. Allocate mutable state and scoped resources there; an already-created handler object closing over module state shares that state across IDs.

```ts
import { Effect, Ref, Schema } from "effect"
import { Entity } from "effect/cluster"
import { Rpc } from "effect/rpc"

const Session = Entity.make("Session", [
  Rpc.make("Touch", { success: Schema.Number })
])

const SessionLive = Session.toLayer(Effect.gen(function*() {
  // Deliberately ephemeral: each activation starts at zero.
  const touches = yield* Ref.make(0)
  return Session.of({
    Touch: () => Ref.updateAndGet(touches, (n) => n + 1)
  })
}))
```

For durable aggregates, load authoritative state during construction and coordinate durable writes with command handling. Persisted messages alone cannot rebuild a projection from all historical commands: completed requests are not ordinary recovery input.

Passivation closes idle activations; later requests construct them again. Choose idle time from resource cost and reconstruction cost. The reaper skips entities with active requests or keep-alive enabled, so `maxIdleTime` is not a deadline for a long-lived stream. Choose termination behavior separately: `InterruptOnTermination` lets long-lived handlers stop promptly during shutdown/handoff; persisted requests resume under the next owner. Server-side `Uninterruptible` takes precedence.

## Concurrency is a domain decision

`toLayer` defaults to concurrency one. That protects state transitions only while handlers retain the serialization slot. `Rpc.fork` allows overlap even with that default; increasing concurrency also permits same-ID overlap. Read-only work is safe only if it can tolerate observing concurrent transitions; external writes may need serialization even without mutable local state.

Use `toLayerQueue` when the protocol genuinely needs a custom scheduling/state-machine loop, not just to recreate a mailbox. It registers handlers with unbounded RPC concurrency and leaves scheduling and replies to the queue consumer/replier. Bound and reason about that behavior explicitly.

## Source anchors

- `packages/effect/src/cluster/Entity.ts`: `toLayer`, `toLayerQueue`, `CurrentAddress`, and `Request`.
- `packages/effect/src/cluster/internal/entityManager.ts`: per-activation construction, default concurrency, defect restart, and request replay.
- `packages/effect/src/cluster/internal/entityReaper.ts`: active-request and keep-alive exclusions.
- `packages/effect/src/cluster/ClusterSchema.ts`: termination and interruption annotations.
- `packages/effect/test/cluster/Entity.test.ts`: activation scopes, per-ID isolation, typed failures versus fatal defects.
- `packages/effect/test/cluster/Sharding.test.ts`: handler restart and unfinished-request replay.
