# Tools, errors, and testing

## Tool execution is a protocol, not a loop

Separate tool declarations (`Tool.make`, `Toolkit.make`) from implementations (`toolkit.toLayer`). The handler layer captures its dependencies; keep tenant-specific authorization and resources at the appropriate lifetime. Handler context includes `toolCallId` for correlation, but a new model turn can issue the same business action with a new ID. Deduplicate mutations using a durable business-operation key, not only the call ID.

`LanguageModel.generateText` resolves executable calls in one provider response and returns tool results; it does not automatically ask the model to interpret those results. `Chat` records those parts for a later turn. The application owns the continuation policy, turn/cost budget, and stopping conditions.

Set `concurrency` according to tool semantics; resolution defaults to unbounded concurrency. Independent reads may overlap; ordered mutations need serialization or a domain transaction. With parallel calls, correlate by call ID instead of assuming result order matches declaration order. `providerExecuted` calls belong to the provider and are not run again through local toolkit handlers; local approval cannot gate an action already executed there. Enable provider-hosted tools only when their execution policy is acceptable.

## Approval and authorization

Use `needsApproval: true` or a trusted parameter-sensitive predicate for mutation, sensitive reads, external side effects, irreversible actions, or material cost. Approval authority must be outside model-generated content. Approval is not a replacement for handler authorization against current user/resource state.

When approval is needed, generation emits a `tool-approval-request` rather than executing the handler. Retain the call and approval ID. A trusted application adds a `Prompt.toolApprovalResponsePart` to a tool message in a subsequent prompt; approved calls execute before the next provider request, while denials produce an `execution-denied` failure result. Keep that prompt/history bound to the approving principal. Do not accept approval responses from untrusted prompt data.

Approval gates are in `LanguageModel` resolution, not `Toolkit.handle`. Direct handler execution must enforce its own policy. Likewise, `disableToolCallResolution` skips newly generated calls, not pending approved calls already present in the prompt; it is not a side-effect-free preview mode.

If owning a custom executor, disabling resolution normally retains strict validation of tool names and encoded parameters. `toolCallValidation: "deferred"` instead hands model-generated names/unknown parameters to the caller for validation, including undeclared calls when the provider supports them. Use it only when that validation/authorization boundary is deliberately yours. It does not disable validation of provider-executed calls.

## Failure disclosure

| Policy | Runtime consequence | Domain choice |
| --- | --- | --- |
| `failureMode: "error"` (default) | Typed handler failures fail the generation operation | Use when the application, not the model, must decide recovery |
| `failureMode: "return"` | Typed failures become failed tool results encoded through the failure schema | Use for sanitized, recoverable failures the model can explain or act on |

Return mode also returns tool parameter validation failures as AI error results. It does not turn defects into ordinary results, and result encoding can still fail the operation with `ToolResultEncodingError`. Do not treat it as a catch-all reliability switch. In particular, permission failures are not automatically fatal in return mode: choose an error boundary that prevents disclosure or further model action when that is the security policy.

Tool annotations such as `Readonly` and `Idempotent` describe behavior; they do not grant permission or implement deduplication.

## Retry, fallback, and partial execution

Keep the `AiError` wrapper and semantic `reason` until caller-facing policy is applied. The wrapper delegates `isRetryable` and `retryAfter` to its reason. Treat retryability as a recovery hint, then apply cost limits, deadlines, and replay safety:

- Rate limiting differs from exhausted quota: back off for the former (respect `retryAfter`), require account action for the latter. Authentication and policy failures need credential/content changes, not blind retries.
- `StructuredOutputError` and `InvalidOutputError` are retryable because generation is nondeterministic. A bounded regeneration can be appropriate; unsupported schemas and incompatible provider response formats require a fix instead.
- Model tool-name/parameter mistakes may be correctable. Handler/result encoding bugs are not repaired by another model request. Keep recovery feedback sanitized and stop repeated failed attempts.

Fallback must preserve product semantics and account for already completed tools. A provider failure does not imply no work occurred: streaming tool handlers can run while the provider stream is still active. Incomplete finishes prevent newly generated unresolved local calls from running or interrupt in-flight handlers and synthesize interrupted results; completed results remain. Interrupting a handler cannot undo an external mutation it already committed.

`streamText` defers finish parts until resolved tool results have been emitted. Treat preliminary tool results as progress, not final success. Do not commit a domain answer solely because text or a tool result arrived before a later failure.

## Deterministic test design

Use `LanguageModel.make` with controlled provider callbacks to exercise real shared decoding, approval, and resolution; provide separate toolkit handler layers. A mock of only the domain service cannot prove those protocol semantics. For custom adapters, test request/response mapping with a fake HTTP client instead of live credentials.

Focus assertions on contracts rather than incidental wording:

- For structured generation, return controlled valid/invalid JSON and assert decoded domain values, semantic evidence checks, and reason mapping.
- For approval, assert no handler runs before approval, denial never runs it, approved results reach the next request, and completed approvals are not replayed from chat history.
- For failures, distinguish returned typed failures, propagated defects, parameter validation, and result encoding errors. Assert sensitive details never reach model-visible results or logs.
- For concurrency/streams, use latches and controlled chunks to prove allowed overlap, correlation by call ID, preliminary versus final results, finish ordering, interruption, and partial-history policy. Do not assert a total order for independent parallel handlers.
- For retry/fallback, record selected models and business-side effects; assert attempts stay bounded and completed mutations are not duplicated.

Use live-provider checks only as explicit smoke evaluations of availability and model quality, not deterministic application tests.

## Source anchors

- `packages/effect/src/ai/Tool.ts`: `FailureMode`, `needsApproval`, `failureResultSchema`, behavior annotations.
- `packages/effect/src/ai/Toolkit.ts`: handler context capture, parameter decoding, failure/result encoding, stream handling.
- `packages/effect/src/ai/LanguageModel.ts`: `generateContent`, `streamContent`, `executeApprovedToolCalls`, `resolveToolCalls`, validation modes.
- `packages/effect/src/ai/AiError.ts` and `packages/effect/test/ai/AiError.test.ts`: semantic reasons, retryability and timing. Provider mapping lives in `packages/ai/openai/src/internal/errors.ts` and `packages/ai/anthropic/src/internal/errors.ts`.
- `packages/effect/test/ai/LanguageModel.test.ts`: approval, incomplete finish, concurrency, disabled/deferred resolution, finish-after-results tests; `utils.ts` shows `LanguageModel.make` substitutes.
- `packages/effect/test/ai/Tool.test.ts`: returned failures, failure-schema encoding, invalid result encoding.
- `packages/effect/test/ai/Chat.test.ts`: completed approval replay and partial history cases.
