---
name: effect-http
description: Build Effect HTTP boundaries with HttpApi contracts, typed clients, schema bodies, service-owned outbound protocols, transport layers, status/error mapping, and in-process tests. Use when creating or refactoring Effect HTTP APIs, outbound HTTP services, generated clients, request/response schema handling, retries, streaming bodies, web interop, or HTTP tests.
---

## Native Effect Standards

- Prefer Effect HTTP primitives at boundaries: `HttpClient.HttpClient`, `HttpClientRequest.HttpClientRequest`, `HttpClientResponse.HttpClientResponse`, `HttpServerRequest.HttpServerRequest`, and `HttpServerResponse.HttpServerResponse`.
- Prefer `HttpApi` for first-party APIs. Define the schema contract once, then derive server handlers, OpenAPI, and typed clients from it.
- Keep API definitions shareable. Put `HttpApiGroup` schemas in a module that has no server-only, browser-only, or runtime-specific imports.
- Encapsulate outbound HTTP behind services. Callers should use domain methods such as `fetchTranscript`, `registerClient`, or `probeEndpoint`, not raw `client.execute` calls.
- Depend on `HttpClient.HttpClient` in reusable code and provide a transport layer at the edge. Use `FetchHttpClient.layer`, `NodeHttpClient`, or `BunHttpClient` only in runtime composition, tests, or adapter factories.
- Build requests with `HttpClientRequest` combinators. They return immutable request values and compose through `.pipe(...)`.
- Decode and encode HTTP bodies with schemas. Prefer `HttpClientResponse.schemaBodyJson`, `HttpClientRequest.schemaBodyJson`, `HttpServerResponse.schemaJson`, or `Schema.fromJsonString(...)` over unchecked JSON helpers.
- Use `Stream.Stream` for streaming request or response bodies. Do not write manual web reader loops when an Effect stream can model the data flow.
- Use `Effect.fnUntraced` for effectful wrappers unless a span is intentional. Use `Effect.fn` or `Effect.withSpan` when the operation should appear as its own trace span.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

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
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- inbound API or outbound remote protocol contract
- schemas for params, query, headers, payload, success, and errors
- transport/runtime layer and base URL/auth/retry requirements
- test plan for handler-level or in-process-server verification

Effect-native code should tend toward:

- shareable `HttpApi` definitions or service-owned outbound clients
- schema-encoded requests and decoded responses
- typed domain errors for status, transport, and decode failures
- tests using Effect HTTP layers instead of patched globals

Applies to:

- applying Effect HTTP patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for implementing API definitions, client services, status handling, or tests.
- For first-party APIs, define shared `HttpApiGroup` schemas first and keep handlers thin adapters to domain services.
- For outbound HTTP, create one service per remote protocol, inject `HttpClient.HttpClient`, and apply common transforms once.
- Encode and decode bodies through schema helpers, and use `Stream` for streaming bodies.
- Handle statuses deliberately: use `filterStatusOk` only when failure bodies are irrelevant; otherwise decode status-specific domain bodies.
- Map transport, status, timeout, and decode failures to precise tagged domain errors.
- Test with `HttpApiTest`, in-process servers, handler-backed clients, provided `HttpClient` layers, and `TestClock` for retry/timeout logic.

## Gotchas

- If handlers parse params or bodies by hand, the API schema stops being the contract. Put params, query, headers, payload, success, and errors on endpoints.
- If outbound code scatters base URLs, auth, retries, and status filters across call sites, behavior diverges. Centralize them in the protocol service or generated client layer.
- If `filterStatusOk` is used where error bodies carry product meaning, useful remote details are thrown away. Decode meaningful non-2xx responses explicitly.
- If tests patch `globalThis.fetch`, application code no longer proves it uses Effect HTTP correctly. Provide a `HttpClient` layer or run an in-process server.
- If unchecked JSON helpers creep into implementations, runtime validation and wire contracts split. Use request/response schema helpers or `Schema.fromJsonString`.
- If HTTP services leak low-level client errors to product callers, UI and API layers cannot make domain decisions. Map boundary failures to precise tagged errors.

## References

- [`references/patterns-01-effect-http-patterns-for-agents.md`](./references/patterns-01-effect-http-patterns-for-agents.md): Read when: you need source-pattern detail for Effect HTTP patterns for agents, First principles, Behavior encapsulation.
- [`references/patterns-02-outbound-http-one-service-owns-one-remote-protoc.md`](./references/patterns-02-outbound-http-one-service-owns-one-remote-protoc.md): Read when: you need source-pattern detail for Outbound HTTP: one service owns one remote protocol, Modular, testable, maintainable services, Keep transport injection explicit.
- [`references/patterns-03-test-with-http-layers-not-global-mocks.md`](./references/patterns-03-test-with-http-layers-not-global-mocks.md): Read when: you need source-pattern detail for Test with HTTP layers, not global mocks, Keep client transforms close to typed clients, Error handling patterns.
- [`references/patterns-04-outbound-client-errors.md`](./references/patterns-04-outbound-client-errors.md): Read when: you need source-pattern detail for Outbound client errors, Inbound API errors, Request and response body patterns.
- [`references/patterns-05-what-to-avoid.md`](./references/patterns-05-what-to-avoid.md): Read when: you need source-pattern detail for What to avoid.
