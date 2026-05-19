# Effect OpenTelemetry patterns for agents — part 2

Covers:

- Encapsulate cross-cutting instrumentation as combinators
- Use spans for streams at the stream boundary
- Disable tracing deliberately for noisy paths
- Modular, testable, maintainable services
- Keep exporter lifecycle in layers

---

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
