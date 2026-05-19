# Effect AI patterns for agents — part 1

Covers:

- Effect AI patterns for agents
- First principles
- Behavior encapsulation
- Wrap model calls in a use-case service
- Separate provider routing from behavior
- Modular, testable, maintainable services
- Capture model requirements in Layers

---

# Effect AI patterns for agents

## First principles

- Encapsulate AI behavior behind domain services. Application code should call methods like `scoreAnswer`, `generateThreadTitle`, or `draftFeedback`, not scatter `LanguageModel.generateText` calls through handlers.
- Keep provider details at the edge. Use `OpenAiLanguageModel.model(...)`, `AnthropicLanguageModel.model(...)`, `Model.make(...)`, or an `ExecutionPlan` in Layers and adapters, not in domain logic.
- Use `Schema` at every AI boundary: structured output schemas, tool parameter schemas, tool success schemas, prompt input parsing, persisted chat history, and provider response decoding.
- Prefer `LanguageModel.generateObject` for structured data. Do not ask for JSON and parse it manually in application code.
- Prefer `Stream.Stream` for partial model output. Do not hand-roll web reader loops for model streaming.
- Treat tools as capabilities with typed schemas and handlers, not as arbitrary callbacks. Group them with `Toolkit.make` and provide handlers via `toLayer`.
- Map provider-agnostic `AiError.AiError` to a domain tagged error at the service boundary when callers should not depend on AI internals.
- Build tests by swapping the `LanguageModel.LanguageModel`, toolkit handler, provider client, or process boundary layer. Tests should not hit live model providers.

## Behavior encapsulation

### Wrap model calls in a use-case service

The docs in `.dotai/repos/effect/ai-docs/src/71_ai/10_language-model.ts` define `AiWriter` as a `Context.Service` with domain methods that hide provider selection, prompts, structured output decoding, streaming, and error mapping. Follow the same shape for project features.

```ts
import { Context, Effect, Layer, Schema, Stream } from "effect";
import { AiError, LanguageModel, type Response } from "effect/unstable/ai";

export class AssessmentAiError extends Schema.TaggedErrorClass<AssessmentAiError>()(
  "AssessmentAiError",
  { reason: AiError.AiErrorReason },
) {
  static fromAiError(error: AiError.AiError): AssessmentAiError {
    return new AssessmentAiError({ reason: error.reason });
  }
}

export const AnswerScore = Schema.Struct({
  score: Schema.Number,
  rationale: Schema.String,
}).annotate({ identifier: "AnswerScore" });

export class AssessmentAi extends Context.Service<
  AssessmentAi,
  {
    readonly scoreAnswer: (input: {
      readonly question: string;
      readonly answer: string;
    }) => Effect.Effect<typeof AnswerScore.Type, AssessmentAiError>;
    readonly streamFeedback: (answer: string) => Stream.Stream<string, AssessmentAiError>;
  }
>()("fiberisle/AssessmentAi") {
  static readonly layer = Layer.effect(
    AssessmentAi,
    Effect.gen(function* () {
      const scoreAnswer = Effect.fn("AssessmentAi.scoreAnswer")(
        function* (input: { readonly question: string; readonly answer: string }) {
          const response = yield* LanguageModel.generateObject({
            objectName: "answer_score",
            schema: AnswerScore,
            prompt: [
              "Score the answer from 0 to 100.",
              `Question: ${input.question}`,
              `Answer: ${input.answer}`,
            ].join("\n"),
          });

          return response.value;
        },
        Effect.catchTag("AiError", (error) => Effect.fail(AssessmentAiError.fromAiError(error))),
      );

      const streamFeedback = (answer: string) =>
        LanguageModel.streamText({
          prompt: `Give concise feedback for this answer:\n${answer}`,
          toolChoice: "none",
        }).pipe(
          Stream.filter((part): part is Response.TextDeltaPart => part.type === "text-delta"),
          Stream.map((part) => part.delta),
          Stream.mapError((error) => AssessmentAiError.fromAiError(error)),
        );

      return AssessmentAi.of({ scoreAnswer, streamFeedback });
    }),
  );
}
```

Guidelines:

- The service API should be stable and domain-shaped. Do not leak prompt strings, provider request bodies, raw `Response.Part` arrays, or provider-specific config unless that is the explicit domain.
- Keep prompt construction pure when it is large or shared. Build prompts and schemas in pure helpers, while provider modules execute them.
- Keep post-processing in the service. Decode structured output, then sanitize domain values before returning them.
- Use `Chat` only when conversation history is part of the behavior. For one-shot extraction or generation, use `LanguageModel.generateText` / `generateObject` directly.

### Separate provider routing from behavior

Route requests to a provider instance registry when provider selection is runtime-configurable. The caller supplies a `modelSelection`, the router finds the configured provider instance, and the provider-specific closure owns execution.

```ts
export interface TextGenerationShape {
  readonly generateThreadTitle: (
    input: ThreadTitleInput,
  ) => Effect.Effect<ThreadTitle, TextGenerationError>;
}

const resolveInstance = (
  registry: ProviderInstanceRegistryShape,
  operation: "generateThreadTitle",
  instanceId: ProviderInstanceId,
): Effect.Effect<TextGenerationShape, TextGenerationError> =>
  registry.getInstance(instanceId).pipe(
    Effect.flatMap((instance) =>
      instance === undefined
        ? Effect.fail(
            new TextGenerationError({
              operation,
              detail: `No provider instance registered for '${instanceId}'.`,
            }),
          )
        : Effect.succeed(instance.textGeneration),
    ),
  );
```

Guidelines:

- A router service chooses _which_ provider instance to use.
- A provider adapter service chooses _how_ to call that provider.
- A domain service chooses _what behavior_ the product needs.
- Do not mix those responsibilities in one function.

## Modular, testable, maintainable services

### Capture model requirements in Layers

The Effect docs use provider client Layers and `captureRequirements` so model dependencies are pulled into the service Layer once.

```ts
import { Config, Effect, ExecutionPlan, Layer } from "effect";
import { AnthropicClient, AnthropicLanguageModel } from "@effect/ai-anthropic";
import { OpenAiClient, OpenAiLanguageModel } from "@effect/ai-openai";
import { FetchHttpClient } from "effect/unstable/http";

const OpenAiClientLayer = OpenAiClient.layerConfig({
  apiKey: Config.redacted("OPENAI_API_KEY"),
}).pipe(Layer.provide(FetchHttpClient.layer));

const AnthropicClientLayer = AnthropicClient.layerConfig({
  apiKey: Config.redacted("ANTHROPIC_API_KEY"),
}).pipe(Layer.provide(FetchHttpClient.layer));

const DraftPlan = ExecutionPlan.make(
  { provide: OpenAiLanguageModel.model("gpt-5.2"), attempts: 3 },
  { provide: AnthropicLanguageModel.model("claude-opus-4-6"), attempts: 2 },
);

export const makeDraftModelLayer = DraftPlan.captureRequirements.pipe(
  Effect.provide([OpenAiClientLayer, AnthropicClientLayer]),
);
```

Guidelines:

- Provide `FetchHttpClient.layer`, `NodeHttpClient`, or another transport at runtime composition, not inside reusable domain methods.
- Use `Config.redacted(...)` for API keys.
- Use `Model.ProviderName` and `Model.ModelName` inside behavior only for telemetry, audit metadata, or user-visible attribution.
- Use `ExecutionPlan` for provider fallback or model fallback instead of hand-coded nested retries.
