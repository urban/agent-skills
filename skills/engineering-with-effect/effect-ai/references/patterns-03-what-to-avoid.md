# Effect AI patterns for agents — part 3

Covers:

- What to avoid

---

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
