# Effect Core runtime standards for agents — part 1

Source: `/Volumes/Code/personal/agent-skills/RULES.md`. This chunk is vendored so the skill remains atomic.

Covers:

- effectful wrapper conventions
- `Effect.gen` and yieldable usage
- `Context.Service` and service access
- streams, SSE, WebSockets
- layer typing and composition
- typed errors, catch and fork APIs
- causes and schemas

---

# Effect runtime standards

## Effect wrappers

- Effectful wrappers must use `Effect.fnUntraced` unless spans are required.
- Use `Effect.fn("name")` when spans are needed, with the name matching the function.
- Do not write `(...args) => Effect.gen(function* () { ... })` for reusable effectful wrappers.
- Pass `Effect.fn` / `Effect.fnUntraced` post-processing combinators as additional arguments to the function constructor.
- Do not call `.pipe(...)` on the function returned by `Effect.fn`.
- An `Effect.fnUntraced` that only does `return yield* effect` is not allowed. Write the direct effect expression instead of wrapping it in a generator.
- Outside generators, yieldables must be converted with `.asEffect()` before piping.
- In `Effect.gen` methods that need `this`, pass `Effect.gen({ self: this }, function* () { ... })`; do not pass `this` directly as the first argument.

## Services

- Define services with `Context.Service`.
- Do not use v3 `Context.Tag`, `Context.GenericTag`, `Effect.Tag`, or `Effect.Service`.
- Yield services inside effect bodies instead of using static accessor proxies.
- Yield services from context inside effect bodies. Do not pass service instances as function arguments.
- Services must expose typed errors, not defects.
- Services must expose typed errors only for actionable failures that callers can handle.
- Non-actionable failures must not be exposed as typed errors. Catch them at the service definition with `Effect.catchTag` or `Effect.catchTags` and `Effect.die`, or let existing defects propagate naturally.

## Streams, SSE, and WebSockets

- All streaming implementations, including SSE and WebSockets, must use Effect `Stream`.
- SSE must use `effect/unstable/encoding/Sse` for framing.
- WebSockets must use first-party Effect socket abstractions.

## Layers

- Final live layers such as `Rpc.toLayer`, service layers, and middleware layers must be typed as `Layer.Layer<ProvidedServices>`.
- Intermediate and test-exported layers should infer naturally.
- Use `Layer.orDie` only on final live compositions whose remaining errors are truly unrecoverable.
- Prefer composing layers before providing them.
- Use `Layer.fresh` or `Effect.provide(layer, { local: true })` only when a layer subtree must be rebuilt independently, such as test isolation.

## Error handling

- Never use `Effect.orDie`.
- Handle typed errors explicitly with `Effect.catchTag` or `Effect.catchTags`, then `Effect.die` only when the failure is genuinely unrecoverable.
- Use catch combinators: `Effect.catch`, `Effect.catchCause`, `Effect.catchDefect`, `Effect.catchFilter`, `Effect.catchCauseFilter`, `Effect.catchTag`, and `Effect.catchTags`.
- Do not use removed or renamed v3 forms such as `catchAll`, `catchAllCause`, `catchAllDefect`, `catchSome`, or `catchSomeCause`.
- Do not use the global `Error` class in app code.
- Use `Schema.TaggedErrorClass` with a `_tag` discriminator.
- Reuse an existing tagged error when one already fits.
- Do not probe errors with checks like `if ("_tag" in error)`. All app errors should already be values from `Schema.TaggedErrorClass` classes with a typed `_tag`; match on the typed error channel instead.
- If a tagged error has a `reason` field, it must use `Schema.Literals([...])` with PascalCase values.
- Do not invent generic typed errors like `XFailed`, `InternalError`, or `UnknownError`.
- When a failure is actionable, define a specific `Schema.TaggedErrorClass` for it.
- Do not erase error channels with `unknown` in `Effect<A, unknown>`, `Cause<unknown>`, or `Exit<A, unknown>`.
- Keep expected errors precisely typed so callers can safely pattern match on `_tag`.

## Fibers

- For forked fibers, use names: `Effect.forkChild`, `Effect.forkDetach`, `Effect.forkScoped`, or `Effect.forkIn`.
- Do not use removed or renamed v3 forms such as `Effect.fork`, `Effect.forkDaemon`, `Effect.forkAll`, or `Effect.forkWithErrorHandler`.

## Causes

- When inspecting causes, use the flattened `Cause` shape.
- Iterate `cause.reasons` and narrow with `Cause.isFailReason`, `Cause.isDieReason`, or `Cause.isInterruptReason`.
- When turning Effect causes into user-visible or event payload text, use `Cause.pretty(...)`.
- Do not add bespoke `xFailureToMessage` style helpers.
- If an error needs a better message than its `_tag` or existing fields provide, define that message on the tagged error itself.

## Schemas

- Do not use `Schema.Unknown` in app code or AI output schemas.
- Use explicit `Schema.Struct` shapes or `Schema.Json`.
