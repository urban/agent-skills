# Composition and lifetimes

## Graph semantics

- Merge independent providers whose requirements are already satisfied at that stage.
- Supply dependencies to a provider before merging it with peers that consume its output.
- Use `Layer.provide` when supplied dependency outputs are implementation details that should disappear from the resulting graph.
- Use `Layer.provideMerge` only when downstream composition or a harness intentionally consumes the supplied capabilities as part of the result.
- Treat a Layer value as an already deferred acquisition recipe; wrapping it in a zero-argument function changes the API without adding useful laziness.
- Use `Layer.unwrap` when an Effect genuinely selects or constructs a Layer at runtime, with its requirements and construction failures represented honestly.

## Sharing

A layer value is memoized within its memoization context. Decide the sharing domain:

| Resource | Typical sharing |
| --- | --- |
| Process-wide pool or telemetry exporter | One application scope |
| Tenant-specific client | One tenant/config identity |
| Request I/O handle | One request scope |
| Test mutable state | One test unless sharing is intentional |

Freshness creates another acquisition. It is correct for independent state, not as a generic repair for accidental mutation or unclear ownership.

## Scoped construction

Acquire owned resources in layer construction and register release in the same scope. Interruption during partial graph construction must still release resources already acquired.

Manual layer building is justified at runtime boundaries such as request-specific memoization, plugin isolation, or a host that explicitly manages a child scope. It is not ordinary service-method composition.

Providing a Layer inside a service operation is justified only when runtime policy deliberately controls activation or lifetime at that operation boundary. Capture the Layer recipe during service construction, acquire it in the operation scope, and preserve the wrapped Effect's success, expected failure, defect, and interruption semantics. State the lifetime reason near the boundary so nested provision is recognizable as ownership rather than incidental wiring.

## Construction failures

Keep failures typed while callers can select fallback, report configuration, or retry startup. Convert them to defects only at a final boundary where continued operation is impossible and no caller can recover.
