# Test levels and evidence

## Choose from the confidence question

Start with a compact set of high-value black-box scenarios covering meaningful user/operational flows and consequential failures. Exercise real production composition through a public UI, CLI, API, or application interface; full deployment is needed only when deployment interactions are part of the confidence question.

Black-box describes what the test observes, not how many processes it starts. An in-process application harness with real internal collaborators can provide broad behavioral confidence with fast, deterministic feedback.

Add integration/contract checks or focused unit/property tests only for important gaps that these scenarios cannot cover reliably or economically. A pure function is not automatically entitled to its own test file. Test count, assertion count, and coverage percentage are not goals.

| Confidence needed | Useful boundary |
| --- | --- |
| Critical flow works across deployed components | End-to-end |
| Modules compose and real infrastructure semantics matter | In-process or local integration |
| One adapter honors a remote or persistence protocol | Contract or adapter integration |
| Important invariant has unrepresented cases that broad scenarios cannot cover economically | Focused example or property supplement |
| One deep module's stable contract has a distinct confidence gap | Public-interface unit supplement |

Preserve routing, serialization, middleware, runtime lifecycle, database constraints, transaction isolation, or concurrency when those semantics are the behavior. Use a focused boundary for a pure value rule only when doing so adds meaningful missing confidence or improves feedback cost without losing needed composition evidence.

## Confidence per test

- Map proposed scenarios to acceptance criteria and consequential risks. One coherent scenario can cover several criteria; no one-to-one mapping is required.
- Extend or strengthen an existing scenario before adding a redundant test. Keep failure messages specific enough to identify the broken contract.
- Do not repeat the same behavioral proof at every layer. Keep overlap only when it catches a distinct failure, such as real database constraints or deployed routing.
- Keep scenarios independent and deterministic. A single giant journey with unrelated assertions is not a substitute for a small reliable suite.
- When reducing a suite, preserve distinct risks and assertion sensitivity. Fewer tests that miss important failures are not an improvement.
- Prefer controlled setup and visible outcomes over sleeps, elaborate harnesses, or diagnostic assertions that merely freeze implementation details.

## Observable evidence

Prefer evidence a caller or operator could observe:

- returned value or typed failure
- persisted row or domain state loaded through a public query
- emitted event, message, or job
- rendered HTTP/CLI/UI response
- captured outbound protocol request at a boundary harness
- acquired and released resource

An exact interaction is observable when the interaction is the product or protocol contract. For example, an adapter contract may require one particular HTTP method, path, serialized body, idempotency key, or cleanup call. Internal helper call count is not equivalent.

## Suite roles

Keep live external checks separately named and scheduled as smoke or compatibility tests. They provide evidence about credentials, deployment, provider behavior, and network integration but should not make the normal suite nondeterministic.

When a regression is found, first see whether an existing black-box scenario can be strengthened to detect it. Add a focused reproducer only when it captures a distinct risk or makes feedback materially more reliable/economical. Name the broken behavior and assert the stable outcome; avoid freezing incidental implementation that happened to be present in the fix.
