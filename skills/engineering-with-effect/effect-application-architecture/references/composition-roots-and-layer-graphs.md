# Composition roots and Layer graphs

## Translate dependency direction

Domain and application source dependencies point toward capabilities they consume. The provider graph runs in the other direction: infrastructure Layers construct low-level capabilities, feature Layers consume them, and public facade Layers consume the private features they hide.

A typical topology is:

```text
runtime adapters + validated configuration
                  ↓
infrastructure capability Layers
                  ↓
private feature Layers
                  ↓
public application Layer
                  ↓
entrypoint program
```

Pure domain modules do not appear in the Layer graph merely because feature implementations import them. A source import is not automatically a runtime requirement.

Compose by actual requirements and outputs. Dependencies used only to construct a private feature or facade should disappear from the downstream output. Keep a dependency visible only when another intentional consumer needs it. Operator choice, memoization, freshness, and scoped construction remain Layer-level mechanics rather than application-topology policy.

## Composition boundaries

Give each runtime ownership and sharing domain an explicit, identifiable composition boundary. A conventional server, worker, or command process usually has a named root. Framework-hosted, reactive, command-dispatched, request-, tenant-, or job-scoped applications may combine an outer root with nested or lazily selected graphs. Complete means complete for that ownership domain, not every graph in the executable. A library of ordinary values should leave runtime composition to its host.

The boundary owns:

- resolving runtime configuration at the appropriate composition or adapter edge
- selecting concrete infrastructure and runtime adapters
- constructing the configured graph for its ownership domain
- opening or receiving the scope that owns its resources
- providing that graph around the operations which share it
- publishing or handing off terminal results at the runtime edge when applicable

It does not own domain transitions, authorization policy, protocol rendering, retry decisions, or feature orchestration.

Construct long-lived dependencies once per intended sharing domain. If one entrypoint flow invokes several public operations, provide the same graph around that flow rather than separately around each call. Use nested graphs when request-, run-, tenant-, job-, subscription-, or framework-owned lifetimes need distinct identity and release.

## Configuration and dependency hiding

Resolve environment, files, flags, deployment metadata, or host values at a composition or adapter edge. Use explicit validated values or typed `Config` consumed during Layer construction. A feature should receive the resulting capability rather than repeatedly consult an ambient source during its operations.

Configuration belongs in the public application contract only when the embedding caller must choose it. Even then, expose the smallest stable configuration required to construct the supported public Layer; keep provider-specific credentials, client options, and migration controls behind infrastructure constructors when callers do not need them.

Capture common implementation dependencies once during Layer construction. A composition boundary may build a provider family or scoped router: validated input or application policy may select an already-wired capability or a bounded identity-specific child graph. Feature operations must not construct ad hoc long-lived production adapters or repeatedly reacquire shared resources.

## Lifetime alignment

The outer composition boundary owns the application scope, while individual Layers own acquisition and release for the resources they provide. Align each resource with the narrowest correct sharing domain:

- application-wide pools, exporters, and supervised infrastructure live in the application scope
- tenant- or configuration-specific clients live with that identity
- request or job resources live in the corresponding nested scope
- transaction values live only inside the transaction owner's callback

Do not reconstruct equivalent Layer values as an accidental way to request freshness. If sharing or isolation matters, make the lifetime boundary explicit and apply the focused Layer guidance for the operator-level design.
