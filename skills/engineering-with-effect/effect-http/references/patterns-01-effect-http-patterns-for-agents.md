# Effect `HTTP` patterns for agents — part 1

Covers:

- Effect HTTP patterns for agents
- First principles
- Behavior encapsulation
- First-party HTTP APIs: contract first, behavior behind services

---

# Effect `HTTP` patterns for agents

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

`.dotai/repos/effect/packages/effect/HTTPAPI.md` demonstrates this shape:

1. define schemas and the `HttpApiGroup` in a shared module,
2. define domain behavior in a service or extension,
3. make handlers thin adapters from HTTP input to service calls,
4. let typed errors flow through the handler instead of translating in every route.

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
