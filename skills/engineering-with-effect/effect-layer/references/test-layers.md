# Test layers

## State belongs to acquisition

A stable layer recipe can serve many isolated tests if it allocates state during each independent build. Recreating the Layer object is not required. Conversely, a new layer or `Layer.fresh` cannot isolate an object allocated earlier and passed to `Layer.succeed`.

```ts
import { Context, Effect, Layer, Ref } from "effect"

const Counter = Context.Service<Ref.Ref<number>>("test/Counter")
const CounterLive = Layer.effect(Counter, Ref.make(0))
const increment = Effect.flatMap(Counter, (ref) =>
  Ref.updateAndGet(ref, (n) => n + 1)
)

const isolatedRuns = Effect.gen(function*() {
  const first = yield* Effect.provide(increment, CounterLive, { local: true })
  const second = yield* Effect.provide(increment, CounterLive, { local: true })
  return [first, second] // [1, 1], even if an outer build already has CounterLive
})
```

Use a shared block runtime only for intentionally shared expensive setup; keep mutable per-test state in a separate local build. Retain backing-state services with `provideMerge` only when assertions need controlled observability. Otherwise hide them behind the tested service.

## Evidence for lifetime and sharing contracts

- For scope-owned resources, observe successful release and interruption cleanup. Synchronize on acquisition before interrupting so the assertion cannot pass without exercising cleanup.
- When a dependent's finalizer needs its dependency, assert it runs while that dependency is usable. Do not assert a total ordering among parallel peers.
- For an intentional sharing contract, assert one acquisition for a diamond graph using a stable dependency layer; contrast it with a fresh subtree. Assert release after the owner closes, not merely acquisition counts.
- For conditional provision, a successful handler does not prove that disabled resources were absent. Observe acquisition through the real provision boundary; when bypass is the claim, distinguish no activation read from no resource acquisition. Completed release after that boundary exits establishes lifetime behavior that acquisition counts alone cannot show.
- When sharing a memo map across scopes or runtimes, close one owner and prove the resource remains usable through the other; close the last owner and assert one release.
- When fallback construction is important, fail after a resource is acquired and assert the failed branch releases it before fallback use.
- `Layer.mock` supports partial services whose omitted members fail with `UnimplementedError` when used. Use this only for a narrow path where touching another capability should fail, not as a general replacement for a behaviorally faithful fake.
