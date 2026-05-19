# Effect `HTTP` patterns for agents — part 4

Covers:

- Outbound client errors
- Inbound API errors
- Request and response body patterns
- Web interop
- Observability and tracing

---

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

Use these helpers to bridge Cloudflare Worker requests and upstream web `Response` values. Keep that kind of web interop isolated in an adapter. Domain services should use Effect HTTP services, not direct `fetch`.

If an external runtime requires a `fetch` function, wrap it at the transport layer: provide `FetchHttpClient.Fetch` with a guarded implementation, then expose a normal `Layer.Layer<HttpClient.HttpClient>`.

## Observability and tracing

- Use `Effect.fn` or `Effect.withSpan` around meaningful HTTP operations. Add stable attributes such as route templates, methods, and remote service names.
- Do not add manual logs for error paths. Spans already capture failures.
- When an HTTP client is used by telemetry exporters, avoid recursively tracing the exporter by composing `FetchHttpClient.layer` with `Layer.succeed(HttpClient.TracerDisabledWhen, () => true)`.
- Use `Effect.annotateCurrentSpan` for request-specific fields inside an existing span.
