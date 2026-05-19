# Effect AI patterns for agents — part 2

Covers:

- Make tools their own module and Layer
- Test with fake models and fake boundaries
- Error handling patterns
- Understand AiError
- Map AI errors at service boundaries
- Retry only retryable reasons
- Choose tool failureMode deliberately
- Prompt and response patterns

---

### Make tools their own module and Layer

`.dotai/repos/effect/ai-docs/src/71_ai/20_tools.ts` defines `Tool.make`, groups tools with `Toolkit.make`, and implements handlers through `Toolkit.toLayer`. This keeps tool schemas testable without the model and tool handlers swappable without prompt changes.

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

`.dotai/repos/effect/packages/effect/test/unstable/ai/utils.ts` provides a test helper that replaces `LanguageModel.LanguageModel` with `LanguageModel.make`. Copy this pattern for project tests.

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
- Use fake provider responses, fake process binaries, or fake HTTP clients. Provider tests in `.dotai/repos/effect/packages/ai/openai/test` use a mock HTTP client.
- For streaming and delayed tools, use `TestClock.adjust(...)` and latches rather than wall-clock sleeps. `LanguageModel.test.ts` verifies that streaming emits tool calls before delayed tool results and defers finish parts until tool results are emitted.

## Error handling patterns

### Understand `AiError`

The AI modules expose provider-agnostic `AiError.AiError`. Its `reason` is a typed semantic reason such as:

- retryable: `RateLimitError`, `InternalProviderError`, some `NetworkError`, `InvalidOutputError`, `StructuredOutputError`, `ToolNotFoundError`, `ToolParameterValidationError`
- non-retryable: `QuotaExhaustedError`, `AuthenticationError`, `ContentPolicyError`, `InvalidRequestError`, `UnsupportedSchemaError`, `InvalidToolResultError`, `ToolResultEncodingError`, `ToolConfigurationError`, `ToolkitRequiredError`, `InvalidUserInputError`, `UnknownError`

Each reason has `isRetryable`, and some reasons carry `retryAfter` or HTTP/provider metadata. Provider packages map HTTP transport failures and status codes into these reasons in files such as `.dotai/repos/effect/packages/ai/openai/src/internal/errors.ts` and `.dotai/repos/effect/packages/ai/anthropic/src/internal/errors.ts`.

### Map AI errors at service boundaries

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

`Tool.make` defaults `failureMode` to `"error"`. With `"error"`, a handler failure fails the model call. With `"return"`, a handler failure is encoded as a tool result with `isFailure: true` so the model can recover or explain the problem. `.dotai/repos/effect/packages/effect/test/unstable/ai/Tool.test.ts` covers both modes.

Use `"error"` for invariant violations, permission failures that must stop the operation, invalid handler outputs, and unexpected infrastructure failures. Use `"return"` for domain-level misses the assistant can handle, such as "candidate not found" or "inventory unavailable".

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
- For agentic loops, let `Chat` maintain tool calls and tool results in history. The docs in `.dotai/repos/effect/ai-docs/src/71_ai/30_chat.ts` loop until a generated response has no tool calls.
