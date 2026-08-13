---
name: effect-ai
description: Design Effect AI capabilities with domain-owned behavior, provider routing, structured output, tool safety, streaming, retry/fallback policy, and deterministic substitutes. Use when model or tool semantics—not lint syntax—drive the design.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Put product AI behavior behind domain capabilities; provider requests, prompt assembly, and response parts are implementation details unless passthrough is the product.
- Keep provider/model selection, credentials, transports, and fallback plans at adapter or layer boundaries.
- Use schemas for structured output and tools; decide what invalid output means for the product.
- Treat tool approval, failure mode, idempotency, cost, and side effects as explicit policy.

## Constraints

- Effect AI is currently exposed through an unstable v4 module surface; verify imports and API details against the installed release.
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
- Prefer structured generation when downstream behavior depends on fields. Validate, normalize, and apply domain checks after model decoding.
- Stream domain-relevant deltas or events, not provider-specific response parts, unless the caller is a provider adapter.
- Define tools as protocols: parameter schema, success schema, expected failure schema, handler layer, approval rule, and failure mode.
- Preserve semantic AI failure reasons when callers distinguish authentication, quota, policy, invalid input/output, transient provider failure, or tool failure.
- Test prompts and behavior through fake language models and tool handlers; assert normalized outputs, tool calls/results, approval, error mapping, and stream order.

## Gotchas

- Scattered model calls turn prompt text and provider response shape into accidental product API.
- Schema-valid output can still violate product invariants; validate semantic constraints after generation.
- Provider fallback after tools have run can repeat side effects; fallback boundaries must account for completed tool calls.
- Returning a tool failure to the model is recovery policy, not generic error handling; defects and permission failures usually must stop the operation.
- Collapsing AI failures to one string prevents correct retry, setup, moderation, and quota UX.
- Live-provider tests measure availability and model drift, not deterministic application behavior.

## References

- [`references/domain-model-and-routing.md`](./references/domain-model-and-routing.md): Read when: designing an AI service, model/provider routing, structured output, chat, or streaming.
- [`references/tools-errors-and-testing.md`](./references/tools-errors-and-testing.md): Read when: defining tool approval/failure semantics, AI error policy, fallback, or deterministic tests.
