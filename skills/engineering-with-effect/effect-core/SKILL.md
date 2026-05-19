---
name: effect-core
description: Write Effect-native TypeScript with current core Effect v4 standards for effect wrappers, typed errors, services, layers, streams, causes, schemas, architecture, observability, and tests. Use when authoring or reviewing any Effect code, especially code that uses Effect.gen, Effect.fn, Context.Service, Layer, Stream, Schema, Cause, fibers, errors, or Effect-based tests.
---

## Native Effect Standards

- Prefer direct Effect expressions. Use `Effect.fnUntraced` for effectful wrappers unless spans are required, and use named `Effect.fn("name")` only when the function should create a span.
- Pass `Effect.fn` / `Effect.fnUntraced` post-processing combinators as additional constructor arguments. Do not call `.pipe(...)` on the function returned by `Effect.fn`.
- Do not wrap an effect in `Effect.fnUntraced(function* () { return yield* effect })`; return or compose the direct effect expression instead.
- Outside generators, convert yieldables with `.asEffect()` before piping.
- In `Effect.gen` methods that need `this`, use `Effect.gen({ self: this }, function* () { ... })`; do not pass `this` directly as the first argument.
- Define services with `Context.Service`; avoid v3 service APIs such as `Context.Tag`, `Context.GenericTag`, `Effect.Tag`, and `Effect.Service`.
- Yield services from context inside effect bodies. Do not pass service implementations as ordinary function arguments.
- All streaming implementations, including SSE and WebSockets, should use Effect `Stream`. SSE framing belongs to `effect/unstable/encoding/Sse`; WebSockets should use first-party Effect socket abstractions.
- Type final live layers such as `Rpc.toLayer`, service layers, and middleware layers as `Layer.Layer<ProvidedServices>`. Let intermediate and test-exported layers infer naturally.
- Compose layers before providing them. Use `Layer.fresh` or `Effect.provide(layer, { local: true })` only when a layer subtree must be rebuilt independently, such as for test isolation.
- Keep expected failures in the typed error channel. Handle them with v4 catch combinators, and use `Effect.die` only for genuinely unrecoverable failures.
- Use v4 catch combinators: `Effect.catch`, `Effect.catchCause`, `Effect.catchDefect`, `Effect.catchFilter`, `Effect.catchCauseFilter`, `Effect.catchTag`, and `Effect.catchTags`.
- Use v4 fiber names: `Effect.forkChild`, `Effect.forkDetach`, `Effect.forkScoped`, or `Effect.forkIn`.
- Model app errors with `Schema.TaggedErrorClass` and a typed `_tag` discriminator. Reuse an existing tagged error when one already fits.
- Services should expose typed errors only for actionable failures callers can handle. Non-actionable failures should die at the boundary or remain defects.
- If a tagged error has a `reason` field, model it with `Schema.Literals([...])` and PascalCase values.
- Keep error channels precise. Avoid `unknown` in `Effect<A, unknown>`, `Cause<unknown>`, and `Exit<A, unknown>` when failures are expected and typed.
- Inspect causes with the v4 flattened `Cause` shape: iterate `cause.reasons` and narrow with `Cause.isFailReason`, `Cause.isDieReason`, or `Cause.isInterruptReason`.
- Use `Cause.pretty(...)` when turning causes into user-visible or event payload text.
- Use explicit schemas for domain and AI output shapes. Prefer `Schema.Struct`, named schemas, or `Schema.Json` over `Schema.Unknown` in app code.
- Add `.annotate({ identifier: "MySchemaName" })` to named schemas.

## Anti-Patterns to Avoid

- Do not write `(...args) => Effect.gen(function* () { ... })` for effectful wrappers when `Effect.fnUntraced` or `Effect.fn` is the intended abstraction.
- Do not use removed or renamed v3 APIs such as `catchAll`, `catchAllCause`, `catchAllDefect`, `catchSome`, `catchSomeCause`, `Effect.fork`, `Effect.forkDaemon`, `Effect.forkAll`, or `Effect.forkWithErrorHandler`.
- Do not use `Effect.orDie`. First handle typed errors explicitly with `Effect.catchTag` or `Effect.catchTags`; then use `Effect.die` only for genuinely unrecoverable failures.
- Do not use the global `Error` class in app code for expected failures.
- Do not probe errors with checks like `if ("_tag" in error)`. Match on the typed Effect error channel instead.
- Do not expose defects, non-actionable failures, `unknown`, broad catches, or stringly errors from services.
- Do not invent generic tagged errors such as `XFailed`, `InternalError`, or `UnknownError` when a specific actionable error is required.
- Do not pattern match on v3 cause tree tags such as `Sequential`, `Parallel`, or `Empty`.
- Do not add bespoke `xFailureToMessage` helpers when `Cause.pretty(...)` or a message field on the tagged error should own formatting.
- Do not use `Schema.Unknown` for app models or AI output schemas.
- Do not mutate data unless code is truly performance critical; default to referentially transparent pure functions and immutable transforms.
- Do not cast branded entity IDs with `as EntityId`; construct them with the owning branded schema constructor such as `EntityId.makeUnsafe()`.
- Do not create barrel `index.ts` files. Import from the defining module.
- Do not use buttons for navigation actions. Use real links so browser semantics such as middle click, open-in-new-tab, and copy-link-target keep working.
- Do not add optional properties when every consumer must pass the value. Reserve optionality for genuine absence or generic primitive-level modules.
- Do not write nested application like `f(g(x))`; use `.pipe(...)` for pipeable values and Effect `pipe()` / `flow()` for non-pipeable values.
- Do not add manual logging or log annotations for error paths that OpenTelemetry spans already capture.
- Do not rely on arbitrary sleeps, timing races, uncontrolled external state, or live providers in normal tests.
- Do not test what TypeScript or third-party libraries already guarantee unless this repo adds meaningful integration behavior on top.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- whether code is pure, effectful, streaming, service-backed, layer-wired, or test-only
- expected vs non-actionable failures and the public error contract callers can handle
- service boundaries, layer composition, resource lifetime, and test replacement seams
- schema ownership for domain values, branded IDs, JSON, AI outputs, and error reasons
- observability boundaries where spans, metrics, or informational logs actually help operators
- whether tests need deterministic time, fibers, queues, layer replacement, or integration coverage

Effect-native code should tend toward:

- direct, typed Effect expressions with `Effect.fnUntraced` / `Effect.fn` only where they add value
- precise `Schema.TaggedErrorClass` failures in the error channel and defects only for unrecoverable faults
- `Context.Service` services, explicit layers, Effect `Stream`, first-party platform abstractions, and schema-backed boundaries
- immutable, readonly, DDD-colocated modules without barrels or global shared domain bags
- low-noise observability through Effect-native spans and domain-level informational logs
- deterministic behavior tests that use production composition and replace only true external boundaries

Applies to:

- authoring, refactoring, or reviewing general Effect application code
- enforcing current Effect v4 naming, error, service, stream, layer, cause, and testing conventions
- establishing cross-cutting defaults before loading a narrower Effect skill such as service, schema, stream, HTTP, or testing

Does not cover:

- library-specific deep patterns that are better handled by the narrower Effect skills in this directory
- broad architecture rewrites outside the user-requested behavior
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- old v3 Effect APIs appearing in new code
- typed errors being collapsed into defects, strings, `unknown`, broad `Error`, or generic failure classes
- service and layer boundaries becoming implicit, global, hard to test, or impossible to replace
- stream, SSE, WebSocket, and time-dependent code drifting into manual loops and races
- tests that chase coverage numbers instead of protecting user-visible behavior and regressions

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for core Effect wrappers, typed errors, architecture, observability, and testing defaults.
- Start with the typed shape of the computation: success value, expected error, and required context. Let that shape guide services, layers, schemas, and tests.
- Use `Effect.fnUntraced` for named reusable effectful functions when no span is needed; use named `Effect.fn("name")` when tracing is intentional.
- Keep boundary errors actionable and precise. Convert external failures into domain tagged errors only when callers can act on them; otherwise let defects remain defects or die at the service boundary.
- Keep layer construction and resource ownership explicit. Final application layers may erase unrecoverable construction errors with `Layer.orDie`; intermediate layers should preserve typed construction errors.
- Prefer pure functions, readonly data, Effect collection modules such as `Array`, and Effect `Optic` for repeated or complex immutable updates.
- Colocate domain modules with the domain that owns them, avoid global shared domain folders, avoid barrel files, and import from defining modules.
- Use Effect-native observability: `Effect.withSpan`, named `Effect.fn`, `Stream.withSpan`, `Metric.*`, and domain-level `Effect.log*` only when the event is useful outside debugging.
- Test through public behavior and production composition. Swap external boundaries with layers, use `TestClock` for time, and favor regression, user-path, and business-logic tests over implementation-detail checks.

## Gotchas

- If an effectful helper is written as an arrow returning `Effect.gen`, tracing, naming, and post-processing conventions drift quickly. Use `Effect.fnUntraced` or a direct Effect expression instead.
- If old v3 catch, fork, service, or cause APIs appear, examples from stale training data have leaked in. Replace them with v4 names and the flattened cause model.
- If a service exposes `unknown`, `Error`, `InternalError`, or `UnknownError`, callers cannot exhaustively handle expected failures. Model actionable failures as specific tagged errors and let non-actionable ones die.
- If errors are inspected with `"_tag" in error`, the program has already lost the benefit of typed error channels. Preserve the precise channel and use `catchTag` / `catchTags`.
- If stream, SSE, or WebSocket code uses manual reader loops or callback arrays, cleanup and backpressure bugs follow. Use `Stream` and first-party Effect encoding/socket abstractions.
- If layers are rebuilt accidentally, shared state and resource lifetime become surprising. Compose layers first and use `Layer.fresh` only when independent rebuilding is intentional.
- If tests use sleeps or live time, concurrency bugs become flaky instead of deterministic. Use `TestClock`, `Deferred`, `Queue`, scoped fibers, and layer replacement.
- If coverage becomes the goal, tests get noisy and brittle. Keep coverage above the floor with high-value regression, user-path, business-logic, and contract tests.

## References

- [`references/patterns-01-effect-core-runtime-standards.md`](./references/patterns-01-effect-core-runtime-standards.md): Read when: you need source-pattern detail for Effect wrappers, services, layers, streams, errors, v4 catch/fork names, causes, and schemas.
- [`references/patterns-02-architecture-standards.md`](./references/patterns-02-architecture-standards.md): Read when: you need source-pattern detail for immutable architecture, directory structure, DDD colocation, branded IDs, navigation semantics, optionality, piping, and schema identifiers.
- [`references/patterns-03-observability-and-testing-standards.md`](./references/patterns-03-observability-and-testing-standards.md): Read when: you need source-pattern detail for observability defaults, logging boundaries, test coverage, deterministic tests, and behavior-first testing.
