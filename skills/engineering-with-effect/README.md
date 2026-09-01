# Engineering with Effect

Effect-specific knowledge skills for writing Effect-native code with current standards and best practices.

These skills are intended to be used with the [`dotai` CLI](https://github.com/urban/dotai).

## Primary routing

Choose one primary skill by the decision that owns the task. Add another only when the task contains a separate, substantive decision in its scope.

| Primary decision | Skill |
| --- | --- |
| Core computation, failure/defect, Cause, interruption, or ambiguous routing | `effect-core` |
| Runtime topology spanning multiple capabilities or ownership domains | `effect-application-architecture` |
| One coherent capability contract and its public failures | `effect-service` |
| Construction, dependency visibility, sharing, freshness, or scoped lifetime | `effect-layer` |
| Cross-cutting test seam, deterministic coordination, or cleanup evidence | `effect-testing` |
| Protocol or package-specific behavior | The matching specialist below |

## Sibling skills

- [effect-ai](./effect-ai/SKILL.md) — Effect AI integrations, provider layers, typed tools, structured generation, streaming output, and tests.
- [effect-application-architecture](./effect-application-architecture/SKILL.md) — Whole-application Effect topology across ordinary values, services, Layer graphs, composition roots, scopes, and public exports.
- [effect-atom](./effect-atom/SKILL.md) — Effect Atom state modules, async lifecycles, service-backed data access, React hooks, optimistic updates, and tests.
- [effect-client-wrapper](./effect-client-wrapper/SKILL.md) — Effect service wrappers around Promise-based third-party SDK clients.
- [effect-cluster](./effect-cluster/SKILL.md) — Effect Cluster entities, typed RPC protocols, runners, persistence, proxies, actor-style state, and tests.
- [effect-core](./effect-core/SKILL.md) — Core computation and runtime semantics plus routing when no narrower specialist clearly owns the decision.
- [effect-fast-check](./effect-fast-check/SKILL.md) — Property-based testing for Effect code with @effect/vitest, schema-derived arbitraries, and deterministic boundaries.
- [effect-http](./effect-http/SKILL.md) — Effect HTTP APIs, typed clients, schema bodies, outbound services, transport layers, status mapping, and in-process tests.
- [effect-layer](./effect-layer/SKILL.md) — Effect Layer composition, dependency wiring, scoped resources, sharing semantics, typed construction errors, and test layers.
- [effect-opentelemetry](./effect-opentelemetry/SKILL.md) — Effect-native tracing, metrics, logs, OTLP/OpenTelemetry layers, low-cardinality attributes, and telemetry tests.
- [effect-optic](./effect-optic/SKILL.md) — Pure immutable reads and updates over nested data, optional focuses, variants, traversals, and schema-backed types.
- [effect-platform](./effect-platform/SKILL.md) — Filesystem, path, crypto, process, stdio, terminal, socket, HTTP runtime, scoped resource, and platform-boundary patterns.
- [effect-schema](./effect-schema/SKILL.md) — Effect Schema contracts for runtime validation, codecs, tagged errors, transformations, HTTP APIs, and schema tests.
- [effect-service](./effect-service/SKILL.md) — Context.Service boundaries, small domain contracts, dependency capture, typed errors, layers, scoped resources, and test doubles.
- [effect-stream](./effect-stream/SKILL.md) — Lazy back-pressured streams, service-owned sources, adapters, schema decoding, protocol boundaries, cleanup, and tests.
- [effect-testing](./effect-testing/SKILL.md) — Effect testing with @effect/vitest, public boundaries, layer replacement, deterministic clocks/fibers/queues, and typed errors.
- [effect-workflow](./effect-workflow/SKILL.md) — Durable Effect workflows, schema-defined payloads, idempotency keys, activities, durable queues, proxies, compensation, and tests.
