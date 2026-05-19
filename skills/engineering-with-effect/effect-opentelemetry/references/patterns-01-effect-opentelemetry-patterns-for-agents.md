# Effect OpenTelemetry patterns for agents — part 1

Covers:

- Effect OpenTelemetry patterns for agents
- First principles
- Choosing the module
- Use effect/unstable/observability for direct OTLP export
- Use @effect/opentelemetry for existing OpenTelemetry SDK integration
- Behavior encapsulation
- Instrument public behavior, not implementation noise

---

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
