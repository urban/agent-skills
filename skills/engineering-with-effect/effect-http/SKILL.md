---
name: effect-http
description: Design Effect HTTP boundaries around shared contracts, status semantics, body codecs, transport ownership, retries, streaming, and in-process verification. Use when implementing inbound HttpApi handlers or outbound remote-protocol services.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Inspect the installed Effect HTTP, HttpApi, runtime, and official protocol integrations before adding a custom transport, router, codec, retry loop, or streaming bridge.
- For first-party APIs, make one shareable schema contract the source for handlers, clients, and documentation.
- For outbound HTTP, let one service own one remote protocol, including base URL, authentication, status interpretation, retries, timeouts, and body codecs.
- Treat transport failure, protocol status, and body decoding as distinct failure classes when callers respond differently.
- Keep runtime transports and web interop at composition or adapter edges.

## Constraints

- Effect HTTP and HttpApi are currently exposed through unstable v4 module surfaces; verify imports and API details against the installed release.
- Retry only operations and failure classes that are safe to repeat; idempotency is a protocol decision.
- Do not discard a non-success response body when it carries domain meaning.
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
- Use a blanket success-status filter only when all non-success bodies are irrelevant. Otherwise branch on status and decode the corresponding schema.
- Map transport, timeout, status, and decode failures into the smallest caller-actionable taxonomy, preserving causes for diagnosis.
- Use schema body helpers for known payloads and Stream for incremental bodies; bridge Web APIs in one adapter when the runtime requires them.
- Test contracts without the public internet: handler-backed clients for contract logic, in-process servers for routing/middleware/transport, and logical time for retry policy.

## Gotchas

- A custom transport or protocol layer can duplicate HttpClient, HttpApi, Schema, Stream, or an official integration while losing their status, scope, and interruption semantics; name the unsupported requirement first.
- Hand-parsed handler input drifts from generated clients and OpenAPI; put the rule in the endpoint schema or domain service.
- Centralizing a client but leaving retries and status filters at call sites still creates divergent protocol behavior.
- Retrying a write after a connection failure can duplicate side effects even when the response was never received; require idempotency evidence.
- Filtering status before reading a meaningful error body destroys details needed for product decisions.
- Global transport mocks can make tests pass while application code bypasses the intended Effect HTTP layer.
- A stream response that outlives its request scope can lose its body or leak a connection; make body consumption and ownership explicit.

## References

- [`references/inbound-contracts.md`](./references/inbound-contracts.md): Read when: defining a shared HttpApi, error statuses, or thin handlers.
- [`references/outbound-protocols.md`](./references/outbound-protocols.md): Read when: designing a remote-protocol service, status handling, retries, timeouts, or transport layers.
- [`references/http-testing.md`](./references/http-testing.md): Read when: choosing handler-backed versus in-process-server verification or testing time-based client policy.
