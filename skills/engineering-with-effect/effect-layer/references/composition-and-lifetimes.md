# Composition and lifetimes

## Graph semantics

- Merge independent providers whose requirements are already satisfied at that stage.
- Supply dependencies to a provider before merging it with peers that consume its output.
- Hide dependency outputs when they are implementation details.
- Retain dependency outputs only when downstream composition or a harness intentionally consumes them.

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

## Construction failures

Keep failures typed while callers can select fallback, report configuration, or retry startup. Convert them to defects only at a final boundary where continued operation is impossible and no caller can recover.
