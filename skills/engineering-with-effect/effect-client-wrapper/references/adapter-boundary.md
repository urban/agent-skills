# Adapter boundary

## Capability and failure ownership

Prefer named domain methods when callers benefit from stable product vocabulary and normalized responses. Split a shared low-level adapter from domain services when they need different recovery or response models. Keep a generic escape hatch for very large SDKs or low-level adapter modules; its descriptor can carry the operation name, invocation, and safe telemetry metadata. Let its invocation receive cancellation as well as the private client. Returning the raw client or provider response throughout the application defeats the boundary.

Separate construction/configuration errors from request errors if startup recovery differs from one failed operation. Use `Effect.try` for a fallible synchronous constructor and `Effect.tryPromise` for an asynchronous invocation. Put the constructor or SDK call inside the thunk: wrapping an already-started Promise does not make each Effect execution a fresh request, so retries can merely reobserve the same rejection.

`Effect.tryPromise({ try, catch })` translates both synchronous invocation throws and Promise rejections. Its mapper must return an error, not throw; a throwing mapper becomes a defect. `Effect.promise` treats rejection as a defect, so it is not the normal adapter for fallible SDK requests. Avoid broad cause recovery that turns application defects or interruption into provider failures.

Translate unknown external values defensively. Preserve safe codes, statuses, bounded retry hints, and vetted request IDs when they support recovery; do not blindly copy messages, headers, response bodies, or raw `cause`. Credentials wrapped in `Redacted` are protected during normal inspection, not after the SDK has copied their unwrapped value into an exception. Higher-level services may translate a safe adapter error into domain outcomes, such as a documented provider not-found response becoming domain absence. Do not convert authentication or transport failures into absence.

## Cancellation is a transport contract

The Promise thunk receives an `AbortSignal` when it declares an ordinary parameter, for example `try: (signal) => sdkCall(signal)`. Forward it using the SDK's documented request options. Effect v4 uses the thunk's runtime arity to decide whether to allocate a controller: rest forwarding and default-valued signal parameters can silently lose the signal.

Interruption aborts that signal but cannot force the SDK or provider to stop. If cancellation is unsupported, document that in-flight work can outlive the fiber and use provider deadlines or an explicit SDK cancellation handle where available. Do not claim an Effect timeout rolls back remote work.

For a callback API with a cancellation handle, `Effect.callback` can return a cleanup Effect that cancels the in-flight request on interruption. That cleanup is not a general finalizer for successful completion; persistent subscriptions and client resources need scope ownership instead.

## Example: a narrow, cancellable read

This illustrative SDK accepts a signal in its request options. The adapter exposes only the domain projection and deliberately omits the untrusted rejection value; a real provider classifier can add vetted recovery details.

```ts
import { Data, Effect } from "effect"

interface ReceiptSdk {
  getReceipt(
    id: string,
    options: { readonly signal: AbortSignal }
  ): Promise<{ readonly status: "pending" | "paid" }>
}

class ReceiptReadError extends Data.TaggedError("ReceiptReadError")<{}> {}

const makeReceiptReader = (client: ReceiptSdk) => ({
  isPaid: (id: string) =>
    Effect.tryPromise({
      try: (signal) => client.getReceipt(id, { signal }),
      catch: () => new ReceiptReadError()
    }).pipe(Effect.map((receipt) => receipt.status === "paid"))
})
```

This reader borrows the client; construction and release belong to its caller. If an SDK's successful response is untrusted, decode it at the adapter boundary before projecting domain values. Keep a response-contract failure distinct from a transient transport rejection rather than retrying every malformed response.
