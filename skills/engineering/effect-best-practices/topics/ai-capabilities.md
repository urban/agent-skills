# AI capabilities

Put product behavior behind a domain capability. Provider requests, prompts, and response parts remain implementation details unless exposing them is the product. Define which variability is acceptable, what evidence generated claims require, and how invalid or unavailable output changes the caller's behavior.

Separate domain intent from model routing and provider adaptation. A common Effect interface does not establish equivalent behavior across models. Choose fallback only when capability, privacy, cost, output meaning, and tool policy remain acceptable for the same operation.

Define tool authority outside the model. An application policy decides whether a requested read or mutation is permitted and which approval is valid; model output cannot grant itself permission. Model-visible failures should support safe correction without disclosing private operator diagnostics.

Choose a stopping and budget policy for subsequent turns. Before retry or fallback, account for tools already executed and whether partial output or history remains valid. Preserve logical operation identity across repeated attempts with external effects; restarting generation must not silently repeat a business action.

**Tradeoff:** schema acceptance establishes representation, not factual truth or authorization. Controlled responses can establish application policy and ordering; live evaluations address model quality and drift. Keep those claims separate and use Effect's AI documentation for tool-resolution and provider mechanics.
