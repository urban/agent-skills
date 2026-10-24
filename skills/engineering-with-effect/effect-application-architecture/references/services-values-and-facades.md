# Services, values, and facades

## Preserve ordinary values

Effect requirements describe capabilities needed at runtime; they are not a module system for every named concept. Keep a value or function ordinary when its identity is entirely in its inputs and outputs and it owns no independently configured or shared runtime concern.

Ordinary shapes commonly include:

- schemas, canonical values, and pure domain policy
- deterministic comparators, transitions, and evidence construction
- immutable commands, mutation intents, and operation results
- operation-local preparation or execution functions
- transaction-scoped semantic views and writers that are valid only inside one callback

A reusable function may still return an `Effect` and declare requirements. That alone does not require a new service. Promote a capability to `Context.Service` when callers need a coherent runtime identity with replaceability, shared state, configuration, owned resources, or construction that captures implementation dependencies.

Use `Context.Reference` when absence should intentionally fall back to a default, not merely because the value is small or configurable. Its default is evaluated lazily and cached on the key, not allocated per request or runtime. A required deployment setting or acquired client should not silently fall back; pass validated values to construction or require a service. Context lookup itself does not own resource release.

An operation-local value may be contextual when a framework protocol or dynamic propagation contract requires service lookup. Provide it only inside the owning request, run, transaction, tool, or subscription scope; the exception changes access, not lifetime.

## Private feature capabilities

A private feature capability coordinates a caller-meaningful use case while hiding infrastructure vocabulary. Its methods speak in domain inputs, outcomes, and expected failures. Its constructing Layer captures repositories, remote protocol services, clocks, identifiers, or other dependencies that are implementation details.

Not every feature module needs a service. Pure features remain ordinary modules, and a one-shot operation can remain a named Effect function when contextual replacement or shared construction adds no value. Conversely, a cohesive private service can be worthwhile even when it has one current caller if it hides a meaningful dependency and policy boundary.

Private does not mean untestable. Test through the public surface when that proves behavior; test a private feature directly only when it owns a substantial contract that the public surface cannot isolate clearly.

## Public facades

A public facade earns its place when it gives callers a stable, cohesive vocabulary while hiding multiple private features and their graph. It may capture private capabilities during construction and expose only supported application operations. Callers then require the facade rather than recreating feature composition.

Do not add a facade that only renames each private method. A facade should reduce caller burden by owning cross-feature policy, hiding graph shape, stabilizing a supported surface, or presenting one coherent capability to an entrypoint or embedding application.

One application may expose:

- one facade for a tightly cohesive product surface
- several facades for independently useful caller groups
- direct public feature capabilities when no extra facade adds depth
- ordinary public Effect functions when a service identity is unnecessary

Choose from caller cohesion and replacement needs, not from a rule that an application must have exactly one service.

## Dependency visibility

Capture implementation requirements while constructing private features and facades. Leave a requirement visible on a public operation only when supplying that capability is intentionally the caller's responsibility, such as scoped invocation context chosen by the caller or host protocol.

A service's contextual requirements, method inputs, successes, failures, and returned values all contribute to the public contract. Hiding an internal module from exports is insufficient if a public type still mentions its service or representation.

### Capture fixes dependency identity

```ts
import { Context, Effect, Layer } from "effect"

class Inventory extends Context.Service<Inventory, {
  readonly reserve: (sku: string) => Effect.Effect<void>
}>()("shop/Inventory") {}

class Dispatch extends Context.Service<Dispatch, {
  readonly schedule: (sku: string) => Effect.Effect<void>
}>()("shop/Dispatch") {}

class Fulfillment extends Context.Service<Fulfillment, {
  readonly fulfill: (sku: string) => Effect.Effect<void>
}>()("shop/Fulfillment") {
  static readonly layer = Layer.effect(Fulfillment, Effect.gen(function*() {
    const inventory = yield* Inventory
    const dispatch = yield* Dispatch
    return {
      fulfill: (sku: string) => Effect.gen(function*() {
        yield* inventory.reserve(sku)
        yield* dispatch.schedule(sku)
      })
    }
  }))
}
```

The facade owns the ordering policy; the composition boundary only selects providers. This sketch assumes scheduling may follow reservation without atomicity; it does not implement rollback or durable delivery.

Providing the private Layers to `Fulfillment.layer` with `Layer.provide` produces a public Layer exposing only `Fulfillment`. Its operations close over those private instances. Overriding `Inventory` around a later call cannot replace the captured instance. For tenant-specific dependencies, construct the facade in that tenant's graph; for deliberately invocation-local context, perform lookup during the operation instead of capturing it. Do not capture request or transaction state in a host-lived facade.
