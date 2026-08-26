# Outbound protocols

## One owner

One service should own the remote protocol's base URL, authentication, common headers, cookies, rate limits, status policy, retries, timeouts, and schemas. Callers use domain methods.

## Status decisions

- Filter all non-success statuses only when their bodies have no product meaning.
- Match statuses explicitly when not-found, conflict, rate-limit, validation, or authentication bodies change behavior.
- Distinguish request/transport failure from body-read/decode failure when callers act differently.

## Retry safety

Retry transient transport failures and retryable statuses only within a bound. For writes, require a protocol idempotency key, server deduplication, or another proof that repeating is safe. Honor retry hints when they are trustworthy and bounded.

## Transport

Reusable protocol code depends on the abstract HTTP client. Runtime composition chooses fetch, Node, Bun, or another transport. Web Request/Response conversion belongs in one runtime adapter.

## Streaming

The scope that owns the response must remain alive while the stream consumes the body. Decide cancellation, connection release, framing, and partial-output semantics before returning the stream.
