# Tools, errors, and testing

## Tool protocol

Define parameter, success, expected failure, handler dependencies, approval rule, and failure mode. Require approval for mutation, external side effects, sensitive reads, irreversible actions, or material cost. Approval authority must be outside the model.

Return expected tool failure to the model only when the assistant can safely recover or explain it. Permission failures, invalid handler output, and defects generally terminate the model operation.

## Retry and fallback

Classify authentication, quota, policy, invalid input, invalid/structured output, transient network/provider, and tool failures. Retry only transient classes. Provider fallback requires equivalent behavior and awareness of already executed tools.

## Tests

Replace the model and toolkit handlers. Assert prompt inputs where they are a contract, structured output normalization, tool call/result ordering, approval, failure mapping, fallback selection, and stream completion. Use live-provider checks only as explicit smoke evaluations.
