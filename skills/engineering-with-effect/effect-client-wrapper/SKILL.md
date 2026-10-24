---
name: effect-client-wrapper
description: Wrap Promise-based third-party SDK clients behind Effect with narrow capabilities, redacted configuration, actionable error mapping, scoped cleanup, retry/idempotency policy, telemetry boundaries, and deterministic substitutes. Use for Stripe, AWS, Resend, and similar SDK adapters.
---

## Rules

- Check the installed Effect packages and official integrations before wrapping an upstream SDK; use a custom wrapper only when no suitable integration owns the required provider, protocol, lifetime, and failure semantics.
- Prefer domain methods over exposing the SDK. Keep a generic client `use` escape hatch only when wrapping the surface is impractical and leakage is deliberate.
- Construct and configure an owned SDK inside a layer; keep credentials redacted until the exact constructor/request boundary.
- Translate expected external failures where the SDK is invoked; distinguish startup failures from request failures when recovery differs.
- Preserve cancellation at the adapter boundary when the SDK supports it; distinguish stopping the fiber from stopping remote work.
- Add retry, telemetry, and cleanup from SDK semantics, not automatically.

## Constraints

- Never include credentials or sensitive provider payloads in errors, spans, logs, or test snapshots.
- Retry only classified transient failures and only when repeating the operation is safe.
- Release resources in their owning scope. A wrapper borrowing an externally managed client must not close it.
- Do not treat interruption or timeout as proof that a remote mutation did not commit.

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
- client ownership, cancellation support, close/flush behavior, and credential sensitivity

Failure modes this knowledge helps avoid:

- duplicate remote mutations after ambiguous failures
- client leaks or premature shutdown of shared clients
- provider details escaping through domain APIs or diagnostics

## Patterns

- Split the low-level SDK adapter from higher-level domain services when many domains share the client but need different error and response models.
- A generic escape hatch can accept an operation descriptor: stable name, invocation, and safe telemetry metadata. Keep the raw client inside the callback; make signal forwarding part of this contract.
- Invoke the SDK lazily inside `Effect.tryPromise`; translate synchronous invocation throws and Promise rejections into actionable errors. Retain only vetted provider details, not raw causes by default.
- Add a span only for a meaningful SDK operation; use stable operation names and low-cardinality attributes.
- Classify transient failures from provider codes/status/retry hints. Bound attempts and backoff, and require idempotency for writes.
- Provide a fake at the narrow service boundary or a scripted low-level adapter; assert domain calls and mapped outcomes rather than constructing the real SDK.

## Gotchas

- Wrapping an SDK before checking for an official Effect integration creates a second client, configuration, error, and lifecycle model; inspect the installed ecosystem first and name the remaining gap.
- A generic `use(client => ...)` everywhere leaks SDK request and response types through the application and defeats the boundary.
- Retrying every rejected Promise can repeat charges or sends; classify failures and reuse the same logical idempotency key, accounting for retries already inside the SDK.
- A timeout can leave the provider working after the caller has stopped waiting; forward the signal, and reconcile uncertain mutation outcomes instead of assuming rollback.
- Logging an opaque constructor error may stringify configuration or credentials; sanitize causes too, since `Redacted` configuration does not redact SDK errors.
- Closing a borrowed client can break unrelated callers; keep release with its owner and choose an explicit close/flush failure policy rather than silently losing buffered work.
- Automatic spans around every wrapper can duplicate higher-level domain spans and inflate telemetry.
- A fake that returns domain values directly can bypass adapter decoding and error mapping; test the adapter separately when those behaviors matter.

## References

- [`references/adapter-boundary.md`](./references/adapter-boundary.md): Read when: choosing domain methods versus a generic escape hatch, forwarding cancellation, or translating external failures.
- [`references/retry-lifecycle-and-tests.md`](./references/retry-lifecycle-and-tests.md): Read when: deciding retry/idempotency policy, layer ownership, cleanup failure policy, telemetry, or adapter test cases.
