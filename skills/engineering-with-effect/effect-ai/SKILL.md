---
name: effect-ai
description: Design Effect AI capabilities with domain-owned behavior, provider routing, structured output, tool safety, streaming, retry/fallback policy, and deterministic substitutes. Use when model or tool semantics—not lint syntax—drive the design.
---

## Rules

- Reuse Effect AI's language model, toolkit, chat, and execution-plan boundaries rather than wrapping a provider SDK into a parallel framework.
- Put product AI behavior behind domain capabilities; provider requests, prompt assembly, and response parts are implementation details unless passthrough is the product.
- Keep provider/model selection, credentials, transports, and fallback plans at adapter or layer boundaries.
- Use schemas for structured output and tools; decide what invalid output means for the product.
- Treat tool approval, failure mode, idempotency, cost, and side effects as explicit policy.

## Constraints

- Shared AI modules are under `effect/ai`; provider implementations are separate packages. The AI surface is unstable.
- Never allow a model to authorize its own sensitive read, mutation, external side effect, or high-cost action.
- Retry and provider fallback require semantic equivalence and must not duplicate non-idempotent tool effects.
- Raw prompts, outputs, credentials, and tool payloads require explicit privacy and telemetry decisions.

## Knowledge Boundaries

Applies to:

- domain AI service design and provider routing
- structured generation, chat history, streaming parts, and toolkits
- AI error taxonomy, retry/fallback, approval, and deterministic tests

Does not cover:

- provider SDK syntax without product-level behavior
- generic Schema, Stream, HTTP, or Layer rules

Decision inputs:

- caller-facing behavior and acceptable model variance
- provider portability and fallback guarantees
- tool risk, replay safety, and approval authority
- persisted history and privacy requirements

## Patterns

- Separate three decisions: the domain service decides what behavior is needed, routing decides which configured model can perform it, and the provider adapter decides how to call it.
- Prefer `LanguageModel.generateObject` when downstream behavior depends on fields. Its provider-adapted codec decodes the response; normalize and apply domain checks to `response.value`.
- Stream domain-relevant deltas or events, not provider-specific response parts, unless the caller is a provider adapter.
- Define tools as protocols: schemas, handler dependencies, approval authority, failure disclosure, and replay policy. A generation call resolves tools for that response; the application owns subsequent model turns and their budget.
- Preserve `AiError.reason` for caller policy. `isRetryable` describes recoverability, not permission to replay an operation with tool effects.
- Test behavior with `LanguageModel.make` and substitute tool handlers; distinguish adapter protocol tests from domain tests and live-provider evaluations.

## Gotchas

- A `Model` is a layer with provider/model metadata, not a capability registry. Route by product requirements before selecting it; a shared interface does not prove equivalent provider behavior.
- Schema-valid output can still invent facts or violate cross-field invariants. Keep evidence and domain checks outside model decoding.
- Automatic tool resolution is not an agent loop. Feed results into a subsequent turn only under an explicit stopping and cost policy.
- `failureMode: "return"` can expose typed failures to the model; it is not a security filter. Sanitize recoverable failures and keep authorization outside the model.
- `disableToolCallResolution` is not a dry-run boundary: pending approved calls in the prompt are resolved first. Keep approval execution separate when previewing requests.
- Provider fallback or retry after tools have run can repeat side effects. Use durable idempotency and a replay-safe operation boundary, not just an AI retry flag.
- Streaming can run tools before terminal provider failure, and interrupted chat streams retain partial history. Decide what remains valid; interruption does not roll back external effects.
- Live-provider tests measure availability and model drift, not deterministic application behavior. Use controlled responses for approval, failure, and ordering assertions.

## References

- [`references/domain-model-and-routing.md`](./references/domain-model-and-routing.md): Read when: designing an AI service, model/provider routing, structured output, chat, or streaming.
- [`references/tools-errors-and-testing.md`](./references/tools-errors-and-testing.md): Read when: defining tool approval/failure semantics, AI error policy, fallback, or deterministic tests.
