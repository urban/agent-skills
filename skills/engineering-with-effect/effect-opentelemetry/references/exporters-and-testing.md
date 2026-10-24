# Exporters and testing

## Select one owner for each signal

Choose Effect-native OTLP exporters for direct OTLP/HTTP through Effect services. Choose the OpenTelemetry SDK bridge when existing SDK processors, readers, exporters, or ambient context integration are required. Avoid installing two tracers or exporting the same logs/metric series through both stacks unintentionally.

Native configuration can stay entirely at the application edge:

```ts
import { Layer } from "effect"
import { FetchHttpClient } from "effect/http"
import { Otlp } from "effect/observability"

const Telemetry = Otlp.layerJson({
  baseUrl: "http://localhost:4318",
  resource: { serviceName: "billing" },
  shutdownTimeout: "3 seconds"
}).pipe(Layer.provide(FetchHttpClient.layer))
```

This installs logs, metrics, and traces with JSON serialization and appends their `/v1/*` paths. Use individual signal layers for selective installation. Resource metadata describes the service/deployment, not a request or tenant.

For the SDK bridge, `NodeSdk.layer` enables tracing only when a `spanProcessor` is supplied, metrics only with a `metricReader`, and logging only with a `logRecordProcessor`. A resource-only configuration does not enable those signals. Create processors/readers for each layer build rather than reusing already-bound SDK objects across independent runtimes. The bridge's metric producer reads Effect metrics; a separate SDK meter is not a replacement for those instruments.

## Lifetime and delivery policy

Exporter layers own background work and shutdown. Keep them alive until all emitting operations, stream consumers, and callbacks have completed. Stop producers before closing their provider; finalization cannot export spans that have not yet ended. A request-scoped exporter is appropriate only if no work can outlive that request and its setup/shutdown cost is intentional.

Native export suppresses tracing and propagation for its own HTTP traffic, retries transient failures, honors `Retry-After` for 429, and temporarily disables export after an unhandled failure. During that disable window telemetry can be dropped and flush can be a no-op. Do not wrap it in another tracing/retry loop as a substitute for a delivery requirement.

Native scope finalization flushes remaining buffered data and waits for tracked in-flight exports, bounded by `shutdownTimeout`. The SDK tracer and logger providers force-flush and shut down; SDK metric readers are shut down by their layer. Shutdown is best-effort and bounded, not an acknowledgment that all data reached durable storage. Abrupt process termination bypasses these guarantees.

For a checkpoint while the native layer is still alive, obtain `OtlpExporter.Flusher` from an individual signal layer. Its `flush` drains exporters registered with the shared `layerFlusher`; it cannot fail, has no built-in timeout, and only waits for exports it initiates, not already-running interval exports. Bound it with `Effect.timeoutOption` when the caller has a latency budget. Share one registry across the signals you intend to drain; flushing a fresh unrelated registry is a successful no-op.

## Tests at the semantic seam

Use `Tracer.make` with `Tracer.NativeSpan` to inspect ownership without any collector. This example distinguishes a real parent chain from two spans that merely have correct names:

```ts
import { assert, it } from "@effect/vitest"
import { Effect, Exit, Tracer } from "effect"

it.effect("invoice span owns the repository child and records failure", () => {
  const spans: Array<Tracer.Span> = []
  const tracer = Tracer.make({
    span(options) {
      const span = new Tracer.NativeSpan(options)
      spans.push(span)
      return span
    }
  })
  return Effect.gen(function*() {
    const exit = yield* Effect.fail("declined").pipe(
      Effect.withSpan("billing.invoice.persist"),
      Effect.withSpan("billing.invoice.create"),
      Effect.exit
    )
    assert.isTrue(Exit.isFailure(exit))
    const parent = spans.find((span) => span.name === "billing.invoice.create")!
    const child = spans.find((span) => span.name === "billing.invoice.persist")!
    assert.strictEqual(child.parent.valueOrUndefined, parent)
    assert.strictEqual(parent.status._tag, "Ended")
    assert.strictEqual(child.status._tag, "Ended")
    if (child.status._tag === "Ended") {
      assert.isTrue(Exit.isFailure(child.status.exit))
    }
  }).pipe(Effect.withTracer(tracer))
})
```

Add domain cases for handled failures versus failed attempts and interrupted consumption. For serialization tests, assert that a business error becomes an exception event while pure interruption remains Unset with `effect.fiber.interrupted`. Native span state retains an Effect exit; it is not itself an OTLP status code.

Use a fresh `Metric.MetricRegistry` (`new Map()`) for isolated metric tests and provide that same registry to the producer/exporter and the instrumented program. The default registry is shared; creating another metric value with the same name does not isolate state. Assert the expected series/attributes, not just a global count. For delta temporality, cover successive exports and failed delivery without manually resetting counters.

For native exporter tests, use a fake `HttpClient` to capture encoded requests and control response status. Use `TestClock` for intervals and retry delays, and `Deferred` barriers to distinguish request start from completion. Closing a scope while a fake request is blocked tests whether shutdown really waits; a timeout case tests bounded shutdown. A successful immediate HTTP response alone cannot expose that race. For SDK tracing, use `InMemorySpanExporter` and `SimpleSpanProcessor`; inspect finished spans before provider teardown when the in-memory exporter clears its data on shutdown.

## Source anchors (Effect v4)

- Configuration/lifecycle: `packages/effect/src/observability/Otlp.ts`, `OtlpExporter.ts`, `OtlpMetrics.ts`; `packages/opentelemetry/src/NodeSdk.ts`, `OtelLogger.ts`, `OtelMetrics.ts`.
- Test models: `packages/effect/test/Tracer.test.ts`, `packages/effect/test/observability/OtlpExporter.test.ts`, `OtlpTracer.test.ts`, `OtlpMetrics.test.ts`; `packages/opentelemetry/test/OtelTracer.test.ts`.
- Registry isolation: `packages/effect/src/Metric.ts` (`MetricRegistry`).
