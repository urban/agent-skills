# Effect `HTTP` patterns for agents — part 5

Covers:

- What to avoid

---

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
