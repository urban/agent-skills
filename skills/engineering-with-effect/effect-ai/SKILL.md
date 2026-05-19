---
name: effect-ai
description: Design and implement Effect AI integrations behind domain services with typed schemas, provider layers, toolkits, streaming output, error mapping, and deterministic tests. Use when adding or refactoring LLM/model behavior, AI tools, structured generation, chat history, model fallback, provider adapters, or tests around Effect AI modules.
---

## Native Effect Standards

- Encapsulate AI behavior behind domain services. Application code should call methods like `scoreAnswer`, `generateThreadTitle`, or `draftFeedback`, not scatter `LanguageModel.generateText` calls through handlers.
- Keep provider details at the edge. Use `OpenAiLanguageModel.model(...)`, `AnthropicLanguageModel.model(...)`, `Model.make(...)`, or an `ExecutionPlan` in Layers and adapters, not in domain logic.
- Use `Schema` at every AI boundary: structured output schemas, tool parameter schemas, tool success schemas, prompt input parsing, persisted chat history, and provider response decoding.
- Prefer `LanguageModel.generateObject` for structured data. Do not ask for JSON and parse it manually in application code.
- Prefer `Stream.Stream` for partial model output. Do not hand-roll web reader loops for model streaming.
- Treat tools as capabilities with typed schemas and handlers, not as arbitrary callbacks. Group them with `Toolkit.make` and provide handlers via `toLayer`.
- Map provider-agnostic `AiError.AiError` to a domain tagged error at the service boundary when callers should not depend on AI internals.
- Build tests by swapping the `LanguageModel.LanguageModel`, toolkit handler, provider client, or process boundary layer. Tests should not hit live model providers.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

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
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- the domain AI behavior and caller-facing service API
- provider/model selection requirements, tool policy, and schema contracts
- streaming, chat, or structured-output expectations
- test boundaries for fake models, tool handlers, provider clients, or HTTP clients

Effect-native code should tend toward:

- domain-shaped AI services and layers
- schemas for prompts, structured outputs, tools, and persisted history
- provider routing and fallback isolated at the edge
- tests that replace model/provider/tool boundaries instead of hitting live providers

Applies to:

- applying Effect AI patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for implementing non-trivial AI behavior or changing provider/tool wiring.
- Define the domain service API first; hide prompts, raw provider request shapes, response parts, and model-specific configuration unless the feature is explicitly a provider passthrough.
- Put provider clients, model selection, `ExecutionPlan`, transports, and credentials in layers or provider adapters.
- Model every AI boundary with `Schema`, prefer `LanguageModel.generateObject` for structured data, and use `Stream` for partial output.
- Model tools with `Tool.make`, `Toolkit.make`, typed success/failure schemas, handlers in layers, and explicit approval policy for risky tools.
- Map `AiError.AiError` to domain tagged errors at service boundaries while preserving semantic reasons and retryability.
- Test through the service API with fake language models, toolkit handlers, provider HTTP clients, process boundaries, and `TestClock` for delayed streams/tools.

## Gotchas

- If model calls are scattered through handlers, prompt text and provider details become the product API and later provider swaps become rewrites. Put behavior behind a domain service first.
- If structured data is requested as JSON and parsed manually, invalid output turns into ad hoc bugs and lost diagnostics. Use `LanguageModel.generateObject` or schema decoding at the boundary.
- If provider selection happens inside domain behavior, tests and fallback policy become tangled with prompts. Move selection into layers, registries, or `ExecutionPlan`.
- If tool callbacks lack schemas and approval policy, the model can invoke unsafe or malformed capabilities silently. Define tools as typed capabilities with `needsApproval` where risk exists.
- If all AI errors are collapsed to strings, callers cannot distinguish retryable rate limits from authentication, quota, or policy failures. Preserve `AiError.reason` in a domain error.
- If tests hit live providers for normal behavior, the suite becomes slow, flaky, and expensive. Swap the language model, toolkit, provider client, or transport layer.

## References

- [`references/patterns-01-effect-ai-patterns-for-agents.md`](./references/patterns-01-effect-ai-patterns-for-agents.md): Read when: you need source-pattern detail for Effect AI patterns for agents, First principles, Behavior encapsulation.
- [`references/patterns-02-make-tools-their-own-module-and-layer.md`](./references/patterns-02-make-tools-their-own-module-and-layer.md): Read when: you need source-pattern detail for Make tools their own module and Layer, Test with fake models and fake boundaries, Error handling patterns.
- [`references/patterns-03-what-to-avoid.md`](./references/patterns-03-what-to-avoid.md): Read when: you need source-pattern detail for What to avoid.
