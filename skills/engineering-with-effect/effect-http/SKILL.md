---
name: effect-http
description: Design Effect HTTP boundaries around shared contracts, status semantics, body codecs, transport ownership, retries, streaming, and in-process verification. Use when implementing inbound HttpApi handlers or outbound remote-protocol services.
---

## Rules

- Prefer Effect's HTTP, HttpApi, and streaming boundaries over custom transport or codec layers unless the protocol has an unsupported requirement.
- For first-party APIs, make one shareable schema contract the source for handlers, clients, and documentation.
- For outbound HTTP, let one service own one remote protocol, including base URL, authentication, status interpretation, retries, timeouts, and body codecs.
- Treat transport failure, protocol status, and body decoding as distinct failure classes when callers respond differently.
- Keep runtime transports and web interop at composition or adapter edges.

## Constraints

- HTTP and HttpApi use `effect/http` and `effect/http-api`; these modules are unstable.
- Retry only operations and failure classes that are safe to repeat; idempotency is a protocol decision.
- Do not bypass declared HttpApi error decoding with a blanket success-status filter.
- Streaming bodies must preserve backpressure, interruption, and scope ownership across the HTTP boundary.

## Knowledge Boundaries

Applies to:

- HttpApi contract placement and handler boundaries
- outbound client services and request transforms
- status/error taxonomy, retries, timeouts, cookies, and streaming bodies
- handler-level and in-process transport tests

Does not cover:

- mechanical bans on direct globals or unchecked JSON helpers
- stream protocol internals beyond HTTP ownership

Decision inputs:

- who owns the protocol and which peers share its schema
- meaningful success and error statuses and body formats
- method idempotency and server deduplication guarantees
- runtime transport, scope, and verification fidelity required

## Patterns

- Keep shared API modules free of server-only and runtime-only dependencies. Handlers should adapt decoded HTTP input to domain services, not reimplement domain rules.
- Apply base URL, authentication, common headers, cookies, and transport policy once to the client used by the protocol service.
- With a raw HttpClient, choose the status policy explicitly: receiving a 4xx/5xx response is not itself a failed effect. Decode meaningful error bodies before mapping to domain failures.
- Map transport, timeout, status, and decode failures into the smallest caller-actionable taxonomy, preserving causes for diagnosis.
- Use schema body helpers for known payloads and Stream for incremental bodies; bridge Web APIs in one adapter when the runtime requires them.
- Choose tests by fidelity: `HttpApiTest.groups` exercises the generated contract pipeline without sockets; a local server adds runtime transport behavior.

## Gotchas

- A custom transport or protocol layer can duplicate HttpClient, HttpApi, Schema, Stream, or an official integration while losing their status, scope, and interruption semantics; name the unsupported requirement first.
- Hand-parsed handler input drifts from generated clients and OpenAPI; put the rule in the endpoint schema or domain service.
- Centralizing a client but leaving retries and status filters at call sites still creates divergent protocol behavior; keep policy with the protocol owner, with operation-specific safety decisions.
- Retrying a write after a connection failure can duplicate side effects even when the response was never received; require idempotency evidence.
- A success-status filter on the client supplied to HttpApi can turn declared domain errors into generic `HttpClientError`s before the generated decoder runs; leave status/schema dispatch to HttpApi.
- `retryTransient` classifies failures, not idempotency, and is unbounded without a limit; constrain attempts and elapsed time instead of applying it indiscriminately to a shared client.
- Handler-backed tests do exercise routing and middleware, but not socket aborts or unread-body draining; use a local server when those behaviors matter.
- Closing a request scope before consuming its response stream aborts the body; do not return a stream from an already-completed `Effect.scoped` block.

## References

- [`references/inbound-contracts.md`](./references/inbound-contracts.md): Read when: defining a shared HttpApi, error statuses, or thin handlers.
- [`references/outbound-protocols.md`](./references/outbound-protocols.md): Read when: designing a remote-protocol service, status handling, retries, timeouts, or transport layers.
- [`references/http-testing.md`](./references/http-testing.md): Read when: choosing in-memory versus local-server tests, asserting streaming ownership, or testing time-based client policy.
