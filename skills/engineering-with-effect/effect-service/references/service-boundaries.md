# Service boundaries

## Contract test

A service contract should answer:

- What capability does the caller need?
- Which invariants belong to this capability?
- Which failure distinctions change caller behavior?
- Which dependencies and resources are implementation details?

If the methods largely reproduce an SDK, repository, or platform interface, either the abstraction is too low-level or it should be named explicitly as an adapter.

## Construction shapes

- **No-dependency implementation:** construct a value directly in a simple layer.
- **Captured dependencies:** acquire services in the constructor effect and close over them in methods.
- **Parameterized implementation:** return a layer from configuration or identity input.
- **Scoped implementation:** acquire and release the owned client, handle, subscription, or process in the layer scope.
- **Pass-through requirement:** leave a requirement on methods only when every caller intentionally supplies that context.

The service constructor and the default fully wired live layer are distinct artifacts. Keep them separate when tests, alternative runtimes, or application compositions need different dependencies.

## Test substitutes

A full small fake is usually clearer than a partial mock. Put mutable fake state in the layer scope. Expose a test harness service only when assertions need to observe requests, state, or cleanup without reaching into private implementation details.
