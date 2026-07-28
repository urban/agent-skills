---
name: effect-client-wrapper
description: Pattern for wrapping third-party SDK clients (Stripe, Resend, AWS, etc.) with Effect. Use when creating Effect services that wrap external libraries with Promise-based APIs. Provides type-safe error handling, automatic tracing, and clean dependency injection via the "use" pattern.
---

# Effect Client Wrapper Pattern

Wrap third-party SDK clients with an Effect `Context.Service`. Use this when an SDK exposes Promise-based methods (Stripe, Resend, AWS SDK, etc.) and you want typed errors, tracing, configuration, testable layers, and a narrow dependency-injection boundary.

Prefer exposing named domain methods. Keep a generic `use` method only as a low-level SDK escape hatch or when the SDK surface is too large to wrap directly.

## Rules this pattern follows

- Define services with `Context.Service`.
- Return service implementations with `MyService.of(...)`.
- Put the production implementation on `static readonly layer` (lowercase), commonly with `layerNoDeps` when dependencies are composed separately.
- Define custom errors with `Schema.TaggedErrorClass`.
- Use `Schema.Defect()` for opaque thrown/rejected causes.
- Define Effect-returning functions with `Effect.fn("Name")`; do not create functions that return `Effect.gen(...)`.
- `Effect.fn` creates a span. Add dynamic metadata with `Effect.annotateCurrentSpan` / `Effect.annotateSpans`.
- Use `Layer.withSpan(...)` for layer construction tracing.
- Use `Config.redacted` and unwrap with `Redacted.value` only at the SDK boundary.

## Base pattern

```typescript
import { Config, Context, Effect, Layer, Redacted, Schema } from "effect"

// Replace with the real SDK import.
import { ThirdPartyClient } from "third-party-sdk"

// 1. Define schema-backed tagged errors.
export class MyClientInstantiationError extends Schema.TaggedErrorClass<MyClientInstantiationError>()(
  "MyClientInstantiationError",
  {
    cause: Schema.Defect()
  }
) {}

export class MyClientError extends Schema.TaggedErrorClass<MyClientError>()("MyClientError", {
  operation: Schema.String,
  cause: Schema.Defect()
}) {}

// 2. Define the service shape.
export interface MyClientService {
  use<A>(
    operation: string,
    f: (client: ThirdPartyClient) => Promise<A>
  ): Effect.Effect<A, MyClientError>
}

// 3. Define the Context.Service and live layer.
export class MyClient extends Context.Service<MyClient, MyClientService>()(
  "myapp/integrations/MyClient"
) {
  static readonly layer: Layer.Layer<
    MyClient,
    Config.ConfigError | MyClientInstantiationError
  > = Layer.effect(
    MyClient,
    Effect.gen(function*() {
      const apiKey = yield* Config.redacted("MY_CLIENT_API_KEY")

      const client = yield* Effect.try({
        try: () => new ThirdPartyClient({ apiKey: Redacted.value(apiKey) }),
        catch: (cause) => new MyClientInstantiationError({ cause })
      })

      const use: MyClientService["use"] = Effect.fn("MyClient.use")(
        function*<A>(
          operation: string,
          f: (client: ThirdPartyClient) => Promise<A>
        ): Effect.fn.Return<A, MyClientError> {
          yield* Effect.annotateCurrentSpan({ operation })

          return yield* Effect.tryPromise({
            try: () => f(client),
            catch: (cause) => new MyClientError({ operation, cause })
          })
        }
      )

      return MyClient.of({ use })
    })
  ).pipe(Layer.withSpan("MyClient.layer"))
}
```

## Usage

```typescript
const program = Effect.gen(function*() {
  const myClient = yield* MyClient

  const result = yield* myClient.use("someMethod", (client) =>
    client.someMethod({ param: "value" })
  )

  return result
})

program.pipe(Effect.provide(MyClient.layer))
```

## Named domain methods (preferred)

Expose focused methods when the rest of the application should not know about the SDK shape.

```typescript
import { Context, Effect, Layer, Schema } from "effect"

export class EmailClientError extends Schema.TaggedErrorClass<EmailClientError>()(
  "EmailClientError",
  {
    reason: MyClientError
  }
) {}

export interface EmailClientService {
  sendEmail(params: SendEmailParams): Effect.Effect<EmailResult, EmailClientError>
  getEmail(id: string): Effect.Effect<Email, EmailClientError>
}

export class EmailClient extends Context.Service<EmailClient, EmailClientService>()(
  "myapp/email/EmailClient"
) {
  static readonly layerNoDeps = Layer.effect(
    EmailClient,
    Effect.gen(function*() {
      const sdk = yield* MyClient

      const sendEmail = Effect.fn("EmailClient.sendEmail")(function*(
        params: SendEmailParams
      ) {
        yield* Effect.annotateCurrentSpan({ to: params.to })

        return yield* sdk.use("emails.send", (client) =>
          client.emails.send(params)
        ).pipe(
          Effect.mapError((reason) => new EmailClientError({ reason }))
        )
      })

      const getEmail = Effect.fn("EmailClient.getEmail")(function*(id: string) {
        yield* Effect.annotateCurrentSpan({ id })

        return yield* sdk.use("emails.get", (client) =>
          client.emails.get(id)
        ).pipe(
          Effect.mapError((reason) => new EmailClientError({ reason }))
        )
      })

      return EmailClient.of({ sendEmail, getEmail })
    })
  )

  static readonly layer = this.layerNoDeps.pipe(
    Layer.provide(MyClient.layer)
  )
}
```

## Retry policy

Use `Schedule` with typed SDK errors. Prefer retrying only errors that are known to be transient.

```typescript
import { Effect, Schedule } from "effect"

const retryPolicy = Schedule.max([
  Schedule.exponential("250 millis"),
  Schedule.recurs(3)
]).pipe(Schedule.jittered)

const useWithRetry: MyClientService["use"] = Effect.fn("MyClient.use")(
  function*<A>(
    operation: string,
    f: (client: ThirdPartyClient) => Promise<A>
  ): Effect.fn.Return<A, MyClientError> {
    yield* Effect.annotateCurrentSpan({ operation })

    return yield* Effect.tryPromise({
      try: () => f(client),
      catch: (cause) => new MyClientError({ operation, cause })
    }).pipe(
      Effect.retry(retryPolicy)
    )
  }
)
```

If only some failures are retryable, add a field to your error (for example `retryable: Schema.Boolean`) and use `Schedule.while(({ input }) => input.retryable)`.

## Clients with lifecycle / cleanup

If the SDK client must be closed, acquire it with `Effect.acquireRelease` inside the layer. Layer acquisition is scoped, so the release action runs when the layer is torn down.

```typescript
export class MyClient extends Context.Service<MyClient, MyClientService>()(
  "myapp/integrations/MyClient"
) {
  static readonly layer = Layer.effect(
    MyClient,
    Effect.gen(function*() {
      const apiKey = yield* Config.redacted("MY_CLIENT_API_KEY")

      const client = yield* Effect.acquireRelease(
        Effect.try({
          try: () => new ThirdPartyClient({ apiKey: Redacted.value(apiKey) }),
          catch: (cause) => new MyClientInstantiationError({ cause })
        }),
        (client) =>
          Effect.tryPromise(() => client.close()).pipe(
            Effect.catchCause((cause) => Effect.logWarning("failed to close client", cause))
          )
      )

      const use: MyClientService["use"] = Effect.fn("MyClient.use")(
        function*<A>(
          operation: string,
          f: (client: ThirdPartyClient) => Promise<A>
        ): Effect.fn.Return<A, MyClientError> {
          yield* Effect.annotateCurrentSpan({ operation })
          return yield* Effect.tryPromise({
            try: () => f(client),
            catch: (cause) => new MyClientError({ operation, cause })
          })
        }
      )

      return MyClient.of({ use })
    })
  )
}
```

## Test layer

Keep tests independent of the real SDK by providing the same service with a fake implementation.

```typescript
export const MyClientTest = Layer.succeed(
  MyClient,
  MyClient.of({
    use: Effect.fn("MyClient.useTest")(function*<A>(
      operation: string,
      _f: (client: ThirdPartyClient) => Promise<A>
    ): Effect.fn.Return<A, MyClientError> {
      return yield* new MyClientError({
        operation,
        cause: new Error("No test implementation registered")
      })
    })
  })
)
```

For richer tests, store expected responses in a `Ref` service and implement `use` by looking up the requested `operation`.

## Real-world example: Stripe

```typescript
import Stripe from "stripe"
import { Config, Context, Effect, Layer, Redacted, Schema } from "effect"

export class StripeInstantiationError extends Schema.TaggedErrorClass<StripeInstantiationError>()(
  "StripeInstantiationError",
  {
    cause: Schema.Defect()
  }
) {}

export class StripeClientError extends Schema.TaggedErrorClass<StripeClientError>()(
  "StripeClientError",
  {
    operation: Schema.String,
    cause: Schema.Defect()
  }
) {}

export interface StripeClientService {
  use<A>(
    operation: string,
    f: (stripe: Stripe) => Promise<A>
  ): Effect.Effect<A, StripeClientError>
}

export class StripeClient extends Context.Service<StripeClient, StripeClientService>()(
  "myapp/billing/StripeClient"
) {
  static readonly layer = Layer.effect(
    StripeClient,
    Effect.gen(function*() {
      const secretKey = yield* Config.redacted("STRIPE_SECRET_KEY")

      const stripe = yield* Effect.try({
        try: () => new Stripe(Redacted.value(secretKey)),
        catch: (cause) => new StripeInstantiationError({ cause })
      })

      const use: StripeClientService["use"] = Effect.fn("StripeClient.use")(
        function*<A>(
          operation: string,
          f: (stripe: Stripe) => Promise<A>
        ): Effect.fn.Return<A, StripeClientError> {
          yield* Effect.annotateCurrentSpan({ operation })
          return yield* Effect.tryPromise({
            try: () => f(stripe),
            catch: (cause) => new StripeClientError({ operation, cause })
          })
        }
      )

      return StripeClient.of({ use })
    })
  ).pipe(Layer.withSpan("StripeClient.layer"))
}

export const createCustomer = Effect.fn("createCustomer")(function*(email: string) {
  const stripe = yield* StripeClient

  return yield* stripe.use("customers.create", (client) =>
    client.customers.create({ email })
  )
})
```

## Common pitfalls

- Use `class Name extends Context.Service<Name, ServiceShape>()("app/Name")` for service definitions.
- Use `Schema.TaggedErrorClass` for typed service errors.
- Do not expose the raw SDK client unless callers truly need it. Prefer named service methods or a narrow `use` escape hatch.
- Pass an explicit `operation` string for telemetry and annotate the current span.
- Do not log `Redacted.value(secret)` or include it in errors/spans.
- Do not hide layer construction failures. Let configuration and instantiation errors remain in the layer error channel.
