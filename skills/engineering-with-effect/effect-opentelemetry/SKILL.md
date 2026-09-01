---
name: effect-opentelemetry
description: Design Effect telemetry around operator-useful boundaries, stable names, low-cardinality safe attributes, transparent failure semantics, exporter lifetime, and deterministic evidence. Use when choosing spans, metrics, logs, OTLP, or OpenTelemetry SDK integration.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Inspect installed Effect/OpenTelemetry layers, exporters, processors, propagation, and scheduling support before creating telemetry storage, batching loops, exporter lifecycles, or context propagation.
- Instrument operator-meaningful behavior and latency boundaries, not every helper.
- Keep telemetry transport/provider setup in layers at the application edge.
- Treat span and metric names and their stable attributes as operator-facing contracts.
- Preserve the original success, error, context, and cause semantics through instrumentation.

## Constraints

- Effect-native observability exporters currently use an unstable v4 module surface; verify imports and API details against the installed release.
- Never export secrets, credentials, raw prompts, bodies, transcripts, or unbounded user/model content by default.
- Metric attributes must have bounded cardinality; span attributes still require privacy and cost review.
- Exporter outages must not fail ordinary business operations unless observability administration is the feature.

## Knowledge Boundaries

Applies to:

- span boundaries and naming
- metrics, logs, attributes, cardinality, and privacy
- direct OTLP versus OpenTelemetry SDK integration
- exporter lifetime, flush, and deterministic telemetry tests

Does not cover:

- generic application error logging
- vendor-specific collector deployment

Decision inputs:

- operator question the telemetry should answer
- latency/failure boundary and expected volume
- attribute cardinality, sensitivity, and retention
- runtime/exporter lifetime and flush requirements

## Patterns

- Use direct Effect OTLP modules when an Effect-native exporter is sufficient; use the OpenTelemetry SDK bridge when existing processors, exporters, propagation, or platform integration require it.
- Give spans stable domain-first operation names. Add request-specific data only when safe and useful for diagnosis.
- Define metrics centrally and update them at behavior boundaries with bounded outcome, method, provider, or phase labels.
- Avoid duplicate error logs when a span already captures the failure; log when it adds an operator action or context not present in telemetry.
- For stream telemetry, measure the consumption lifetime and terminal exit, not merely construction of the stream value.
- Test instrumentation with fake tracers/export clients and logical time; assert semantic names, attributes, status/cause, payload, and flush behavior.

## Gotchas

- A custom telemetry store or export loop can duplicate standard processors while taking on batching, flushing, propagation, and shutdown correctness; prove the installed integration cannot meet the named requirement.
- Spanning every helper creates trace noise and raises cost while hiding meaningful critical paths.
- Catching failures to keep spans green changes business semantics and hides the original cause.
- IDs, URLs with queries, error messages, prompts, and payloads can explode cardinality or leak sensitive data.
- A per-request provider can be finalized while deferred callbacks still use it; align provider lifetime with callback lifetime.
- Export-loop tests based on sleeps are flaky and slow; drive scheduled export with logical time and a fake client.
- Testing only span names can miss wrong status, dropped causes, unsafe attributes, and broken exporter payloads.

## References

- [`references/instrumentation-semantics.md`](./references/instrumentation-semantics.md): Read when: choosing span/metric/log boundaries, transparent wrappers, stream lifetime, names, attributes, or privacy.
- [`references/exporters-and-testing.md`](./references/exporters-and-testing.md): Read when: choosing native OTLP versus SDK integration, provider lifetime, exporter failure policy, or deterministic tests.
