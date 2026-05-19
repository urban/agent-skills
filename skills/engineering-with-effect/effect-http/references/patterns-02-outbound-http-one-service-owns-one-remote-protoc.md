# Effect `HTTP` patterns for agents — part 2

Covers:

- Outbound HTTP: one service owns one remote protocol
- Modular, testable, maintainable services
- Keep transport injection explicit

---

### Outbound HTTP: one service owns one remote protocol

Effect's HTTP client docs model a service that captures `HttpClient.HttpClient`, applies common request transforms once, and exposes domain methods. Follow this pattern with injected client layers, explicit timeouts, and domain errors.

```ts
import { Context, Duration, Effect, flow, Layer, Schedule, Schema } from "effect";
import {
  FetchHttpClient,
  HttpClient,
  HttpClientRequest,
  HttpClientResponse,
} from "effect/unstable/http";

export const Transcript = Schema.Struct({
  id: Schema.String,
  text: Schema.String,
}).annotate({ identifier: "Transcript" });

export class TranscriptApiError extends Schema.TaggedErrorClass<TranscriptApiError>()(
  "TranscriptApiError",
  {
    reason: Schema.Literals(["RequestFailed", "MalformedResponse"]),
    cause: Schema.Defect,
  },
) {}

export interface TranscriptApiShape {
  readonly fetchTranscript: (
    id: string,
  ) => Effect.Effect<typeof Transcript.Type, TranscriptApiError>;
}

export class TranscriptApi extends Context.Service<TranscriptApi, TranscriptApiShape>()(
  "fiberisle/TranscriptApi",
) {
  static readonly layerNoDeps = (
    baseUrl: string,
  ): Layer.Layer<TranscriptApi, never, HttpClient.HttpClient> =>
    Layer.effect(
      TranscriptApi,
      Effect.gen(function* () {
        const client = (yield* HttpClient.HttpClient).pipe(
          HttpClient.mapRequest(
            flow(HttpClientRequest.prependUrl(baseUrl), HttpClientRequest.acceptJson),
          ),
          HttpClient.filterStatusOk,
          HttpClient.retryTransient({
            retryOn: "errors-and-responses",
            schedule: Schedule.exponential(100),
            times: 3,
          }),
        );

        const fetchTranscript: TranscriptApiShape["fetchTranscript"] = Effect.fnUntraced(
          function* (id) {
            const response = yield* client.get(`/transcripts/${id}`).pipe(
              Effect.timeout(Duration.seconds(20)),
              Effect.mapError(
                (cause) =>
                  new TranscriptApiError({
                    reason: "RequestFailed",
                    cause,
                  }),
              ),
            );

            return yield* HttpClientResponse.schemaBodyJson(Transcript)(response).pipe(
              Effect.mapError(
                (cause) =>
                  new TranscriptApiError({
                    reason: "MalformedResponse",
                    cause,
                  }),
              ),
            );
          },
        );

        return TranscriptApi.of({ fetchTranscript });
      }),
    );

  static readonly layer = (baseUrl: string): Layer.Layer<TranscriptApi> =>
    TranscriptApi.layerNoDeps(baseUrl).pipe(Layer.provide(FetchHttpClient.layer));
}
```

Guidelines:

- Apply base URLs, default headers, auth headers, retries, cookies, rate limits, and status filters by transforming the client once with `HttpClient.mapRequest`, `HttpClient.transformResponse`, `HttpClient.retryTransient`, `HttpClient.withCookiesRef`, or `HttpClient.withRateLimiter`.
- Keep request construction local to the protocol service. Use `HttpClientRequest.get/post/...`, `setHeader`, `setUrlParam`, `setUrlParams`, `bodyText`, `bodyUrlParams`, `bodyFormDataRecord`, `bodyStream`, and schema body helpers.
- Model remote failures as domain errors. Do not leak `HttpClientError` or `Schema.SchemaError` unless the service contract is explicitly a low-level HTTP helper.
- Use explicit status handling when non-2xx responses carry meaningful domain data. Use `HttpClient.filterStatusOk` when all non-2xx statuses are failures.
- Bound network effects with `Effect.timeout` and convert timeout, transport, status, and decode failures into specific tagged errors.

## Modular, testable, maintainable services

### Keep transport injection explicit

Accept an optional `httpClientLayer` and default to `FetchHttpClient.layer` at the API edge. That keeps tests deterministic without patching `globalThis.fetch`.

```ts
import { Effect, Layer } from "effect";
import { FetchHttpClient, HttpClient, HttpClientRequest } from "effect/unstable/http";

export interface ProbeOptions {
  readonly httpClientLayer?: Layer.Layer<HttpClient.HttpClient>;
}

const provideHttpClient = <A, E>(
  effect: Effect.Effect<A, E, HttpClient.HttpClient>,
  options: ProbeOptions,
): Effect.Effect<A, E> =>
  effect.pipe(Effect.provide(options.httpClientLayer ?? FetchHttpClient.layer));

export const ping = (url: string, options: ProbeOptions = {}): Effect.Effect<boolean> =>
  provideHttpClient(
    Effect.gen(function* () {
      const client = yield* HttpClient.HttpClient;
      const response = yield* client.execute(
        HttpClientRequest.get(url).pipe(HttpClientRequest.setHeader("accept", "application/json")),
      );
      return response.status >= 200 && response.status < 300;
    }),
    options,
  );
```

Use this shape for SDK-style helper functions. For application services, prefer depending on `HttpClient.HttpClient` in `layerNoDeps` and composing the default transport in a final `layer`.
