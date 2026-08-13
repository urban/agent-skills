# Runtime semantics

## Function boundaries

- Choose a reusable Effect function when it accepts domain input, gives an operation a stable identity, or owns a tracing boundary; otherwise keep the computation as a value.
- Trace only when the operation should appear independently in latency and failure analysis.

## Expected failure and defect policy

| Outcome | Model as | Reason |
| --- | --- | --- |
| Caller can recover, retry, ask for input, or choose another path | Typed expected error | Recovery belongs in the public contract |
| Dependency detail changes no caller decision | Boundary-owned translation or terminal handling | Avoid infrastructure unions without turning operational failures into defects |
| Broken invariant, impossible state, programmer fault | Defect | Recovery would hide corruption or a bug |
| External data violates an accepted contract | Typed boundary error | The boundary can explain what was rejected |

Preserve a cause when it helps operators diagnose the external failure. Do not expose opaque causes as a substitute for a useful domain taxonomy.

## Requirements and lifetime

Capture a requirement in the layer that owns the implementation. Pass it through a public effect only when the caller is intentionally responsible for supplying that capability, such as a request or transaction context.

Choose fiber ownership explicitly:

- child: tied to the parent operation
- scoped: tied to an enclosing resource scope
- detached: independently supervised with explicit shutdown
- in-scope: tied to a chosen scope rather than the immediate parent

Interruption is not an ordinary typed failure. Resource finalizers and protocol cleanup must run on interruption as well as normal completion.

## Causes

Inspect Cause when behavior depends on the distinction between expected failure, defect, and interruption. Keep Cause intact through transparent instrumentation; pretty-print it only at a human or wire boundary.
