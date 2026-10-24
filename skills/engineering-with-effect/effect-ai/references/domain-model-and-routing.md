# Domain model and routing

## Ownership and provider selection

| Role | Owns |
| --- | --- |
| Domain AI capability | Product behavior, prompt intent, output normalization, caller errors |
| Application routing policy | Configured provider/model selection and required capabilities |
| Provider adapter | Provider request/response mapping and transport |
| Execution plan | Attempt limits, supplied model layers, schedules, and failure predicates |

Provider constructors such as `OpenAiLanguageModel.model` and `AnthropicLanguageModel.model` return a `Model`: a layer supplying `LanguageModel` plus provider/model metadata. Supply credentials and HTTP clients at the composition boundary. If a domain service captures a selected model for later use, `model.captureRequirements` captures its required services from the current context; choose that lifetime intentionally rather than resolving tenant credentials from unrelated callers.

Use `ExecutionPlan` with `Effect.withExecutionPlan` for attempts over alternative model layers, not a custom retry framework. The entire wrapped effect is re-executed: place only a replay-safe operation inside it. Each fallback must preserve required tool support, structured-output behavior, privacy constraints, and product quality. A plan does not establish equivalence or compensate completed tool effects.

## Structured generation

Use structured generation when fields drive downstream behavior. `generateObject` requests JSON output, applies the provider's codec transformer, joins response text, and decodes it into `response.value`. Do not manually parse `response.text` as a substitute: provider transformations can change the wire representation.

```ts
import { Effect, Schema } from "effect"
import { LanguageModel } from "effect/ai"

const EvidenceAnswer = Schema.Struct({
  answer: Schema.String,
  citedDocumentIds: Schema.Array(Schema.String)
})

const draftAnswer = (question: string) =>
  Effect.gen(function*() {
    const response = yield* LanguageModel.generateObject({
      prompt: question,
      schema: EvidenceAnswer
    })
    return response.value
  })
```

This is a draft, not a verified answer: the domain must check that citations belong to authorized retrieved documents and support the claims. Schema decoding cannot establish that evidence relationship.

Provider JSON-schema support is not uniform. Adapters can use native structured output or a forced output tool whose input is mapped back to response text. Check the configured adapter and model's capabilities; keep these mechanics out of domain prompts. Unsupported schemas require a schema/adapter change, not repeated generation.

## Conversation and streaming ownership

Use `Chat` when history is part of the behavior, not merely because a model accepts messages. A chat instance owns mutable history and serializes its generation operations. Scope it to a conversation; sharing one across unrelated users mixes their context. Use the provided export/restore or persistence boundary and version application-owned stored envelopes as needed.

A successful non-streaming call appends the prompt and response. `Chat.streamText` records accumulated parts on release, including interruption or failure; history is not a transaction that commits only a complete answer. Decide whether partial text may influence later turns, and reconcile history before retrying when it must not.

Expose text deltas or domain events rather than provider-specific part variants unless passthrough is the product. Preserve completion versus truncation/failure, usage where relevant to budgets, and tool approval events. A stream of text alone must not make an incomplete answer appear committed.

## Source anchors

Effect v4 source paths:

- `packages/effect/src/ai/Model.ts`: `Model`, `captureRequirements`, metadata.
- `packages/effect/src/ExecutionPlan.ts` and `packages/effect/src/internal/executionPlan.ts`: layer selection and whole-effect attempts.
- `packages/effect/src/ai/LanguageModel.ts`: `generateObject`, `resolveStructuredOutput`.
- `packages/ai/openai/src/OpenAiLanguageModel.ts`: `prepareResponseFormat`; `packages/ai/anthropic/src/AnthropicLanguageModel.ts`: `prepareTools`, `getOutputFormat`, `makeResponse`.
- `packages/ai/openai/test/OpenAiLanguageModel.test.ts`: `uses json_schema format for structured output`; `packages/ai/anthropic/test/AnthropicLanguageModel.test.ts`: native structured output and capability-override cases.
- `packages/effect/src/ai/Chat.ts` and `packages/effect/test/ai/Chat.test.ts`: history ownership; `keeps partial assistant text when streamText is interrupted`.
