# Service construction and wiring

## Default class-owned shape

Keep `make` and `layer` discoverable on a concrete service class, while allowing callers to replace the implementation at the Context key. These members are an authoring convention, not an automatic consequence of `Context.Service`.

```ts
import { Context, Effect, Layer } from "effect"

class StockLedger extends Context.Service<StockLedger, {
  readonly available: (sku: string) => Effect.Effect<number>
}>()("@shop/StockLedger") {}

export class Availability extends Context.Service<Availability, {
  readonly canSupply: (sku: string, quantity: number) => Effect.Effect<boolean>
}>()("@shop/Availability") {
  static readonly make = Effect.gen(function* () {
    const ledger = yield* StockLedger

    return Availability.of({
      canSupply: (sku, quantity) => ledger.available(sku).pipe(
        Effect.map((available) => quantity > 0 && available >= quantity),
      ),
    })
  })

  static readonly layer = Layer.effect(Availability, Availability.make)
}
```

This capability answers a read-only availability question; it does **not** promise an atomic reservation. If callers need a reservation invariant, expose a reservation operation rather than making them compose a check and a write.

The layer requires `StockLedger` at construction, but `canSupply` closes over the selected ledger. `Availability.of` returns its argument unchanged: it does not construct, acquire, or wire anything. `Layer.effect` runs `make` in the layer's scope. Use `Layer.provide` on the default layer when a particular adapter is intentionally part of that default; otherwise retain its construction input for external wiring.

Keep acquisition failures on `make` / `layer` distinct from failures of the returned operations. A successful construction does not imply that later network calls cannot fail.

## Pure and scoped construction

For an already-available immutable implementation, `Layer.succeed(Service, implementation)` is enough. Keep `make = Effect.succeed(implementation)` when a named constructor seam is useful, not solely to force a uniform ceremony.

For mutable state, allocate inside the constructor effect rather than at module initialization. For an owned client or subscription, acquire with `Effect.acquireRelease` inside `make` and build with `Layer.effect`. The layer supplies the scope; closing it releases the resource even if a caller retained the service object. Do not return that object from a temporary scope and continue using it afterward.

## Parameterized construction and identity

When domain options select behavior, expose matching `make(options)` and `layer(options)` members. Options should be domain data, not a bag of optional dependency overrides. Keep a separately named seam such as `makeWith` for deliberate adapter replacement.

Distinguish three identities:

- **Context key:** the string identifies the runtime slot. Different classes using the same string collide; different options do not create additional slots.
- **Service value:** a constructor can produce multiple implementations of the same capability. Select the implementation for a given context, or model explicit instance lookup if several must coexist.
- **Layer value:** reusing the same layer shares acquisition within a shared build/memoization boundary. A factory that constructs a new layer on each call creates distinct layer values even for equal options; equal options are not a cache key. Reusing a layer across independent sibling `Effect.provide` calls does not itself promise one shared acquisition.

Choose and retain the parameterized layer value where sharing is intended; do not change the capability key merely to force fresh acquisition.

## Variants and public aliases

Name deliberate variants by policy, such as `layerTest`, `layerCached`, or `makeWith`. Keep `make` and `layer` as the discoverable defaults when those defaults exist.

Export a package-level default Layer only when embedding callers intentionally consume it; make it a direct alias of the class-owned Layer rather than constructing a second default. Application composition roots remain separate because they assemble several capabilities and own a broader runtime boundary.

## Source anchors (Effect v4)

- `packages/effect/src/Context.ts`: `Service`, `ServiceProto.of`, and string-key lookup.
- `packages/effect/src/Layer.ts`: `effect` / `effectContext` supply the layer scope.
- `packages/effect/src/Effect.ts`: `provide` documents enclosing reuse versus sibling builds.
- `packages/effect/test/Layer.test.ts`: “sharing with merge”, “finalizers”, and “memoizes composed layers by identity”.
