# Effect OpenTelemetry patterns for agents — part 3

Covers:

- Build test seams around Tracer and HttpClient
- Keep platform-specific OpenTelemetry code out of domain modules
- Error handling patterns
- Let spans record the cause
- Keep exporter failures non-actionable
- Preserve typed domain errors
- Attribute and naming guidelines
- Span names

---

### Build test seams around `Tracer` and `HttpClient`

Test instrumentation without talking to a collector.

For span behavior, provide a custom `Tracer.Tracer` and inspect finished spans:

```ts
import * as Effect from "effect/Effect";
import * as Tracer from "effect/Tracer";

const collectSpanNames = <A, E, R>(
  effect: Effect.Effect<A, E, R>,
): Effect.Effect<ReadonlyArray<string>, E, R> =>
  Effect.gen(function* () {
    const spanNames: Array<string> = [];
    const tracer = Tracer.make({
      span: (options) => {
        const span = new Tracer.NativeSpan(options);
        const end = span.end.bind(span);
        span.end = (endTime, exit) => {
          end(endTime, exit);
          if (span.sampled) {
            spanNames.push(span.name);
          }
        };
        return span;
      },
    });

    yield* effect.pipe(Effect.withTracer(tracer));
    return spanNames;
  });
```

For OTLP payloads, provide a fake `HttpClient` and advance `TestClock` to trigger exports. This is the pattern in `.dotai/repos/effect/packages/effect/test/unstable/observability/OtlpMetrics.test.ts` and `.dotai/repos/effect/packages/effect/test/unstable/observability/OtlpExporter.test.ts`.

### Keep platform-specific OpenTelemetry code out of domain modules

For edge runtimes:

- Import `@effect/opentelemetry/Resource` and `@effect/opentelemetry/Tracer` subpaths instead of the barrel to avoid Node imports.
- Install one `WebTracerProvider` per isolate or application lifetime, not once per request, because deferred callbacks can outlive the request Effect scope.
- Expose telemetry setup as layers so application code remains Effect-native.

Use this pattern only for platform integration code. Domain modules should still use `Effect.withSpan` and metrics, not direct OpenTelemetry SDK objects.

## Error handling patterns

### Let spans record the cause

Both Effect OTLP and `@effect/opentelemetry` tracers inspect the span's `Exit` when the span ends:

- Success sets an OK status.
- Interrupt-only causes are treated as OK and annotated with `span.label = ⚠︎ Interrupted` and `status.interrupted = true`.
- Failures/defects are converted with `Cause.prettyErrors`, recorded as `exception` events, and set the span status to error.

Therefore:

- Do not catch an error only to log it for telemetry.
- Do not convert expected typed errors into defects so they look like exceptions.
- If a boundary catches an error for recovery, ensure the recovered behavior is intentional; the surrounding span will no longer represent a failed operation.
- If you need failure metrics while preserving failure semantics, use `Effect.exit` / `Effect.onExit` and then re-fail with the original cause.

### Keep exporter failures non-actionable

`OtlpExporter.make` retries transient HTTP failures, honors `retry-after` for `429`, disables export briefly after exporter failure, drops the current buffer, and logs at debug level. Exporter failures should not fail business operations.

Do not expose telemetry exporter errors from application services unless the service is explicitly an observability administration service.

### Preserve typed domain errors

Telemetry wrappers must be transparent in their type signatures:

```ts
const withSpanAndMetrics =
  (name: string) =>
  <A, E, R>(effect: Effect.Effect<A, E, R>): Effect.Effect<A, E, R> =>
    effect.pipe(withMetrics({ attributes: { operation: name } }), Effect.withSpan(name));
```

A caller should not see a new `TelemetryError` just because an operation is traced. If you add instrumentation to a service method, keep the method's existing typed error channel.

## Attribute and naming guidelines

### Span names

Use stable dotted names with domain-first prefixes:

- `voice-assessment.session.start`
- `voice-assessment.audio.transcribe`
- `voice-assessment.scoring.evaluate`
- `ws.rpc.assessment.submit`
- `server.startup.config.load`

### Attributes

Prefer low-cardinality attributes:

```ts
Effect.withSpan("plugin.mcp.connection.acquire", {
  attributes: {
    "plugin.mcp.transport": transport,
    "plugin.mcp.cache_hit": cacheHit,
    "plugin.mcp.attempt": 1,
  },
});
```

Use domain identifiers sparingly when they are necessary for support/debugging and safe to export. Avoid attributes that create unbounded cardinality in metrics. It can be acceptable for spans to include an operation target like `mcp.tool.name` or `startup.phase`; it is usually not acceptable for metrics to include raw user text, URLs with query parameters, tokens, or full error messages.

### Metrics

Define metrics centrally in an observability module, then update them at behavior boundaries.

Example pattern:

```ts
import * as Metric from "effect/Metric";

export const assessmentRequestsTotal = Metric.counter("assessment_requests_total", {
  description: "Total assessment requests handled by the server.",
});

export const assessmentRequestDuration = Metric.timer("assessment_request_duration", {
  description: "Assessment request duration.",
});
```

Use `Metric.withAttributes` at update sites so the attribute set is local to the observation.

## What to avoid

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

## Source map

- `.dotai/repos/effect/LLMS.md` — Effect service, span, error, and observability guidance.
- `.dotai/repos/effect/packages/opentelemetry/src/Tracer.ts` — bridge from Effect `Tracer` to OpenTelemetry spans, parent propagation, current OTel span, failure-to-exception mapping.
- `.dotai/repos/effect/packages/opentelemetry/src/NodeSdk.ts` and `WebSdk.ts` — OpenTelemetry SDK provider layers.
- `.dotai/repos/effect/packages/opentelemetry/src/Metrics.ts` and `Logger.ts` — metric producer registration and OTel log mapping.
- `.dotai/repos/effect/packages/effect/src/unstable/observability/OtlpTracer.ts`, `OtlpLogger.ts`, `OtlpMetrics.ts`, `OtlpExporter.ts`, `Otlp.ts` — lightweight OTLP exporter modules.
- `.dotai/repos/effect/packages/effect/test/unstable/observability/OtlpExporter.test.ts` and `OtlpMetrics.test.ts` — fake `HttpClient` and `TestClock` exporter tests.
