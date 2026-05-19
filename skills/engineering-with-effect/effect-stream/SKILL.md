---
name: effect-stream
description: Build Effect Stream pipelines for lazy back-pressured data, service-owned sources, callback/Web/Node adapters, schema decoding, protocol boundaries, cleanup, and deterministic tests. Use when implementing or reviewing Effect streams, streaming service APIs, event subscriptions, callback adapters, process or HTTP body streams, NDJSON/SSE protocols, stream error handling, or stream tests.
---

## Native Effect Standards

- Expose streams as service capabilities and keep queues, subscriptions, handles, readers, and sockets private unless callers own lifecycle.
- Use `Stream.unwrap` for per-subscriber setup and `Stream.callback` for push APIs with registered cleanup and deliberate buffering.
- Split source adaptation, boundary decoding, domain transforms, and terminal sinks.
- Use schema codecs, NDJSON/SSE channels, `decodeText`, `splitLines`, and platform/Web/Node adapters instead of manual parsing loops.
- Map external failures to precise tagged errors and recover only from expected typed stream errors.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not write ad hoc async generators, manual `ReadableStream` reader loops, event-emitter arrays, or callback buffering when a `Stream` constructor models the source.
- Do not expose `Queue`, `PubSub`, sockets, file watchers, or process handles as service APIs when callers only need a stream.
- Do not pass service instances into stream functions. Yield services from context inside service construction or effect bodies.
- Do not use `Effect.orDie` or `Stream.die` for expected failures. Map expected failures to tagged errors and handle them explicitly.
- Do not invent generic errors like `InternalError`, `UnknownError`, or `XFailed` for stream failures.
- Do not erase stream error channels to `unknown`; keep `Stream.Stream<A, E, R>` precise.
- Do not `runCollect` infinite or long-lived streams unless capped first.
- Do not add arbitrary sleeps in tests for time-based streams; use `TestClock`.
- Do not manually parse JSON, NDJSON, or SSE in implementation code when a schema codec or Effect encoding channel can own the boundary.
- Do not ignore cleanup. Every subscription, callback, poller, reader, and spawned stream consumer needs scoped lifetime or an `ensuring` finalizer.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- stream source and lifetime owner
- payload, decoding, and protocol framing schemas
- backpressure, buffering, retry, and recovery policy
- terminal sink or returned stream boundary
- test limit and coordination strategy

Effect-native code should tend toward:

- domain-level streams behind services
- pipelines split into source, decoding, transforms, and sinks
- typed stream errors and explicit recovery
- bounded deterministic tests with cleanup assertions

Applies to:

- applying Effect Stream patterns to implementation, refactoring, review, or tests
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

- Bundled `references/patterns-*` files contain source-pattern detail for adapting push APIs, decoding protocols, recovering errors, or testing long-lived streams.
- Expose streams as service capabilities and keep queues, subscriptions, handles, readers, and sockets private unless callers own lifecycle.
- Use `Stream.unwrap` for per-subscriber setup and `Stream.callback` for push APIs with registered cleanup and deliberate buffering.
- Split source adaptation, boundary decoding, domain transforms, and terminal sinks.
- Use schema codecs, NDJSON/SSE channels, `decodeText`, `splitLines`, and platform/Web/Node adapters instead of manual parsing loops.
- Map external failures to precise tagged errors and recover only from expected typed stream errors.
- Test by consuming bounded public streams with `take`, `timeout`, `Deferred`, `Queue`, scoped fibers, and `TestClock`.

## Gotchas

- If a service exposes queues, pubsubs, or file watchers instead of a stream, callers inherit lifecycle and backpressure details. Return a domain stream unless they truly own the handle.
- If callback APIs are wrapped without finalizers, interruption leaks handlers and background work. Register cleanup inside `Stream.callback` or `ensuring`.
- If infinite streams are `runCollect`ed in tests, the test hangs or relies on timeouts. Bound consumption with `take`, `takeUntil`, or `timeout`.
- If JSON, NDJSON, or SSE are parsed manually, framing and partial chunks break at edge cases. Use schema codecs and Effect encoding channels.
- If stream failures are encoded as log lines or generic messages, remote consumers cannot recover. Preserve them in the error channel or explicit protocol frames.
- If time-based streams are tested with sleeps, races become flaky. Use `TestClock`, `Deferred`, and scoped fibers.

## References

- [`references/patterns-01-effect-stream-patterns-for-agents.md`](./references/patterns-01-effect-stream-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Stream patterns for agents, Mental model from repos/effect, Behavior encapsulation.
- [`references/patterns-02-split-source-boundary-decoding-domain-transforms.md`](./references/patterns-02-split-source-boundary-decoding-domain-transforms.md): Read when: you need source-pattern detail for Split source, boundary decoding, domain transforms, and sinks, Keep sinks at edges, Make tests consume bounded public streams.
- [`references/patterns-03-map-external-failures-at-the-boundary.md`](./references/patterns-03-map-external-failures-at-the-boundary.md): Read when: you need source-pattern detail for Map external failures at the boundary, Recover only from expected typed errors, Preserve remote stream failures explicitly.
