# Testing

When available, use `principle-test-capabilities` for general test-boundary and evidence decisions, resolving it by name through host discovery. This topic specializes those decisions for Effect ownership, interruption, layer sharing, and generated evaluations.

Exercise caller-visible behavior through the closest useful public composition. Replace genuine external uncertainty rather than every collaborator. A fake should preserve the ordering, uniqueness, transactions, failure, or cancellation semantics relevant to the claim; omitted behavior remains unproven.

Treat test sharing as an explicit ownership choice. Isolate mutable state and identity-specific dependencies unless sharing is part of the contract. For asynchronous behavior, identify the application milestone that makes the next assertion meaningful; elapsed time is not evidence of that milestone. Assert resource release only after its owner has actually closed.

Choose observations by contract. Exact calls matter for wire payloads, command arguments, idempotency keys, or release obligations. Incidental call order, private queues, and cache layout usually obscure the behavior. Preserve a concrete regression example when it expresses the bug more clearly than a broad property.

Use properties for named domain laws, with an independent oracle and input space covering the promised representation. A canonicalization law is different from lossless round-trip identity. Stateful Effect properties need a fresh system and model for every evaluation, including shrinking; reproducing generated inputs does not reproduce uncontrolled external state.

**Tradeoff:** handler-level evidence may be sufficient for domain and protocol interpretation, while transport, restart, persistence, or shutdown claims need their actual owners exercised. Use Effect's testing documentation for APIs and harness setup; this topic determines what those tests must establish.

## Supply the external edge, exercise the production capability

This example uses Effect 4.1.0. Check the consuming project's installed source before adapting APIs. The contract is that provider unavailability becomes a caller-actionable `SummaryUnavailable` identifying the document. `Summary.layer` is the production implementation; only `TextProvider` is replaced. In an application test, import the production contract and layer rather than copying them into the test.

```ts
import assert from "node:assert/strict"
import { test } from "node:test"
import { Context, Effect, Layer, Schema } from "effect"

class ProviderUnavailable extends Schema.TaggedError<ProviderUnavailable>()("ProviderUnavailable", {}) {}
class SummaryUnavailable extends Schema.TaggedError<SummaryUnavailable>()("SummaryUnavailable", {
  documentId: Schema.String
}) {}

class TextProvider extends Context.Service<TextProvider, {
  generate(source: string): Effect.Effect<string, ProviderUnavailable>
}>()("example/TextProvider") {}

class Summary extends Context.Service<Summary, {
  create(documentId: string, source: string): Effect.Effect<string, SummaryUnavailable>
}>()("example/Summary") {
  static readonly layer = Layer.effect(Summary, Effect.gen(function*() {
    const provider = yield* TextProvider
    const create = Effect.fn("Summary.create")(function*(documentId: string, source: string) {
      return yield* provider.generate(source).pipe(
        Effect.mapError(() => new SummaryUnavailable({ documentId }))
      )
    })
    return Summary.of({ create })
  }))
}

test("provider unavailability identifies the document in the public failure", async () => {
  const provider = Layer.succeed(TextProvider, {
    generate: () => Effect.fail(new ProviderUnavailable({}))
  })
  const application = Summary.layer.pipe(Layer.provide(provider))

  await Effect.runPromise(Effect.gen(function*() {
    const summary = yield* Summary
    const error = yield* Effect.flip(summary.create("doc-7", "Meeting transcript"))
    assert.ok(error instanceof SummaryUnavailable)
    assert.equal(error.documentId, "doc-7")
  }).pipe(Effect.provide(application)))
})
```

`Effect.flip` exchanges success and typed failure channels: an expected failure becomes a value to inspect, while unexpected success fails the test. Defects and interruption require their own cause/exit observations. The fixture supplies a provider failure, but the production capability must perform the translation; passing the provider error through would fail this test. This does not prove provider protocol compatibility, model quality, or resource cleanup.

Source basis: the consuming project's installed `effect/AGENTS.md`, `ai-docs/src/09_testing/20_layer-tests.ts`, and `src/Effect.ts` (`flip`); these are library-relative paths. API facts remain with that source, not this example.
