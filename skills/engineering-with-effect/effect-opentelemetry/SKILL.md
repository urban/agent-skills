---
name: effect-opentelemetry
description: Instrument Effect applications with native spans, metrics, logs, OTLP or OpenTelemetry SDK layers, low-cardinality attributes, transparent wrappers, and deterministic telemetry tests. Use when adding or reviewing tracing, metrics, logging, OTLP exporters, @effect/opentelemetry integration, stream spans, telemetry layers, or tests for observability behavior.
---

## Native Effect Standards

- Prefer Effect-native instrumentation (`Effect.withSpan`, `Stream.withSpan`, `Effect.annotateSpans`, `Metric.*`, `Effect.log*`) over direct OpenTelemetry API calls in domain code.
- Prefer `effect/unstable/observability` OTLP modules for new exporter setup. Use `@effect/opentelemetry` when integrating with an existing OpenTelemetry SDK provider, processor, exporter, or platform constraint.
- Put telemetry setup in layers at the edge. Domain services should not know whether telemetry is exported to OTLP, an OpenTelemetry SDK provider, a local file, or nowhere.
- Instrument behavior boundaries: service methods, command handlers, RPC handlers, plugin invocations, startup phases, stream lifetimes, and resource acquisition. Do not span every small helper.
- Keep instrumentation semantics stable. Span names and metric names are operator-facing API.
- Let failures stay in the typed Effect error channel. Tracers record failed causes automatically when spans end.
- Avoid error-path logging. Add spans and metrics once at boundaries; do not duplicate every failure as logs.
- Use low-cardinality attributes. Include domain identifiers only when useful for debugging and safe to export. Never attach secrets, tokens, raw prompts, raw request bodies, or unbounded payloads.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not import OpenTelemetry SDK packages directly in domain code. Restrict them to telemetry setup modules.
- Do not use `fetch` directly for OTLP export; provide Effect `HttpClient` layers.
- Do not add manual logging for every failure path. Spans already capture failed causes.
- Do not create generic `TelemetryFailed` typed errors for exporter issues in normal application flows.
- Do not hide errors with `Effect.ignore` around business logic just to keep spans green.
- Do not wrap every function in a span. Spans should describe meaningful behavior and latency.
- Do not use high-cardinality or sensitive metric attributes.
- Do not attach raw request/response bodies, audio transcripts, model prompts, secrets, bearer tokens, or full generated outputs to spans or logs.
- Do not provide a per-request scoped OpenTelemetry provider when callbacks may outlive the request. Use an application/isolate lifetime layer or explicit flush strategy.
- Do not copy unsafe patterns from Effect internals into app code. The Effect source sometimes uses `any`, type assertions, `Effect.orDie`, and non-null assertions internally; this project forbids those in application code.
- Do not test exporters with wall-clock sleeps. Use `TestClock.adjust` and fake `HttpClient` / fake `Tracer` services.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- behavior boundaries that need operator-visible spans or metrics
- exporter/runtime constraints and resource attributes
- attribute safety and cardinality policy
- test seam for fake `Tracer` or `HttpClient` exporters

Effect-native code should tend toward:

- Effect-native instrumentation around meaningful boundaries
- telemetry exporter layers at the edge
- transparent span/metric combinators that preserve types
- tests with fake tracers or fake HTTP clients and `TestClock`

Applies to:

- applying Effect OpenTelemetry patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for adding spans, metrics, exporter layers, or SDK integration.
- Instrument service methods, handlers, commands, streams, startup phases, and resource acquisition only when they are meaningful operator boundaries.
- Use Effect-native APIs in domain code; keep OpenTelemetry SDK objects and exporter setup in edge layers.
- Choose direct OTLP observability modules or `@effect/opentelemetry` based on platform and integration constraints.
- Keep attributes low-cardinality and safe; never attach secrets, raw prompts, bodies, transcripts, or generated outputs.
- Make instrumentation transparent: preserve original success, error, and context types, and re-emit original causes after metrics observation.
- Test spans with fake `Tracer` services and exporters with fake `HttpClient` plus `TestClock`.

## Gotchas

- If every helper gets a span, traces become noise and important latency boundaries disappear. Span public behavior and meaningful internal phases only.
- If domain modules import OpenTelemetry SDK packages directly, platform-specific setup leaks everywhere. Keep SDK integration in telemetry layers.
- If errors are caught just to log telemetry, the span no longer records the original failure semantics. Let spans see the typed error channel or re-fail with the original cause.
- If metric attributes include IDs, URLs with queries, prompts, or raw messages, cardinality and privacy risk explode. Use low-cardinality attributes and safe domain labels.
- If exporter failures become service errors, observability outages break business operations. Keep exporter failures non-actionable for normal flows.
- If exporter tests wait on wall-clock intervals, they flake. Drive export loops with fake `HttpClient` and `TestClock`.

## References

- [`references/patterns-01-effect-opentelemetry-patterns-for-agents.md`](./references/patterns-01-effect-opentelemetry-patterns-for-agents.md): Read when: you need source-pattern detail for Effect OpenTelemetry patterns for agents, First principles, Choosing the module.
- [`references/patterns-02-encapsulate-cross-cutting-instrumentation-as-com.md`](./references/patterns-02-encapsulate-cross-cutting-instrumentation-as-com.md): Read when: you need source-pattern detail for Encapsulate cross-cutting instrumentation as combinators, Use spans for streams at the stream boundary, Disable tracing deliberately for noisy paths.
- [`references/patterns-03-build-test-seams-around-tracer-and-httpclient.md`](./references/patterns-03-build-test-seams-around-tracer-and-httpclient.md): Read when: you need source-pattern detail for Build test seams around Tracer and HttpClient, Keep platform-specific OpenTelemetry code out of domain modules, Error handling patterns.
