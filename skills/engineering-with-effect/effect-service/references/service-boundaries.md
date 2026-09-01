# Service boundaries

## Contract test

A service contract should answer:

- What capability does the caller need?
- Which invariants belong to this capability?
- Which failure distinctions change caller behavior?
- Which dependencies and resources are implementation details?

If the methods largely reproduce an SDK, repository, or platform interface, either the abstraction is too low-level or it should be named explicitly as an adapter.

## Construction shapes

- **No-dependency implementation:** keep construction as an Effect and provide the resulting value through the default Layer.
- **Captured dependencies:** acquire services in the constructor effect and close over them in methods.
- **Parameterized implementation:** return a layer from configuration or identity input.
- **Scoped implementation:** acquire and release the owned client, handle, subscription, or process in the layer scope.
- **Pass-through requirement:** leave a requirement on methods only when every caller intentionally supplies that context.

The service constructor and the default fully wired Layer are distinct artifacts owned by the concrete service class. Keep construction and wiring independently replaceable while making both discoverable from the service identity.

## Service or reference

Use `Context.Service` for a coherent capability with reusable behavior, implementation dependencies, replaceability, shared state, or owned resources.

Use `Context.Reference` for a contextual value or recipe with a default that does not form such a capability. Configuration values, feature switches, clocks, and replaceable Layer recipes are common examples. A reference changes how a value is obtained; it does not acquire service-like behavior or resource ownership merely by living in Context.

Keep a reusable Effect function ordinary when parameters and declared requirements already express its whole identity. Contextual access alone does not justify a service.

## Test substitutes

A complete deterministic substitute can use `Layer.succeed(Service, Service.of(fakeShape))`. Put mutable fake state in the layer scope. Expose a test harness service only when assertions need to observe requests, state, or cleanup without reaching into private implementation details.

Use a narrowly named class-owned constructor seam such as `makeWith` only when a test must replace a private constructor dependency or resource recipe without widening the production service contract. Keep private platform clients behind that seam rather than exporting them for tests.
