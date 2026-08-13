# Source adapters

## Ownership

- Per-subscriber source: acquire inside stream setup; release when that subscription ends.
- Shared fan-out source: own producer and subscription lifecycle in a service; expose a domain stream.
- Caller-owned handle: expose only when callers genuinely control pause, close, seek, or process lifecycle.

## Push sources

Choose buffer behavior explicitly:

- suspend/backpressure when producer supports it
- bounded drop/sliding only when loss semantics are acceptable
- fail on overflow when data loss must be visible
- unbounded only with a demonstrated finite producer bound

Register callback unsubscription and handle closure in the source scope. Ensure interruption triggers the same cleanup as normal completion.

## External readers

Use platform adapters for Web/Node/process sources. Preserve byte-stream semantics until decoding. A transport chunk is not a protocol frame.
