# Test levels and evidence

## Choose from the confidence question

Choose the closest public production boundary that can expose a consequential error in the claim. Usually this is a service or application capability with real internal composition and supplied external dependencies. Black-box describes the observation, not the number of processes or the size of the environment.

Use the existing narrow executable check before building another harness. Choose additional evidence for distinct gaps, not as a mandatory testing pyramid:

| Claim | Sufficient evidence to consider |
| --- | --- |
| Application policy, validation, or typed failure handling | Production capability with real internal collaborators and controlled external responses |
| Adapter request encoding, response decoding, or error mapping | Production adapter with independent protocol request/reply fixtures or a focused local protocol harness |
| Persistence constraints, transactions, native-process lifecycle, restart, or shutdown | Focused integration with the relevant real local runtime/resource owner |
| Model factuality, template fidelity, or provider quality/drift | Separately invoked, bounded live evaluation against stated criteria |
| Routing, serialization, middleware, or UI interaction | The public entrypoint and composition that own that behavior |
| A critical deployed journey or deployment interaction | Selected end-to-end evidence |
| A distinct pure invariant or domain law | Focused examples or a non-vacuous property with independent expectations |

These are alternatives selected by risk; a change does not owe evidence at every row. A service fixture cannot establish adapter compatibility, a map cannot establish database constraints, and a model-shaped fixture cannot establish model truth. Keep the actual owner real when its behavior is the claim.

Protocol fixtures should encode the external specification or a known raw exchange independently of the production serializer. Shared contract checks are useful when multiple implementations must preserve the same semantics, but are not a mandatory harness for every interface.

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

Keep live external checks separately named and explicitly invoked; routine test, check, and build commands should remain deterministic and should not download models or corpus inputs. Live checks provide evidence about credentials, deployment, provider compatibility, and model quality. Name the question, cases, evaluation criteria, and run/time limit before running them. A smoke test establishes connectivity or compatibility, not broad output quality.

Unknown provider feasibility warrants an early bounded probe of the disputed real mechanism. Do not defer that uncertainty behind fixtures until final verification. Exhausting an evaluation limit leaves an explicit evidence gap; it does not make acceptance pass or justify silently expanding the experiment.

When a regression is found, first see whether an existing black-box scenario can be strengthened to detect it. Add a focused reproducer only when it captures a distinct risk or makes feedback materially more reliable/economical. Name the broken behavior and assert the stable outcome; avoid freezing incidental implementation that happened to be present in the fix.
