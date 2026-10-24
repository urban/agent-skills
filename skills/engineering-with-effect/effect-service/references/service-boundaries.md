# Service boundaries

## Capability contract

A service contract should answer:

- What capability does the caller need?
- Which invariants belong to this capability?
- Which failure distinctions change caller behavior?
- Which dependencies and resources are implementation details?

If the methods largely reproduce an SDK, repository, or platform interface, either the abstraction is too low-level or it should be named explicitly as an adapter. Keep a reusable Effect function ordinary when parameters and declared requirements already express its whole identity; contextual access alone does not justify a new capability.

## Dependency capture versus invocation context

Yielding a service key retrieves a value from the executing fiber's current context. Retrieving a dependency in `make` and closing over that value fixes the implementation for the lifetime of the constructed service. Overriding that dependency around a later operation does not replace the captured value; supply the override when building the service or replace the service itself.

Capture stable clients, repositories, or policy implementations this way. Capture is not transitive: a captured dependency's operations may still read contextual services when executed. Merely returning an Effect from a constructor does not capture its whole environment.

Request identity, authorization context, tracing, or a transaction can legitimately belong to invocation context. Choose deliberately:

- Pass domain identity or transaction data as method arguments when it is part of the operation's meaning.
- Leave a contextual requirement on an operation when the caller deliberately owns its provision and lifetime.
- Construct a request-scoped service when its entire lifetime should bind to one request.

Do not capture the first caller's credentials or transaction into an application-lived singleton. Conversely, do not leave private platform-client requirements on every method merely to avoid construction wiring.

## Required service or defaulted reference

Use a required `Context.Service` when absence is a wiring error. Use `Context.Reference` when absence has a legitimate default behavior or value. A reference can contain behavior, and a required service can contain configuration; the distinction is the default policy, not whether the shape has methods.

A reference computes its default lazily and caches it on that reference. It is not a per-fiber or per-scope factory. Prefer immutable defaults or recipes safe to share; acquire owned resources through a layer instead. An override remains contextual, but it does not reset or dispose of the cached default.

Optional service access is appropriate only when absence has intentional semantics. Silently switching to a fallback implementation can hide missing production wiring, especially for authorization, persistence, or delivery guarantees.

## Test substitutes

A complete deterministic substitute can use `Layer.succeed(Service, Service.of(fakeShape))`. If the fake is mutable, allocate it inside a constructor effect in a per-test build rather than wrapping shared module state in a new layer. Expose a test harness service only when assertions need to observe requests, state, or cleanup without reaching into private implementation details.

A partial `Layer.mock` is appropriate when unimplemented operations are intentionally unreachable; accessing them defects rather than supplying meaningful default behavior. A narrowly named class-owned constructor seam such as `makeWith` can replace a private client or resource recipe without exporting it as a production capability.

## Source anchors (Effect v4)

- `packages/effect/src/Context.ts`: `Key`, `ServiceProto.evaluate`, `use`, `Reference`, and `getDefaultValue`.
- `packages/effect/src/Effect.ts`: `service`, `serviceOption`, and `provideService`.
- `packages/effect/test/Context.test.ts`: “resolves reference defaults lazily and caches them”.
- `packages/effect/test/Layer.test.ts`: `mock` tests, including “missing mock members fail as unimplemented effects and channels”.
