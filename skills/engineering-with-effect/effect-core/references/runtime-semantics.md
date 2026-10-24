# Runtime semantics

## Function and runtime boundaries

- Keep a computation as an Effect value when it needs no reusable parameter boundary. Reusing an ordinary Effect value does not automatically memoize its result; caching is a separate policy.
- Choose a reusable Effect function when domain inputs or an operation identity add meaning. `Effect.fn("operationName")(body)` creates a span when the returned Effect runs; unnamed `Effect.fn(body)` adds stack-frame context without a span. Use `Effect.fnUntraced` when no added span or stack-frame boundary is wanted. Do not turn every helper into a named span.
- Function construction is not execution. Keep state that belongs to one execution inside the Effect body, rather than accidentally sharing it across calls or repeated runs.
- Reserve `runPromise`, `runFork`, and callback runners for integration edges. Within an Effect, compose the operation directly instead of wrapping `runPromise(operation)` in a Promise adapter: a runner starts an independent root fiber and loses the enclosing fiber’s automatic supervision and context inheritance.
- At a Promise boundary, `runPromise` rejects with a squashed cause. Use `runPromiseExit` when the adapter must distinguish expected failure, defect, and interruption without losing the structured cause. Connect external cancellation through the runner’s `signal` option; do not assume abandoning a Promise interrupts its fiber.

## Expected failure and defect policy

| Outcome | Model as | Reason |
| --- | --- | --- |
| Caller can recover, retry, ask for input, or choose another path | Typed expected error | Recovery belongs in the public contract |
| Dependency detail changes no caller decision | Boundary-owned translation or terminal handling | Avoid infrastructure unions without turning operational failures into defects |
| Broken invariant, impossible state, programmer fault | Defect | Recovery would hide corruption or a bug |
| External data violates an accepted contract | Typed boundary error | The boundary can explain what was rejected |

Use `Effect.try` / `Effect.tryPromise` when a foreign API’s throws or rejections represent expected failure; map them into the boundary’s useful error vocabulary. Throws from `Effect.sync` and rejections from `Effect.promise` become defects. The constructor therefore expresses failure policy, not just sync versus async behavior. Preserve the original external error as diagnostic detail when useful, without substituting an opaque cause for a useful domain taxonomy.

`orDie` is an explicit policy change: it promotes expected errors to defects, not merely a way to shorten a signature. Defect recovery belongs at deliberate containment boundaries, such as isolating an untrusted plugin, not in ordinary domain fallback logic.

## Causes and recovery

`Cause` holds a `reasons` array of `Fail`, `Die`, and `Interrupt` entries. A cause can contain multiple kinds; extracting the first error is not a complete account of the failure.

Typed recovery such as `catch` and `catchTag` is not full-cause recovery. If a cause contains a defect, typed recovery is skipped and ordinary typed failures are promoted to defects, preserving reason order and interrupts. An interrupt reason alongside a typed error does not by itself block typed recovery. Distinguish these data-level rules from a live interruption request: an interrupted fiber can skip handlers in an interruptible region, so `catchCause` is not a way to make canceled work continue.

`catchDefect` can recover a mixed cause containing a defect; it is not a filter that preserves every other reason. Use full-cause inspection when policy depends on all reasons. Transparent instrumentation should leave the cause intact: prefer `tapCause`, or re-fail with `Effect.failCause(cause)` after intentional cause handling. Instrumentation that itself fails or dies can change the outcome.

Do not discard a cause just because it includes cancellation:

```ts
import { Cause } from "effect"

const shutdownFailure = Cause.combine(
  Cause.interrupt(1),
  Cause.die(new Error("Failed to flush audit log during shutdown"))
)

Cause.hasInterrupts(shutdownFailure) // true: cancellation is present
Cause.hasInterruptsOnly(shutdownFailure) // false: cleanup also failed
```

Only an interruption-only cause is eligible for a boundary policy that ignores ordinary cancellation. Format causes at a human-facing or protocol boundary, not before making recovery decisions.

## Requirements and fiber ownership

Capture a requirement where its implementation and lifetime are owned. Pass it through a public effect only when the caller is intentionally responsible for supplying that capability, such as a request or transaction context. Providing a context does not extend the lifetime of resources stored in it.

Prefer `Effect.all` with a concurrency option or a race combinator when the concurrent work belongs to one result. For explicit fibers, choose lifetime and observation separately:

| Lifetime owner | Operation | Consequence |
| --- | --- | --- |
| Parent fiber | `Effect.forkChild` | Parent termination interrupts remaining child work |
| Current resource scope | `Effect.forkScoped` | Scope closure interrupts the fiber, even if the forking fiber has already finished |
| Explicit resource scope | `Effect.forkIn` | The chosen scope, not the immediate parent, determines shutdown |
| External supervisor | `Effect.forkDetach` | No automatic parent or scope shutdown; retain a handle and define observation and interruption |

Detached work inherits context, not ownership of the resources in that context. A request-owned connection can close while a detached fiber still refers to it.

Forking does not make the child’s result part of the parent’s result. `Fiber.join` propagates the child’s cause; `Fiber.await` returns an `Exit` for explicit policy. Neither scope ownership nor simply retaining the handle is a substitute for deciding what a failed background task means.

## Interruption and cleanup

Interruption is cooperative, not an ordinary typed error and not a force-kill of foreign work. `Fiber.interrupt` waits for completion, including finalizers and uninterruptible regions. A hung finalizer or uninterruptible wait can therefore hang shutdown.

Use scoped acquisition or bracketing to register cleanup before exposing a resource. `acquireRelease` protects acquisition by default and runs release when its scope closes; `acquireUseRelease` brackets one use. Avoid manually placing cleanup only after the successful path.

Keep uninterruptible regions narrow. When a critical transition contains waiting work, `uninterruptibleMask` provides `restore` to reinstate the previous interruptibility around that work. Restoring is not necessarily forcing interruptibility: the caller may already have been masked.

Foreign asynchronous work must cooperate too. Pass the supplied `AbortSignal` from `tryPromise` or `promise` to APIs that support cancellation; interruption cannot stop a Promise’s underlying operation if it ignores the signal.
