# Application architecture

Keep source modules and runtime capabilities distinct. A pure policy module, canonical schema, immutable command, or one-shot Effect function does not need a service just to appear in a dependency diagram. A service earns runtime identity through coherent replacement, configuration, shared state, resources, or captured construction.

Design public operations around caller vocabulary. Capture stable implementation requirements in the private capability that owns them; leave a requirement public only when supplying it is intentionally the caller's responsibility. A facade should hide graph shape or own cohesive cross-feature policy. Do not impose one application-wide facade or mechanically mirror every private method.

For a concrete service with construction policy, keep its supported default `make` and `layer` members on the service class. This is a discoverability convention for the intended implementation, not a reason to add construction to a contract-only service.

Give each actual runtime ownership domain an identifiable composition boundary. One process may have a host graph and bounded request-, tenant-, or job-specific graphs. Complete means complete for that domain, not eager acquisition of everything the executable could use. A library of ordinary values can leave composition entirely to its host.

Keep business ordering, authorization, and transaction policy in application behavior. Layer assembly selects implementations, configuration, visibility, and lifetime. Public exports should expose the supported capability surface, not every service needed to construct it.

**Tradeoff:** a private feature service with one caller can hide substantial policy, while a heavily reused wrapper can still be shallow. Judge the knowledge removed from callers rather than service count or file size.
