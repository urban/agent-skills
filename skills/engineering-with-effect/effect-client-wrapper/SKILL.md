---
name: effect-client-wrapper
description: Wrap Promise-based third-party SDK clients behind Effect with narrow capabilities, redacted configuration, actionable error mapping, scoped cleanup, retry/idempotency policy, telemetry boundaries, and deterministic substitutes. Use for Stripe, AWS, Resend, and similar SDK adapters.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Check the installed Effect packages and official integrations before wrapping an upstream SDK; use a custom wrapper only when no suitable integration owns the required provider, protocol, lifetime, and failure semantics.
- Prefer domain methods over exposing the SDK. Keep a generic client `use` escape hatch only when wrapping the surface is impractical and leakage is deliberate.
- Construct and configure the SDK inside a layer; keep credentials redacted until the exact constructor/request boundary.
- Map constructor failures and operation failures separately when startup and request recovery differ.
- Add retry, telemetry, and cleanup from SDK semantics, not automatically.

## Constraints

- Never include credentials or sensitive provider payloads in errors, spans, logs, or test snapshots.
- Retry only classified transient failures and only when repeating the operation is safe.
- If the client owns resources, its layer must own release and define release-failure policy.

## Knowledge Boundaries

Applies to:

- SDK constructor/configuration layers
- narrow domain methods and generic escape hatches
- Promise rejection mapping, retryability, idempotency, tracing, and cleanup
- fake SDK boundaries and adapter tests

Does not cover:

- native Effect HTTP protocols that should use HttpClient directly
- generic service or layer syntax

Decision inputs:

- SDK surface size and domain abstraction value
- constructor versus per-operation failure semantics
- operation idempotency and provider retry hints
- client lifetime, close/flush behavior, and credential sensitivity

## Patterns

- Split the low-level SDK adapter from higher-level domain services when many domains share the client but need different error and response models.
- Accept one operation descriptor object in a generic escape hatch: operation name, invocation, and safe telemetry metadata. Keep the raw client inside the callback only.
- Convert Promise rejections at the adapter boundary, preserving opaque cause plus structured provider details that are safe and useful.
- Add a span only for a meaningful SDK operation; use stable operation names and low-cardinality attributes.
- Classify transient failures from provider codes/status/retry hints. Bound attempts and backoff, and require idempotency for writes.
- Provide a fake at the narrow service boundary or a scripted low-level adapter; assert domain calls and mapped outcomes rather than constructing the real SDK.

## Gotchas

- Wrapping an SDK before checking for an official Effect integration creates a second client, configuration, error, and lifecycle model; inspect the installed ecosystem first and name the remaining gap.
- A generic `use(client => ...)` everywhere leaks SDK request and response types through the application and defeats the boundary.
- Retrying every rejected Promise can repeat charges, sends, uploads, or mutations.
- Logging an opaque constructor error may stringify configuration or credentials; sanitize deliberately.
- Swallowing close/flush failure can lose buffered work, while failing every shutdown can mask the primary application exit; choose policy by resource semantics.
- Automatic spans around every wrapper can duplicate higher-level domain spans and inflate telemetry.
- A fake that returns domain values directly can bypass adapter decoding and error mapping; test the adapter separately when those behaviors matter.

## References

- [`references/adapter-boundary.md`](./references/adapter-boundary.md): Read when: choosing domain methods versus a generic escape hatch, constructing the client, or mapping Promise failures.
- [`references/retry-lifecycle-and-tests.md`](./references/retry-lifecycle-and-tests.md): Read when: adding retries, idempotency, redaction, telemetry, cleanup, or deterministic substitutes.
