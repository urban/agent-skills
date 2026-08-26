# Configuration and module effects

## Configuration boundary

Read environment or deployment input in bootstrap or the earliest runtime boundary. Decode it into a typed configuration value before constructing application modules.

Distinguish:

- missing value
- malformed value
- unsupported combination
- secret value
- startup dependency failure

Startup failure should identify the configuration key or subsystem without revealing the secret value. Wrap credentials, API keys, passwords, and tokens in a redacted type at decode time. Keep them wrapped through application composition and unwrap only inside the adapter constructor or request that requires the raw value.

Do not let reusable modules call `process.env` directly. Doing so hides requirements, repeats parsing, complicates alternate runtimes, and makes tests depend on ambient process state.

## Import-time effects

Ordinary module evaluation should define values, types, functions, classes, and constructors. It should not:

- start a server or worker
- open a database or network connection
- read environment configuration
- register runtime handlers or listeners
- start timers or background loops
- mutate a global registry
- read ambient time or randomness

Put those actions in a true entrypoint or explicit bootstrap/resource function so ownership and shutdown are visible.

Some frameworks require registration or singleton state. Isolate that requirement in one boundary module and expose a normal replaceable interface inward. Do not let the exception become the application architecture.

## Resources and ambient capabilities

The code that creates a connection, process, subscription, server, or timer owns its release or transfers that ownership explicitly. Cleanup must cover success, failure, and cancellation where the runtime supports it.

Avoid mutable global state. Immutable constants and pure lookup tables are safe. For state that must be shared, choose and document its lifetime—request, tenant, test, process, or application—and construct it at that owner.

This skill owns the module-evaluation rule: do not read ambient time or randomness while defining a module. The architecture or runtime-specific testing guidance should decide how application operations receive those capabilities.
