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

## Composition roots

Give each executable or independently started runtime one named composition root. A server, worker, command process, or independently hosted background runtime may each have its own root because each owns a different application lifetime. A repository does not need one global root, and a library of ordinary values should leave runtime composition to its host.

The root owns:

- resolving and validating explicit runtime configuration
- selecting concrete infrastructure and runtime adapters
- constructing the configured application graph
- opening the scope that owns application resources
- providing the graph around the complete application program
- publishing or handing off the program's terminal result at the runtime edge

It does not own domain transitions, authorization policy, protocol rendering, retry decisions, or feature orchestration.

Construct the graph once per intended sharing domain. If one entrypoint flow invokes several public operations, provide the same graph around the entire flow rather than separately around each call. Long-lived runtimes similarly retain one application scope unless request-, tenant-, or job-specific ownership requires a nested graph with a distinct identity.

## Configuration and dependency hiding

Read environment, files, flags, deployment metadata, or host values at an adapter boundary. Decode them into explicit configuration before choosing or parameterizing live Layers. A feature should receive the resulting capability, not repeatedly consult an ambient source.

Configuration belongs in the public application contract only when the embedding caller must choose it. Even then, expose the smallest stable configuration required to construct the supported public Layer; keep provider-specific credentials, client options, and migration controls behind infrastructure constructors when callers do not need them.

Capture common implementation dependencies once during Layer construction. Public operations must not provide production Layers internally: internal provision fixes the implementation, can reacquire scoped resources, and prevents a multi-call program from sharing one graph.

## Lifetime alignment

The composition root owns the outer application scope, while individual Layers own acquisition and release for the resources they provide. Align each resource with the narrowest correct sharing domain:

- application-wide pools, exporters, and supervised infrastructure live in the application scope
- tenant- or configuration-specific clients live with that identity
- request or job resources live in the corresponding nested scope
- transaction values live only inside the transaction owner's callback

Do not reconstruct equivalent Layer values as an accidental way to request freshness. If sharing or isolation matters, make the lifetime boundary explicit and apply the focused Layer guidance for the operator-level design.
