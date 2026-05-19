# Effect `HTTP` patterns for agents

These notes capture the project patterns for writing Effect HTTP code. They are based on `repos/effect/packages/effect/src/unstable/http`, `repos/effect/packages/effect/src/unstable/httpapi`, `repos/effect/packages/effect/HTTPAPI.md`, the HTTP tests under `repos/effect/packages/**/test`, and HTTP usage in `repos/executor`, `repos/alchemy-effect`, and `repos/t3code`.

## First principles

- Prefer Effect HTTP primitives at boundaries: `HttpClient.HttpClient`, `HttpClientRequest.HttpClientRequest`, `HttpClientResponse.HttpClientResponse`, `HttpServerRequest.HttpServerRequest`, and `HttpServerResponse.HttpServerResponse`.
- Prefer `HttpApi` for first-party APIs. Define the schema contract once, then derive server handlers, OpenAPI, and typed clients from it.
- Keep API definitions shareable. Put `HttpApiGroup` schemas in a module that has no server-only, browser-only, or runtime-specific imports.
- Encapsulate outbound HTTP behind services. Callers should use domain methods such as `fetchTranscript`, `registerClient`, or `probeEndpoint`, not raw `client.execute` calls.
- Depend on `HttpClient.HttpClient` in reusable code and provide a transport layer at the edge. Use `FetchHttpClient.layer`, `NodeHttpClient`, or `BunHttpClient` only in runtime composition, tests, or adapter factories.
- Build requests with `HttpClientRequest` combinators. They return immutable request values and compose through `.pipe(...)`.
- Decode and encode HTTP bodies with schemas. Prefer `HttpClientResponse.schemaBodyJson`, `HttpClientRequest.schemaBodyJson`, `HttpServerResponse.schemaJson`, or `Schema.fromJsonString(...)` over unchecked JSON helpers.
- Use `Stream.Stream` for streaming request or response bodies. Do not write manual web reader loops when an Effect stream can model the data flow.
- Use `Effect.fnUntraced` for effectful wrappers unless a span is intentional. Use `Effect.fn` or `Effect.withSpan` when the operation should appear as its own trace span.

## Behavior encapsulation

### First-party HTTP APIs: contract first, behavior behind services

`repos/effect/packages/effect/HTTPAPI.md`, `repos/executor/packages/plugins/example/src/shared.ts`, and `repos/executor/packages/plugins/example/src/server.ts` all use the same shape:

1. define schemas and the `HttpApiGroup` in a shared module,
2. define domain behavior in a service or extension,
3. make handlers thin adapters from HTTP input to service calls,
4. let typed errors flow through the handler instead of translating in every route.

Adapted pattern:

```ts
import { Context, Effect, Layer, Schema } from "effect";
import { HttpApi, HttpApiBuilder, HttpApiEndpoint, HttpApiGroup } from "effect/unstable/httpapi";

export const StartAssessmentPayload = Schema.Struct({
  participantId: Schema.String,
  promptId: Schema.String,
}).annotate({ identifier: "StartAssessmentPayload" });

export const AssessmentSession = Schema.Struct({
  id: Schema.String,
  status: Schema.Literals(["Ready", "InProgress"]),
}).annotate({ identifier: "AssessmentSession" });

export class AssessmentUnavailable extends Schema.TaggedErrorClass<AssessmentUnavailable>()(
  "AssessmentUnavailable",
  {
    reason: Schema.Literals(["ProviderUnavailable", "ConfigurationMissing"]),
  },
  { httpApiStatus: 503 },
) {}

export const AssessmentGroup = HttpApiGroup.make("assessment").add(
  HttpApiEndpoint.post("start", "/assessments/start", {
    payload: StartAssessmentPayload,
    success: AssessmentSession,
    error: AssessmentUnavailable,
  }),
);

export interface VoiceAssessmentShape {
  readonly start: (
    payload: typeof StartAssessmentPayload.Type,
  ) => Effect.Effect<typeof AssessmentSession.Type, AssessmentUnavailable>;
}

export class VoiceAssessment extends Context.Service<VoiceAssessment, VoiceAssessmentShape>()(
  "fiberisle/VoiceAssessment",
) {}

const Api = HttpApi.make("voice-assessment").add(AssessmentGroup);

export const AssessmentHandlers = HttpApiBuilder.group(Api, "assessment", (handlers) =>
  handlers.handle("start", ({ payload }) =>
    Effect.gen(function* () {
      const assessment = yield* VoiceAssessment;
      return yield* assessment.start(payload);
    }),
  ),
);

export const AssessmentApiLive: Layer.Layer<never, never, VoiceAssessment> = HttpApiBuilder.layer(
  Api,
).pipe(Layer.provide(AssessmentHandlers));
```

Guidelines:

- The API module owns wire contracts: params, query, headers, payload, success, and error schemas.
- The service owns behavior and invariants. The handler should not duplicate service validation or orchestration.
- Handler code may read `ctx.params`, `ctx.query`, `ctx.headers`, `ctx.payload`, or `ctx.request`, but it should quickly delegate to a service.
- Use `Schema.TaggedErrorClass` or `Schema.ErrorClass` with `httpApiStatus` / `HttpApiSchema.status(...)` for errors returned over HTTP.
- Prefer endpoint or group `.error` declarations over ad hoc `HttpServerResponse` error bodies.

### Outbound HTTP: one service owns one remote protocol

Effect's HTTP client docs model a service that captures `HttpClient.HttpClient`, applies common request transforms once, and exposes domain methods. `repos/executor/packages/core/sdk/src/oauth-discovery.ts`, `repos/executor/packages/plugins/openapi/src/sdk/parse.ts`, and `repos/executor/packages/plugins/mcp/src/sdk/probe-shape.ts` follow this pattern with injected client layers, explicit timeouts, and domain errors.

Adapted pattern:

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

`repos/executor/packages/core/sdk/src/oauth-discovery.ts` and `repos/executor/packages/plugins/mcp/src/sdk/probe-shape.ts` accept an optional `httpClientLayer` and default to `FetchHttpClient.layer` at the API edge. That keeps tests deterministic without patching `globalThis.fetch`.

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

### Test with HTTP layers, not global mocks

Effect's own tests use `NodeHttpServer.layerTest`, `HttpRouter.serve`, `HttpServer.serve`, and `HttpApiTest.groups`. Executor adds a useful wrapper in `repos/executor/packages/core/sdk/src/testing.ts`: build a scoped test server, expose a `baseUrl`, and return a `Layer.succeed(HttpClient.HttpClient, client)` for callers.

Adapted test pattern:

```ts
import * as NodeHttpServer from "@effect/platform-node/NodeHttpServer";
import { Context, Effect, Layer, Predicate, Schema, Scope } from "effect";
import { HttpClient, HttpRouter, HttpServer, HttpServerResponse } from "effect/unstable/http";

export class TestServerAddressError extends Schema.TaggedErrorClass<TestServerAddressError>()(
  "TestServerAddressError",
  { address: Schema.Defect },
) {}

export interface TestHttpServer {
  readonly baseUrl: string;
  readonly httpClientLayer: Layer.Layer<HttpClient.HttpClient>;
  readonly url: (path?: string) => string;
}

export const serveRoutes = (
  routes: readonly HttpRouter.Route<never, never>[],
): Effect.Effect<TestHttpServer, TestServerAddressError, Scope.Scope> =>
  Effect.gen(function* () {
    const context = yield* Layer.build(
      Layer.fresh(
        HttpRouter.serve(HttpRouter.addAll(routes), {
          disableListenLog: true,
          disableLogger: true,
        }).pipe(Layer.provideMerge(NodeHttpServer.layerTest)),
      ),
    );

    const server = Context.get(context, HttpServer.HttpServer);
    const address = server.address;
    if (!Predicate.isTagged(address, "TcpAddress")) {
      return yield* new TestServerAddressError(address);
    }

    const client = Context.get(context, HttpClient.HttpClient);
    const baseUrl = `http://127.0.0.1:${address.port}`;

    return {
      baseUrl,
      httpClientLayer: Layer.succeed(HttpClient.HttpClient, client),
      url: (path = "") => new URL(path, baseUrl).toString(),
    };
  });

export const okRoute = HttpRouter.route(
  "GET",
  "/health",
  Effect.succeed(HttpServerResponse.text("ok")),
);
```

Guidelines:

- Prefer real Effect HTTP servers for integration tests. They exercise routing, request encoding, response decoding, status handling, cookies, and middleware.
- Use `Layer.fresh` for scoped test servers so each test gets a clean port and lifecycle.
- Use `HttpApiTest.groups` for handler-level tests that should bypass the socket but still use the `HttpApi` contract.
- Disable listen and request logging in tests with `{ disableListenLog: true, disableLogger: true }`.
- Use `TestClock` for retry, timeout, and rate-limit tests. Effect's HTTP client tests advance logical time instead of sleeping.

### Keep client transforms close to typed clients

Effect docs and `repos/executor/packages/core/sdk/src/client.ts` use generated clients with request transforms for base URLs and auth.

```ts
import { Context, Effect, flow, Layer } from "effect";
import { FetchHttpClient, HttpClient, HttpClientRequest } from "effect/unstable/http";
import { HttpApiClient } from "effect/unstable/httpapi";

import { AssessmentApi } from "./AssessmentApi";

export class AssessmentApiClient extends Context.Service<
  AssessmentApiClient,
  HttpApiClient.ForApi<typeof AssessmentApi>
>()("fiberisle/AssessmentApiClient") {
  static readonly layer = (baseUrl: string): Layer.Layer<AssessmentApiClient> =>
    Layer.effect(
      AssessmentApiClient,
      HttpApiClient.make(AssessmentApi, {
        transformClient: (client) =>
          client.pipe(
            HttpClient.mapRequest(flow(HttpClientRequest.prependUrl(baseUrl))),
            HttpClient.retryTransient({ retryOn: "errors-only", times: 2 }),
          ),
      }),
    ).pipe(Layer.provide(FetchHttpClient.layer));
}
```

Guidelines:

- Use `baseUrl` or `transformClient` instead of hand-building URLs at every call site.
- Use `HttpApiMiddleware.layerClient` for auth or other middleware declared by the API contract.
- Keep generated clients inside services when many callers use the same remote API.

## Error handling patterns

### Outbound client errors

`HttpClientError` wraps reason values such as `TransportError`, `InvalidUrlError`, `EncodeError`, `StatusCodeError`, `DecodeError`, and `EmptyBodyError`. `HttpClient.filterStatusOk` converts non-2xx responses into `StatusCodeError`. `HttpClient.retryTransient` retries transport errors, timeouts, and transient statuses: `408`, `429`, `500`, `502`, `503`, and `504`.

Patterns:

- Use `filterStatusOk` only when the response body is irrelevant on failure.
- If a status has product meaning, inspect `response.status` and decode the body deliberately.
- Map body-read failures separately from request failures when callers can act differently.
- Keep retry policy close to the protocol service. Be cautious retrying non-idempotent operations; use `retryOn: "errors-only"` for writes unless the protocol guarantees safe retries.
- Use `HttpClientResponse.matchStatus` when a small number of statuses map to distinct domain outcomes.

```ts
import { Effect, Schema } from "effect";
import { HttpClient, HttpClientRequest, HttpClientResponse } from "effect/unstable/http";

export const ClientRegistrationPayload = Schema.Record(Schema.String, Schema.String).annotate({
  identifier: "ClientRegistrationPayload",
});

export const ProviderErrorBody = Schema.Struct({
  code: Schema.String,
  message: Schema.String,
}).annotate({ identifier: "ProviderErrorBody" });

export class RegisterClientError extends Schema.TaggedErrorClass<RegisterClientError>()(
  "RegisterClientError",
  {
    reason: Schema.Literals(["Rejected", "Unavailable", "MalformedResponse"]),
    detail: Schema.optional(Schema.String),
    cause: Schema.optional(Schema.Defect),
  },
) {}

export const registerClient = (
  registrationEndpoint: string,
  payload: typeof ClientRegistrationPayload.Type,
): Effect.Effect<void, RegisterClientError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient;
    const request = yield* HttpClientRequest.post(registrationEndpoint).pipe(
      HttpClientRequest.schemaBodyJson(ClientRegistrationPayload)(payload),
      Effect.mapError(
        (cause) =>
          new RegisterClientError({
            reason: "Unavailable",
            cause,
          }),
      ),
    );
    const response = yield* client.execute(request).pipe(
      Effect.mapError(
        (cause) =>
          new RegisterClientError({
            reason: "Unavailable",
            cause,
          }),
      ),
    );

    if (response.status >= 200 && response.status < 300) {
      return;
    }

    const errorBody = yield* HttpClientResponse.schemaBodyJson(ProviderErrorBody)(response).pipe(
      Effect.mapError(
        (cause) =>
          new RegisterClientError({
            reason: "MalformedResponse",
            cause,
          }),
      ),
    );

    return yield* new RegisterClientError({
      reason: "Rejected",
      detail: `${errorBody.code}: ${errorBody.message}`,
    });
  });
```

### Inbound API errors

Effect's `HTTPAPI.md` shows two valid styles:

- custom tagged errors with a status annotation,
- predefined `HttpApiError` schemas such as `NotFound`, `Unauthorized`, `Forbidden`, and their no-content variants.

Prefer custom domain errors when the caller needs structured information. Use predefined errors for ordinary protocol failures.

```ts
import { Effect, Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiError,
  HttpApiGroup,
  HttpApiSchema,
} from "effect/unstable/httpapi";

export class AssessmentNotFound extends Schema.TaggedErrorClass<AssessmentNotFound>()(
  "AssessmentNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class RateLimitExceeded extends Schema.TaggedErrorClass<RateLimitExceeded>()(
  "RateLimitExceeded",
  { message: Schema.String },
) {}

export const RateLimitExceededHttp = RateLimitExceeded.pipe(
  HttpApiSchema.status("TooManyRequests"),
);

export const AssessmentReadGroup = HttpApiGroup.make("assessment-read").add(
  HttpApiEndpoint.get("get", "/assessments/:id", {
    params: { id: Schema.String },
    success: Schema.String,
    error: [AssessmentNotFound, RateLimitExceededHttp, HttpApiError.UnauthorizedNoContent],
  }),
);

export const missingAssessment = (id: string): Effect.Effect<never, AssessmentNotFound> =>
  Effect.fail(new AssessmentNotFound({ id }));
```

Guidelines:

- Put stable status and encoding metadata on schemas, not in each handler.
- Add errors at the group level when every endpoint inherits the same failure set.
- Return `Effect.void` for no-content success handlers.
- Let non-actionable defects bubble to the composition boundary, where observability/capture middleware can translate them into an opaque public error.
- Do not inspect error shapes with `"_tag" in error`; keep the error channel typed and use `Effect.catchTag` / `Effect.catchTags`.

## Request and response body patterns

- Use `HttpClientRequest.schemaBodyJson(schema)(body)` for JSON requests when the body has a known schema.
- Use `HttpClientResponse.schemaBodyJson(schema)(response)` for JSON responses.
- Use `HttpServerResponse.schemaJson(schema)(body, options)` when manually returning a JSON server response.
- Use `HttpApiSchema.asText`, `asFormUrlEncoded`, `asUint8Array`, `asMultipart`, or `asMultipartStream` on `HttpApi` schemas to describe non-default wire encodings.
- Use `HttpClientRequest.bodyStream` and `HttpServerResponse.stream` with `Stream.Stream` for streaming bodies.
- Use `HttpServerRequest.HttpServerRequest` only when a route truly needs raw request access. Prefer endpoint schemas for params, query, headers, and payload.

## Web interop

Effect provides conversion helpers:

- `HttpClientRequest.fromWeb` / `HttpClientRequest.toWeb`
- `HttpClientResponse.fromWeb`
- `HttpServerRequest.toWeb`
- `HttpServerResponse.fromWeb`
- `HttpServerResponse.toClientResponse`

`repos/alchemy-effect/stacks/otel/Ingester.ts` uses these helpers to bridge Cloudflare Worker requests and upstream web `Response` values. In this project, keep that kind of web interop isolated in an adapter. Domain services should use Effect HTTP services, not direct `fetch`.

If an external runtime requires a `fetch` function, wrap it at the transport layer, as in `repos/executor/packages/core/sdk/src/hosted-http-client.ts`: provide `FetchHttpClient.Fetch` with a guarded implementation, then expose a normal `Layer.Layer<HttpClient.HttpClient>`.

## Observability and tracing

- Use `Effect.fn` or `Effect.withSpan` around meaningful HTTP operations. Add stable attributes such as route templates, methods, and remote service names.
- Do not add manual logs for error paths. Spans already capture failures.
- When an HTTP client is used by telemetry exporters, avoid recursively tracing the exporter. `repos/t3code/apps/web/src/observability/clientTracing.ts` composes `FetchHttpClient.layer` with `Layer.succeed(HttpClient.TracerDisabledWhen, () => true)` for that purpose.
- Use `Effect.annotateCurrentSpan` for request-specific fields inside an existing span.

## What to avoid

- Do not use `fetch`, web `Request`, or web `Response` directly in application behavior. If a runtime forces web APIs, isolate the conversion in one adapter and return Effect HTTP values.
- Do not patch `globalThis.fetch` in tests. Provide a `HttpClient` layer or start an Effect test server.
- Do not pass `HttpClient` instances as function arguments through domain code. Yield `HttpClient.HttpClient` from context inside the service that owns the HTTP behavior.
- Do not scatter base URL, auth, retry, timeout, or cookie setup across call sites. Apply them once through client transforms or layers.
- Do not use unchecked JSON helpers in implementation code when a schema is available. Avoid `bodyJsonUnsafe`, `jsonUnsafe`, `JSON.parse`, and `JSON.stringify` outside tests, fixtures, or unavoidable low-level adapters.
- Do not parse request params, query strings, headers, or JSON bodies by hand for `HttpApi` routes. Put schemas on the endpoint.
- Do not return ad hoc `HttpServerResponse` errors from typed `HttpApi` handlers. Declare error schemas and fail with those errors.
- Do not expose broad `unknown` or generic `InternalError`-style typed errors from services. Use specific actionable tagged errors; reserve opaque HTTP 500 errors for public edge translation.
- Do not retry all failures blindly. Keep retries bounded, transient-only, and safe for the operation.
- Do not use `Effect.orDie` for expected HTTP failures. Map typed errors explicitly and die only for genuinely unrecoverable defects.
