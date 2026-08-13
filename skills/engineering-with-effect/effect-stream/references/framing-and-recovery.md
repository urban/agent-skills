# Framing and recovery

Decode in stages:

1. bytes to text with incremental decoder state
2. text to protocol frames or lines
3. frame payload to schema values
4. schema values to domain events

Use established NDJSON and SSE channels when available. They handle partial chunks and protocol details that line splitting alone may miss.

## Failure semantics

- Source/transport failure remains in the stream error channel.
- Decode failure becomes a typed protocol error.
- A remote error frame is decoded back into the error channel when the local API promises failure semantics.
- Failure becomes an ordinary data frame only when the wire protocol explicitly models it that way.

## Retry and repeat

Retry rebuilds after failure; repeat rebuilds after success. Both may duplicate emitted values. Require offset, sequence, resume token, deduplication, or explicit at-least-once acceptance when reconnecting after partial output.
