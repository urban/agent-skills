# Effect AI patterns for agents

These notes capture project patterns for using Effect's AI modules. They are based on `repos/effect/packages/effect/src/unstable/ai`, provider packages under `repos/effect/packages/ai`, AI docs under `repos/effect/ai-docs/src/71_ai`, tests under `repos/effect/packages/**/test`, and adjacent AI/tooling patterns in `repos/t3code`, `repos/executor`, and `repos/alchemy-effect`.

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

The docs in `repos/effect/ai-docs/src/71_ai/10_language-model.ts` define `AiWriter` as a `Context.Service` with domain methods that hide provider selection, prompts, structured output decoding, streaming, and error mapping. Follow the same shape for project features.

Adapted pattern:

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
- Keep prompt construction pure when it is large or shared. `repos/t3code/apps/server/src/textGeneration/TextGenerationPrompts.ts` builds prompts and schemas in pure helpers, while provider modules execute them.
- Keep post-processing in the service. `repos/t3code/apps/server/src/textGeneration/CodexTextGeneration.ts` decodes structured output, then sanitizes commit subjects, PR titles, branch names, and thread titles before returning domain values.
- Use `Chat` only when conversation history is part of the behavior. For one-shot extraction or generation, use `LanguageModel.generateText` / `generateObject` directly.

### Separate provider routing from behavior

`repos/t3code/apps/server/src/textGeneration/TextGeneration.ts` routes requests to a provider instance registry. The caller supplies a `modelSelection`, the router finds the configured provider instance, and the provider-specific closure owns execution.

Adapted pattern:

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

Adapted from `repos/effect/ai-docs/src/71_ai/10_language-model.ts`:

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

### Make tools their own module and Layer

`repos/effect/ai-docs/src/71_ai/20_tools.ts` defines `Tool.make`, groups tools with `Toolkit.make`, and implements handlers through `Toolkit.toLayer`. This keeps tool schemas testable without the model and tool handlers swappable without prompt changes.

Adapted pattern:

```ts
import { Effect, Layer, Schema } from "effect";
import { Tool, Toolkit } from "effect/unstable/ai";

const CandidateId = Schema.String.pipe(Schema.brand("CandidateId")).annotate({
  description: "A stable candidate identifier.",
});

const FindCandidate = Tool.make("FindCandidate", {
  description: "Find the candidate profile for an assessment.",
  parameters: Schema.Struct({ candidateId: CandidateId }),
  success: Schema.Struct({ candidateId: CandidateId, displayName: Schema.String }),
});

const AssessmentToolkit = Toolkit.make(FindCandidate);

export const AssessmentToolkitLayer = AssessmentToolkit.toLayer(
  Effect.gen(function* () {
    const candidates = yield* CandidateDirectory;

    return AssessmentToolkit.of({
      FindCandidate: Effect.fn("AssessmentToolkit.FindCandidate")(function* ({ candidateId }) {
        return yield* candidates.find(candidateId);
      }),
    });
  }),
);
```

Guidelines:

- Put `description` on tools and important parameters. The model sees these descriptions.
- Prefer branded IDs and domain schemas for parameters and outputs.
- A toolkit handler may depend on other services; provide those through its Layer.
- Use `Tool.providerDefined` or provider packages such as `OpenAiTool.WebSearch` for provider-side tools. Do not add a local handler for tools that the provider executes server-side.
- Use `needsApproval` for tools that can mutate state, disclose sensitive data, or perform high-cost operations. A static boolean is best for always-dangerous tools; a predicate is appropriate when risk depends on decoded parameters.
- Use `disableToolCallResolution: true` only when another part of the system intentionally owns the tool execution loop.

### Test with fake models and fake boundaries

`repos/effect/packages/effect/test/unstable/ai/utils.ts` provides a test helper that replaces `LanguageModel.LanguageModel` with `LanguageModel.make`. Copy this pattern for project tests.

Adapted helper:

```ts
import { Effect, Predicate, Stream } from "effect";
import { dual } from "effect/Function";
import { LanguageModel, type Response } from "effect/unstable/ai";

export const withTestLanguageModel = dual(
  2,
  <A, E, R>(
    effect: Effect.Effect<A, E, R>,
    options: {
      readonly generateText?: ReadonlyArray<Response.PartEncoded>;
      readonly streamText?: ReadonlyArray<Response.StreamPartEncoded>;
    },
  ): Effect.Effect<A, E, Exclude<R, LanguageModel.LanguageModel>> =>
    Effect.provideServiceEffect(
      effect,
      LanguageModel.LanguageModel,
      LanguageModel.make({
        generateText: () => Effect.succeed(options.generateText ?? []),
        streamText: () =>
          Predicate.isUndefined(options.streamText)
            ? Stream.empty
            : Stream.fromIterable(options.streamText),
      }),
    ),
);
```

Guidelines:

- Test domain behavior through the service API.
- Assert structured outputs, sanitization, tool calls/results, and error mapping.
- Use fake provider responses, fake process binaries, or fake HTTP clients. `repos/t3code/apps/server/src/textGeneration/CodexTextGeneration.test.ts` uses a fake Codex binary; provider tests in `repos/effect/packages/ai/openai/test` use a mock HTTP client.
- For streaming and delayed tools, use `TestClock.adjust(...)` and latches rather than wall-clock sleeps. `LanguageModel.test.ts` verifies that streaming emits tool calls before delayed tool results and defers finish parts until tool results are emitted.

## Error handling patterns

### Understand `AiError`

The AI modules expose provider-agnostic `AiError.AiError`. Its `reason` is a typed semantic reason such as:

- retryable: `RateLimitError`, `InternalProviderError`, some `NetworkError`, `InvalidOutputError`, `StructuredOutputError`, `ToolNotFoundError`, `ToolParameterValidationError`
- non-retryable: `QuotaExhaustedError`, `AuthenticationError`, `ContentPolicyError`, `InvalidRequestError`, `UnsupportedSchemaError`, `InvalidToolResultError`, `ToolResultEncodingError`, `ToolConfigurationError`, `ToolkitRequiredError`, `InvalidUserInputError`, `UnknownError`

Each reason has `isRetryable`, and some reasons carry `retryAfter` or HTTP/provider metadata. Provider packages map HTTP transport failures and status codes into these reasons in files such as `repos/effect/packages/ai/openai/src/internal/errors.ts` and `repos/effect/packages/ai/anthropic/src/internal/errors.ts`.

### Map AI errors at service boundaries

Adapted from `AiWriterError.fromAiError` in the docs:

```ts
export class VoiceAiError extends Schema.TaggedErrorClass<VoiceAiError>()("VoiceAiError", {
  reason: AiError.AiErrorReason,
}) {
  static fromAiError(error: AiError.AiError): VoiceAiError {
    return new VoiceAiError({ reason: error.reason });
  }
}

const generateSummary = Effect.fn("VoiceAi.generateSummary")(
  function* (transcript: string) {
    const response = yield* LanguageModel.generateText({
      prompt: `Summarize this transcript:\n${transcript}`,
      toolChoice: "none",
    });
    return response.text;
  },
  Effect.catchTag("AiError", (error) => Effect.fail(VoiceAiError.fromAiError(error))),
);
```

Guidelines:

- Preserve the reason. Do not collapse everything to a generic `InternalError` or string.
- Handle actionable reasons close to the caller that can act on them. For example, authentication setup can handle `AuthenticationError`; a retry policy can handle `RateLimitError`; a moderation UX can handle `ContentPolicyError`.
- Let non-actionable defects remain defects, but do not use `Effect.orDie` to erase expected AI failures.

### Retry only retryable reasons

```ts
import { Duration, Effect, Schedule } from "effect";
import { AiError } from "effect/unstable/ai";

const retryTransientAi = <A, R>(effect: Effect.Effect<A, AiError.AiError, R>) =>
  effect.pipe(
    Effect.retry({
      while: (error) => error.isRetryable,
      schedule: Schedule.exponential(Duration.millis(200)).pipe(
        Schedule.intersect(Schedule.recurs(3)),
      ),
    }),
  );
```

Guidelines:

- Do not retry `AuthenticationError`, `QuotaExhaustedError`, `ContentPolicyError`, `UnsupportedSchemaError`, or invalid user input.
- Prefer provider fallback with `ExecutionPlan` when an equivalent model/provider can satisfy the behavior.
- Surface user-fixable failures as domain errors with enough detail for the UI or operator.

### Choose tool `failureMode` deliberately

`Tool.make` defaults `failureMode` to `"error"`. With `"error"`, a handler failure fails the model call. With `"return"`, a handler failure is encoded as a tool result with `isFailure: true` so the model can recover or explain the problem. `repos/effect/packages/effect/test/unstable/ai/Tool.test.ts` covers both modes.

Use `"error"` for invariant violations, permission failures that must stop the operation, invalid handler outputs, and unexpected infrastructure failures. Use `"return"` for domain-level misses the assistant can handle, such as "candidate not found" or "inventory unavailable".

Adapted pattern:

```ts
const LookupRubric = Tool.make("LookupRubric", {
  description: "Find the scoring rubric for an assessment question.",
  parameters: Schema.Struct({ rubricId: Schema.String }),
  success: Schema.Struct({ rubric: Schema.String }),
  failure: Schema.Struct({ reason: Schema.Literals(["NotFound", "Unavailable"]) }),
  failureMode: "return",
});
```

## Prompt and response patterns

- Use `Prompt.make`, `Prompt.setSystem`, `Prompt.concat`, and typed message/part constructors for rich prompts.
- Attach provider options through the `options` fields on prompt messages or parts when needed. Provider modules extend those option types, for example OpenAI image detail and Anthropic cache-control metadata.
- Inspect response convenience fields instead of parsing content manually: `response.text`, `response.toolCalls`, `response.toolResults`, `response.finishReason`, and `response.usage`.
- For streaming text, filter `Response.TextDeltaPart` and map `delta`.
- For chat, persist or export history through `Chat.export`, `Chat.exportJson`, and `Chat.fromJson` rather than inventing a parallel transcript format.
- For agentic loops, let `Chat` maintain tool calls and tool results in history. The docs in `repos/effect/ai-docs/src/71_ai/30_chat.ts` loop until a generated response has no tool calls.

## Adjacent repository patterns to carry forward

- `repos/t3code`: AI text generation is provider-routed and domain-shaped. Prompt builders are pure, providers decode with `Schema.fromJsonString(...)`, outputs are sanitized, and tests use fake CLIs instead of real model calls.
- `repos/executor`: tool behavior is schema-first and policy-gated. Static tools carry input/output schemas and approval annotations; policies combine user-authored rules and plugin defaults so invoke-time behavior is explicit.
- `repos/alchemy-effect`: runtime AI Gateway access is wrapped in an Effect-native client with a typed tagged error. Bindings are resolved lazily from the runtime environment, while deploy-time policy is a separate Layer.

## What to avoid

- Do not call provider SDKs or `fetch` directly from domain services. Use provider Layers and `HttpClient`-backed clients.
- Do not parse model JSON with `JSON.parse` in application code. Use `LanguageModel.generateObject` or `Schema.fromJsonString(...)` at a boundary.
- Do not expose raw provider request/response shapes from product services unless the product feature is explicitly a provider passthrough.
- Do not hard-code provider/model selection deep inside behavior. Keep it in config, registry, model Layer, or `ExecutionPlan`.
- Do not swallow `AiError.reason` or replace it with a generic error string.
- Do not retry all AI failures. Use `isRetryable` and reason-specific handling.
- Do not use tools without schemas. Tool parameters, successes, and expected failures should be modeled explicitly.
- Do not let unsafe tools execute silently. Use `needsApproval` and policy checks for mutation, external side effects, sensitive reads, and high-cost actions.
- Do not use `failureMode: "return"` for defects or invariant violations that should stop the request.
- Do not write live-provider tests for normal behavior. Swap the model, toolkit, HTTP client, process spawner, or gateway binding layer.
