# Instrumentation semantics

## Span ownership follows the operation

Instrument service operations, handlers, commands, durable steps, startup phases, and resource acquisition when they answer an operator question. Distinguish acquisition latency from the entire resource lifetime; a process-long span rarely answers a request-latency question.

`Effect.withSpan` installs a child span for its region and ends it with the region's exit. `Effect.useSpan` gives a callback an automatically ended span without making it current. `Effect.makeSpanScoped` ends at scope closure but likewise does not install parent context. Use these distinctions to model ownership, not interchangeably as ways to obtain a span object. A manually created `Effect.makeSpan` needs an explicit completion owner; installing it with `withParentSpan` does not end it.

For streams, span consumption rather than the effect that constructs the stream:

```ts
import { Effect, Stream } from "effect"

const invoiceLines = Stream.fromArray(["line-a", "line-b"]).pipe(
  Stream.withSpan("billing.invoice.lines.read")
)

// The stream span covers pulls and terminates with consumption's exit.
const readLines = Stream.runCollect(invoiceLines).pipe(
  Effect.withSpan("billing.invoice.load")
)
```

Keep wrappers transparent: observe an exit rather than converting failure into success. A handled failure inside a span can legitimately yield a successful outer operation; put the span around the attempted operation if that failed attempt matters. Do not equate interruption with an application error: both native OTLP and the SDK bridge export pure interruption as Unset with `effect.fiber.interrupted`, not an exception event.

## Propagation expresses causality, not just matching IDs

Effect child work normally inherits its current parent. At external boundaries, distinguish:

- **Continuation:** decode the remote context and install it with `Effect.withParentSpan` around the new operation span. Use `Tracer.externalSpan` for a generic external parent or `OtelTracer.withSpanContext` for an OpenTelemetry `SpanContext`.
- **Independent work with a cause:** create a new root and link the originating span when a delayed job or fan-in should not appear to be nested request work. Links record causality without pretending the request owns the job's lifetime.
- **JavaScript re-entry:** an installed OpenTelemetry context manager lets the SDK bridge activate Effect spans for SDK instrumentation and inherit independently active OpenTelemetry parents. It does not make every `Effect.runPromise` inside a callback inherit an ambient Effect span. Capture and explicitly install the intended parent when crossing that boundary.

Prefer the existing HTTP integration over hand-written header injection. Effect's client normally creates a client span and injects both W3C `traceparent` and compact B3; server tracing reads incoming context. `HttpClient.TracerPropagationEnabled` can suppress outgoing headers without removing the local client span, useful for untrusted destinations or browser CORS restrictions. Disabling local span recording and suppressing outbound propagation are different policies.

Do not force `{ root: true }` on every handler: it deliberately discards parentage. Do not assign a live request span to detached work without deciding who owns and waits for that work; parent context alone does not extend either the span or provider lifetime.

## Names and metric series

Use stable domain-first names such as `billing.invoice.create` or `workflow.assessment.start`. Use a route template, not a concrete URL, as an operation dimension. Keep bounded attributes such as outcome, provider class, phase, or transport; put a reviewed identifier in a span/log field only when diagnosis needs it.

Each unique metric attribute combination creates a separate series. Budget the product of label value sets, not just each field independently. `Metric.withAttributes` and contextual `Metric.CurrentMetricAttributes` both affect series identity; adding request-specific metric context can multiply every metric updated underneath it. A frequency metric's observed strings also need a bounded vocabulary. Removing a series later does not undo the cost of exporting it.

Choose histogram boundaries and units around an operational threshold rather than recording a number with no interpretation. Choose cumulative versus delta temporality to match the collector/backend; do not reset business counters manually to simulate export intervals.

## Logs and privacy

Effect log annotations support correlation without rebuilding a custom logger. The native OTLP logger exports current trace/span IDs; the SDK logger populates OpenTelemetry context from the Effect parent when present. Log spans (`Effect.withLogSpan`) are elapsed-time log annotations, not distributed trace spans.

Both logger layers merge with existing loggers by default. Decide whether console and exported records are intentionally separate sinks or duplicate ingestion; replace existing loggers only deliberately. Exception messages and stack traces can be exported automatically from failed spans and log causes. Sanitizing only explicit attributes is therefore insufficient: keep sensitive payloads out of errors or provide a reviewed sanitization boundary.

## Source anchors (Effect v4)

- Ownership: `packages/effect/src/internal/effect.ts` (`useSpan`, `withSpan`, `makeSpanScoped`), `packages/effect/src/Channel.ts` (`withSpanImpl`), and `packages/effect/test/Tracer.test.ts`.
- Propagation: `packages/effect/src/http/HttpClient.ts`, `HttpMiddleware.ts`, `HttpTraceContext.ts`; `packages/opentelemetry/src/OtelTracer.ts` and `packages/opentelemetry/test/OtelTracer.test.ts` (JavaScript re-entry, active SDK parents, sampling, interruption).
- Series and logging: `packages/effect/src/Metric.ts`, `packages/effect/src/observability/OtlpLogger.ts`, and `packages/opentelemetry/src/OtelLogger.ts`.
