---
name: effect-opentelemetry
description: Design Effect telemetry around operator-useful boundaries, span ownership and propagation, low-cardinality safe attributes, transparent failure semantics, and exporter lifetime. Use when choosing spans, metrics, logs, OTLP, or OpenTelemetry SDK integration.
---

## Rules

- Instrument operator-meaningful behavior and latency boundaries, not every helper.
- Keep telemetry transport/provider setup in layers at the application edge; use the supplied exporters and processors rather than inventing batching or shutdown loops.
- Choose span lifetime and parent context separately. The owner of the operation must also own span completion.
- Treat span and metric names and their stable attributes as operator-facing contracts.
- Preserve business success, failure, and interruption through instrumentation; do not catch failures merely to keep spans green.
- Make propagation across HTTP, JavaScript callbacks, and background work an explicit boundary decision.

## Constraints

- Effect v4 native OTLP modules live under `effect/observability`; the SDK bridge lives in `@effect/opentelemetry`. These integrations are unstable surfaces.
- Never export secrets, credentials, raw prompts, bodies, transcripts, or unbounded user/model content by default. Review automatically recorded exceptions and HTTP attributes too.
- Metric attributes must have bounded cardinality; span and log attributes still require privacy, retention, and cost review.
- Exporter outages must not fail ordinary business operations unless observability administration is the feature. Best-effort export is not durable audit storage.

## Knowledge Boundaries

Applies to:

- span boundaries, ownership, parentage, and naming
- metrics, correlated logs, attributes, cardinality, and privacy
- direct OTLP versus OpenTelemetry SDK integration
- exporter lifetime, flush, and deterministic telemetry tests

Does not cover:

- generic application error logging
- vendor-specific collector deployment

Decision inputs:

- operator question the telemetry should answer
- latency/failure boundary, cancellation policy, and expected volume
- attribute cardinality, sensitivity, and retention
- runtime/exporter lifetime, callback ownership, and flush requirements
- existing HTTP instrumentation and OpenTelemetry context integration

## Patterns

- Use direct Effect OTLP modules when Effect-native export is sufficient; use the SDK bridge for existing OpenTelemetry processors, readers, exporters, or context integration.
- Use an effect region for an operation span, a scope for a resource-lifetime span, and stream instrumentation for consumption. Do not span only the construction of deferred work.
- Continue a trace with a parent only when the work belongs to that operation; use links for independent work with causal relationships.
- Define metrics centrally and update them at behavior boundaries with bounded outcome, method, provider class, or phase attributes.
- Log when it adds an operator action or contextual event, not just to repeat a failure already captured by a span.
- Test business exits and parent chains separately from serialized export and shutdown behavior.

## Gotchas

- Spanning every helper creates trace noise and raises cost while hiding critical paths; prefer a boundary whose latency or failure changes an operator decision.
- `makeSpanScoped` closes a span but does not install it as parent. Assuming otherwise produces sibling spans; use `withSpan` or explicitly install the parent where nesting is intended.
- Wrapping an effect that returns a stream ends the span before consumption; use `Stream.withSpan` or wrap the consuming effect.
- Re-entering Effect from JavaScript is not ordinary child-fiber inheritance. A copied service context does not guarantee the ambient Effect parent; carry the parent explicitly when continuation is intended.
- Request IDs and free text in metric attributes create new series, even when attached contextually. Keep them out of metric context and use reviewed trace/log fields instead.
- A per-request provider can close before callbacks emit or spans end; keep the exporter alive through all emitting work and close it afterward.
- A successful flush does not prove collector delivery: native export is best-effort and may be disabled after failures. Keep audit durability separate.
- Testing only span names misses wrong parents, cancellation classification, sensitive exception data, and dropped shutdown payloads; assert those semantics at their respective seams.

## References

- [`references/instrumentation-semantics.md`](./references/instrumentation-semantics.md): Read when: choosing span ownership, propagation, stream boundaries, metric attributes, or correlated logs.
- [`references/exporters-and-testing.md`](./references/exporters-and-testing.md): Read when: choosing native OTLP versus SDK integration, exporter lifetime, flush policy, or deterministic telemetry tests.
