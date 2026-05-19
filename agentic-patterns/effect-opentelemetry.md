# Effect OpenTelemetry patterns for agents

## First principles

- Prefer Effect-native instrumentation (`Effect.withSpan`, `Stream.withSpan`, `Effect.annotateSpans`, `Metric.*`, `Effect.log*`) over direct OpenTelemetry API calls in domain code.
- Prefer `effect/unstable/observability` OTLP modules for new exporter setup. Use `@effect/opentelemetry` when integrating with an existing OpenTelemetry SDK provider, processor, exporter, or platform constraint.
- Put telemetry setup in layers at the edge. Domain services should not know whether telemetry is exported to OTLP, an OpenTelemetry SDK provider, a local file, or nowhere.
- Instrument behavior boundaries: service methods, command handlers, RPC handlers, plugin invocations, startup phases, stream lifetimes, and resource acquisition. Do not span every small helper.
- Keep instrumentation semantics stable. Span names and metric names are operator-facing API.
- Let failures stay in the typed Effect error channel. Tracers record failed causes automatically when spans end.
- Avoid error-path logging. Add spans and metrics once at boundaries; do not duplicate every failure as logs.
- Use low-cardinality attributes. Include domain identifiers only when useful for debugging and safe to export. Never attach secrets, tokens, raw prompts, raw request bodies, or unbounded payloads.

## Choosing the module

### Use `effect/unstable/observability` for direct OTLP export

The lightweight OTLP modules build Effect `Tracer`, `Logger`, and metric exporters without installing the OpenTelemetry SDK. They require an `HttpClient`, an `OtlpSerialization` layer, and a scope.

```ts
import { FetchHttpClient } from "effect/unstable/http";
import {
  OtlpLogger,
  OtlpMetrics,
  OtlpSerialization,
  OtlpTracer,
} from "effect/unstable/observability";
import { Layer } from "effect";

const resource = {
  serviceName: "voice-assessment-agent",
  serviceVersion: "1.0.0",
  attributes: {
    "deployment.environment": "production",
  },
} as const;

export const ObservabilityLive = Layer.mergeAll(
  OtlpTracer.layer({
    url: "https://otel.example.com/v1/traces",
    resource,
    exportInterval: "5 seconds",
  }),
  OtlpLogger.layer({
    url: "https://otel.example.com/v1/logs",
    resource,
    exportInterval: "1 second",
    mergeWithExisting: true,
  }),
  OtlpMetrics.layer({
    url: "https://otel.example.com/v1/metrics",
    resource,
    exportInterval: "10 seconds",
    temporality: "cumulative",
  }),
).pipe(Layer.provide(OtlpSerialization.layerJson), Layer.provide(FetchHttpClient.layer));
```

Use `Otlp.layerJson` / `Otlp.layerProtobuf` when all three signals share a base URL and the same resource.

### Use `@effect/opentelemetry` for existing OpenTelemetry SDK integration

`@effect/opentelemetry` bridges Effect spans/logs/metrics to official OpenTelemetry SDK providers. `NodeSdk.layer` and `WebSdk.layer` compose tracing, logging, and metrics based on which processors/readers are present.

```ts
import * as NodeSdk from "@effect/opentelemetry/NodeSdk";
import { InMemorySpanExporter, SimpleSpanProcessor } from "@opentelemetry/sdk-trace-base";
import { Effect } from "effect";

const TracingLive = NodeSdk.layer(() => ({
  resource: {
    serviceName: "test",
  },
  spanProcessor: [new SimpleSpanProcessor(new InMemorySpanExporter())],
}));

const program = Effect.gen(function* () {
  yield* Effect.logInfo("work started");
  return "ok";
}).pipe(Effect.withSpan("voice-assessment.run"), Effect.provide(TracingLive));
```

Use subpath imports in edge runtimes. Avoid the `@effect/opentelemetry` barrel when it imports Node SDK code that is invalid in Cloudflare Workers.

## Behavior encapsulation

### Instrument public behavior, not implementation noise

A service method should describe the operator-visible action. Internal helpers can stay untraced unless they represent separately useful latency or failure boundaries.

```ts
import { Context, Effect, Layer } from "effect";

interface AssessmentInput {
  readonly sessionId: string;
}

export class VoiceAssessment extends Context.Service<
  VoiceAssessment,
  {
    readonly assess: (input: AssessmentInput) => Effect.Effect<void>;
  }
>()("app/VoiceAssessment") {
  static readonly layer = Layer.effect(
    VoiceAssessment,
    Effect.gen(function* () {
      return VoiceAssessment.of({
        assess: (input) =>
          Effect.gen(function* () {
            yield* Effect.annotateCurrentSpan("assessment.session_id", input.sessionId);
            yield* Effect.logInfo("assessment started");
            yield* Effect.sleep("20 millis").pipe(Effect.withSpan("voice-assessment.transcribe"));
            yield* Effect.sleep("10 millis").pipe(Effect.withSpan("voice-assessment.score"));
          }).pipe(
            Effect.withSpan("voice-assessment.assess", {
              attributes: { "assessment.session_id": input.sessionId },
            }),
          ),
      });
    }),
  );
}
```

For this project, if you write an Effect-returning wrapper only to add a span, use `Effect.fn("name")`. If a wrapper is not meant to create a span, use `Effect.fnUntraced`. Do not wrap `Effect.gen` in ad hoc lambdas.

### Encapsulate cross-cutting instrumentation as combinators

Do not scatter counter/timer/span wiring across handlers. Write one generic combinator that preserves the original success, error, and context types.

Example pattern:

```ts
import * as Clock from "effect/Clock";
import * as Duration from "effect/Duration";
import * as Effect from "effect/Effect";
import * as Exit from "effect/Exit";
import * as Metric from "effect/Metric";

export interface WithMetricsOptions {
  readonly counter?: Metric.Metric<number, unknown>;
  readonly timer?: Metric.Metric<Duration.Duration, unknown>;
  readonly attributes?: Readonly<Record<string, unknown>>;
}

export const withMetrics =
  (options: WithMetricsOptions) =>
  <A, E, R>(effect: Effect.Effect<A, E, R>): Effect.Effect<A, E, R> =>
    Effect.gen(function* () {
      const startedAt = yield* Clock.currentTimeNanos;
      const exit = yield* Effect.exit(effect);
      const endedAt = yield* Clock.currentTimeNanos;
      const elapsed = Duration.nanos(endedAt > startedAt ? endedAt - startedAt : 0n);
      const attributes = options.attributes ?? {};

      if (options.timer) {
        yield* Metric.update(Metric.withAttributes(options.timer, attributes), elapsed);
      }

      if (options.counter) {
        yield* Metric.update(
          Metric.withAttributes(options.counter, {
            ...attributes,
            outcome: Exit.isSuccess(exit) ? "success" : "failure",
          }),
          1,
        );
      }

      if (Exit.isSuccess(exit)) {
        return exit.value;
      }
      return yield* Effect.failCause(exit.cause);
    });
```

Key points:

- Capture `Exit` to record metrics for both success and failure.
- Re-emit failures with `Effect.failCause(exit.cause)` so callers and spans see the original cause.
- Use `Clock.currentTimeNanos` so tests can use `TestClock`.

### Use spans for streams at the stream boundary

Stream lifetimes differ from effect construction. Use `Stream.withSpan` and `Stream.onExit` so duration and failure represent stream consumption, not just creation.

Example pattern:

```ts
import * as Clock from "effect/Clock";
import * as Duration from "effect/Duration";
import * as Effect from "effect/Effect";
import * as Exit from "effect/Exit";
import * as Metric from "effect/Metric";
import * as Stream from "effect/Stream";

const rpcRequestsTotal = Metric.counter("app_rpc_requests_total");
const rpcRequestDuration = Metric.timer("app_rpc_request_duration");

const recordRpcStreamMetrics = <E>(
  method: string,
  startedAt: bigint,
  exit: Exit.Exit<unknown, E>,
): Effect.Effect<void> =>
  Effect.gen(function* () {
    const endedAt = yield* Clock.currentTimeNanos;
    const elapsed = Duration.nanos(endedAt > startedAt ? endedAt - startedAt : 0n);

    yield* Metric.update(Metric.withAttributes(rpcRequestDuration, { method }), elapsed);
    yield* Metric.update(
      Metric.withAttributes(rpcRequestsTotal, {
        method,
        outcome: Exit.isSuccess(exit) ? "success" : "failure",
      }),
      1,
    );
  });

export const observeRpcStream = <A, E, R>(
  method: string,
  stream: Stream.Stream<A, E, R>,
): Stream.Stream<A, E, R> =>
  Stream.unwrap(
    Effect.gen(function* () {
      const startedAt = yield* Clock.currentTimeNanos;
      return stream.pipe(Stream.onExit((exit) => recordRpcStreamMetrics(method, startedAt, exit)));
    }),
  ).pipe(
    Stream.withSpan(`rpc.${method}`, {
      attributes: {
        "rpc.system": "effect-rpc",
        "rpc.method": method,
      },
    }),
  );
```

### Disable tracing deliberately for noisy paths

For diagnostics or trace-inspection endpoints, disable tracing at the boundary rather than relying on every child to remember not to span.

Example pattern:

```ts
import * as Effect from "effect/Effect";
import * as References from "effect/References";

const tracingDisabledMethods: ReadonlySet<string> = new Set([
  "server.getTraceDiagnostics",
  "server.getProcessDiagnostics",
]);

const shouldTrace = (method: string): boolean => !tracingDisabledMethods.has(method);

export const withRpcTracing = <A, E, R>(
  method: string,
  effect: Effect.Effect<A, E, R>,
): Effect.Effect<A, E, R> =>
  shouldTrace(method)
    ? effect.pipe(
        Effect.withSpan(`ws.rpc.${method}`, {
          attributes: { "rpc.method": method, "rpc.transport": "websocket" },
        }),
      )
    : effect.pipe(Effect.provideService(References.TracerEnabled, false));
```

## Modular, testable, maintainable services

### Keep exporter lifecycle in layers

Telemetry exporters need scopes, finalizers, intervals, and sometimes platform-specific resources. Hide that lifecycle in layers.

- `OtlpTracer.layer`, `OtlpLogger.layer`, and `OtlpMetrics.layer` add scoped background export loops and final flushes through `OtlpExporter.make`.
- `@effect/opentelemetry/NodeSdk.layer` builds provider, tracer, logger, and metric layers from one configuration effect.
- Use `Layer.unwrap` when configuration decides whether telemetry exists.
- Use `Layer.empty` when telemetry is disabled. Effect's native tracer is safe as a no-op, so application spans can remain in place.

Example pattern:

```ts
import * as Effect from "effect/Effect";
import * as Layer from "effect/Layer";

const isTelemetryDisabled: Effect.Effect<boolean> = Effect.succeed(false);

declare const buildOtlpLayer: (attributes: Readonly<Record<string, unknown>>) => Layer.Layer<never>;

export const TelemetryLive: Layer.Layer<never> = Layer.unwrap(
  Effect.gen(function* () {
    if (yield* isTelemetryDisabled) {
      return Layer.empty;
    }

    return buildOtlpLayer({
      "service.runtime": "cli",
    });
  }),
);
```

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

For OTLP payloads, provide a fake `HttpClient` and advance `TestClock` to trigger exports. This is the pattern in `repos/effect/packages/effect/test/unstable/observability/OtlpMetrics.test.ts` and `repos/effect/packages/effect/test/unstable/observability/OtlpExporter.test.ts`.

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

- `repos/effect/LLMS.md` — Effect service, span, error, and observability guidance.
- `repos/effect/packages/opentelemetry/src/Tracer.ts` — bridge from Effect `Tracer` to OpenTelemetry spans, parent propagation, current OTel span, failure-to-exception mapping.
- `repos/effect/packages/opentelemetry/src/NodeSdk.ts` and `WebSdk.ts` — OpenTelemetry SDK provider layers.
- `repos/effect/packages/opentelemetry/src/Metrics.ts` and `Logger.ts` — metric producer registration and OTel log mapping.
- `repos/effect/packages/effect/src/unstable/observability/OtlpTracer.ts`, `OtlpLogger.ts`, `OtlpMetrics.ts`, `OtlpExporter.ts`, `Otlp.ts` — lightweight OTLP exporter modules.
- `repos/effect/packages/effect/test/unstable/observability/OtlpExporter.test.ts` and `OtlpMetrics.test.ts` — fake `HttpClient` and `TestClock` exporter tests.
