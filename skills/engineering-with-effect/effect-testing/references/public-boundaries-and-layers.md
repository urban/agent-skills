# Public boundaries and layers

Choose the closest stable caller surface:

- pure domain function for a pure invariant
- service method for application capability
- typed client or handler for protocol behavior
- Stream for incremental behavior
- process/CLI service for command integration
- workflow/entity public client for durable/runtime semantics

Preserve production composition behind that surface. Replace network, process, storage, time, randomness, model provider, or another true external boundary. Replacing the application service whose orchestration is under test bypasses the behavior the test needs to exercise.

## Replacement fidelity

Select the seam by what must remain real, not by how many dependencies can be mocked:

| Claim | Keep in the composition | What a cheaper fake can miss |
| --- | --- | --- |
| Retry after a transient storage failure | Application retry policy and storage error translation | Failure classification, uniqueness, transaction boundaries |
| Handler accepts and returns the public schema | Generated client, routing, codecs, middleware, handlers | Encoding and response decoding when calling the handler directly |
| Cancellation releases an in-flight resource | Acquisition, cancellation propagation, release | A precomputed successful response has no lifetime to cancel |
| Socket disconnect or transport framing works | Actual runtime adapter and transport | In-memory clients do not prove socket behavior |

Current in-process harnesses have different fidelity: `HttpApiTest` preserves request encoding, routing, response encoding, and client decoding without a server; `RpcTest` uses the no-serialization client/server path. An in-memory RPC test therefore does not establish a schema round trip. Neither harness establishes network behavior. Choose higher fidelity for the omitted semantics rather than adding unrelated live infrastructure to every test.

For a stateful fake, model the relevant failure rules as well as happy-path values: duplicate keys, ordering, atomicity, and cancellation may determine whether production can produce the asserted result. Use contract cases against both fake and real adapter when those semantics are relied on. Expose a harness service for controlled observations such as captured requests or persisted rows rather than reaching into private refs.

## Layer ownership and isolation

Allocate mutable state during layer acquisition, not in module-level variables or a prebuilt mutable object passed to `Layer.succeed`. Rebuilding a layer cannot isolate an object it reuses from outside acquisition.

`it.layer` / `layer` share a built layer across a block by default. Use `{ buildPerTest: true }` for fresh services released after each test. Enclosing shared layers remain shared; nesting a per-test child does not rebuild its shared parent. Blocks inside a per-test block are also built per test.

Default layer blocks also share their test services, including clock progress. Per-test construction gives fresh test services unless an enclosing shared block owns them. Separate blocks are isolated by default, but a deliberately reused memo map can change sharing.

Share only when setup cost or the intended scenario justifies it. If shared state needs serialized access, set `{ concurrent: false }` on the named layer suite; anonymous layer blocks inherit enclosing concurrency. Serialization prevents overlap, not leakage between tests. Prefer independent scenario state over a chain of tests that must run in a particular order.

Source anchors (Effect v4): `packages/vitest/src/internal/internal.ts` (`makeLayer`), `packages/vitest/test/build-per-test.test.ts`, `packages/vitest/test/isolation.test.ts`, `packages/vitest/test/nested-isolation.test.ts`, `packages/vitest/test/layer-concurrency.test.ts`, `packages/effect/src/http-api/HttpApiTest.ts`, `packages/effect/src/rpc/RpcTest.ts`.
