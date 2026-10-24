# Outbound protocols

## One owner

One service owns a remote protocol's base URL, authentication, headers, status interpretation, rate limits, retries, timeouts, and schemas. Callers use domain methods. Share connection infrastructure at runtime composition, but isolate credentials and mutable session state: a cookie `Ref` shared across tenants also shares their session cookies.

Reusable protocol code depends on `HttpClient.HttpClient`; runtime composition chooses fetch, Node, Bun, or another transport. Web Request/Response conversion belongs in one adapter, not in domain methods.

## Status decisions

A raw HttpClient returns responses for 4xx/5xx statuses; a failed client trace span does not mean the request effect failed. Decide what the protocol means before decoding:

- Filter non-success statuses when callers need only generic status failure. `filterStatusOk` accepts 2xx; it does not understand domain semantics.
- Branch on status when not-found, conflict, rate-limit, validation, or authentication bodies change behavior. Decode the corresponding schema, then map to a caller-actionable domain result or failure.
- Separate transport failure, rejected status, body-read failure, and schema mismatch only where callers act differently. `HttpClientError` wraps a `reason`; a status failure retains the response. Schema decoding can also fail with `SchemaError`, so catching only transport errors is not a complete decode policy.
- Keep generated HttpApi clients on their declared status/body dispatch rather than replacing it with generic filtering.

## Retry and deadline safety

Transient classification is not replay permission. For writes, require an idempotency key, server deduplication, or another protocol guarantee. Streaming uploads also need a replayable source; a retry cannot recreate an already-consumed external input.

`HttpClient.retry` retries failed effects, not successful responses with bad statuses. `retryTransient` can consider both returned transient responses and transient failures; its default covers both, with no finite attempt limit. It does not check the HTTP method. Its `while` option adds error cases to the built-in classification rather than narrowing it, so it is not an idempotency guard.

Use a finite attempt policy and an overall deadline. `retryTransient` honors valid `Retry-After` seconds/dates as a **minimum** delay alongside the schedule; an attempt limit alone cannot cap that wait. In combined error/response mode, repetition and error retries are nested, so `times` is not necessarily a single global attempt budget under mixed outcomes. Bound the whole domain operation when a hard budget matters.

After response retries are exhausted, the last response can still be returned successfully. Apply the protocol's final status interpretation; do not equate retry exhaustion with an automatic failed effect.

Place timeouts according to their meaning: per-attempt timeouts belong inside retry; an overall caller deadline surrounds the operation. Receiving headers is not finishing the body. Include decoding/consumption in the deadline if that is the promised bound, and use a deliberate idle/total policy for long-lived streams rather than retrying an entire partially consumed response.

## Body lifetime

Ordinary HttpClient calls do not require a caller-provided Scope. In-flight interruption aborts the request, and response stream consumption owns its interruption/cleanup. Use `HttpClient.withScope` when the request must be aborted deterministically at scope close, including abandoned bodies; do not rely on garbage collection for prompt release.

When using `withScope`, keep that scope open through body consumption. For decoded results, consume/decode inside it. For streams, acquire the response within the consuming stream's lifetime rather than opening a short scope and returning `response.stream` from it. Keep the runtime transport layer alive for the same duration.

Preserve backpressure and cancellation instead of collecting a streaming body merely to bridge APIs. Choose framing, resource limits, and the meaning of partial delivery explicitly; successful headers do not guarantee successful completion.
