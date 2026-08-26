# Public boundaries and layers

Choose the closest stable caller surface:

- pure domain function for a pure invariant
- service method for application capability
- typed client or handler for protocol behavior
- Stream for incremental behavior
- process/CLI service for command integration
- workflow/entity public client for durable/runtime semantics

Preserve production composition behind that surface. Replace network, process, storage, time, randomness, model provider, or another true external boundary.

Allocate mutable fake state inside the test layer. Build per test for isolation; share only when setup cost or shared-state behavior justifies it. Expose a harness service for controlled observations such as captured requests or persisted rows rather than reaching into private refs.

Use higher fidelity when the behavior depends on serialization, routing, middleware, resource lifetime, or runtime adapters.
