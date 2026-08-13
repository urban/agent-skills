# Failures and regressions

Assert expected errors through the public error/result/exit contract. Check tag/reason and fields that callers use. Inspect Cause when the distinction between expected failure, defect, and interruption is the behavior.

A regression test should:

1. name the caller-visible failure;
2. reproduce it through the nearest public composition;
3. replace only external/nondeterministic edges;
4. assert the stable outcome that was broken;
5. avoid pinning incidental internal sequencing.

Exact invocation assertions are appropriate for protocol contracts: HTTP method/path/body, CLI arguments, serialized payload, idempotency keys, approval prompts, or required cleanup calls.
