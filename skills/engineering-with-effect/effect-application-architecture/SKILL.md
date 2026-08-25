---
name: effect-application-architecture
description: Translate whole-application architecture into Effect topology across ordinary values, Context services, Layer provider and output graphs, composition roots, provision scopes, hidden requirements, and transaction-scoped values. Use when deciding the Effect runtime shape of an application across multiple capabilities rather than one service or Layer.
---

## Rules

- Start from domain and application capabilities, then translate only runtime-bearing capabilities into services and Layer providers.
- Keep schemas, canonical values, pure policy, immutable intents, and operation-local or transaction-scoped values ordinary unless they have an independent runtime identity.
- Use public facades to hide private feature topology when that reduces caller burden; expose multiple capabilities when callers genuinely need independently useful surfaces.
- Give each executable or independently started runtime an explicit composition root that assembles its complete graph and owns its application scope.
- Resolve configuration at the composition edge, capture implementation dependencies during construction, and hide private services from downstream outputs.
- Assign transaction, client, process, subscription, and background-fiber lifetime to one clear scope owner; keep transaction-scoped values within the lifetime where their observations remain valid.
- Provide the complete Effect graph around an entrypoint program once, and make public exports reveal supported capabilities rather than infrastructure topology.

## Constraints

- Do not require one facade, one public service, or one composition root for an entire repository; choose surfaces by caller cohesion and roots by independently started runtime.
- Do not turn every feature, operation, callback, transaction view, or configuration record into a `Context.Service`.
- Public operations must not choose production adapters, read hidden ambient configuration, or provide their own live Layer graph.
- Do not export private feature services, concrete adapters, provider clients, transaction handles, resource constructors, or internal configuration merely because they exist in the composed graph.
- Do not hold a database transaction across remote calls, durable waits, human interaction, or other long-running work.
- Leave service mechanics, Layer operators, schema codecs, platform APIs, test techniques, telemetry semantics, and durable workflow protocols to their focused specialists.

## Knowledge Boundaries

Applies to:

- translating domain and application modules into ordinary values, services, and Layer providers
- deciding public facade versus private Effect capability topology
- arranging the application-wide Layer graph, provision scope, and explicit composition roots
- hiding construction requirements and assigning resource or transaction-scoped values to the correct Effect lifetime
- providing entrypoint programs and designing intentional Effect-facing exports

Does not cover:

- detailed `Context.Service` contract and error design
- mechanical Layer composition, memoization, freshness, or manual build APIs
- schema representation, platform protocol, test, telemetry, or workflow mechanics
- framework-neutral module, entrypoint, authorization, transaction-versus-workflow, or project governance policy

Decision inputs:

- domain invariants, application use cases, and capabilities callers actually need
- which values have runtime identity, shared state, replaceability, configuration, or resources
- executable boundaries, configuration sources, and resource sharing or release domains
- capability dependency direction and which construction requirements callers must not observe
- transaction consistency needs and the lifetime of transaction-current values

Failure modes this knowledge helps avoid:

- a service-per-function graph that obscures ordinary domain behavior
- public facades that merely mirror private services or force unrelated capabilities together
- feature methods that secretly construct production dependencies or open mismatched lifetimes
- composition roots that contain business policy or get rebuilt for every public call
- public exports that make private infrastructure and transaction machinery contractual

## Patterns

Translate the application by semantic role:

| Role | Default Effect shape |
| --- | --- |
| Canonical values, schemas, pure policy, immutable decisions | Ordinary values and functions |
| Reusable effectful operation without runtime identity | Named function returning `Effect` |
| Coherent capability with replaceability, shared state, configuration, or resources | Service contract plus constructing Layer |
| Private feature capability | Internal service whose requirements are captured by its Layer |
| Cohesive caller-facing application surface | Public facade service or public operations over one or more services |
| Executable/runtime assembly | Named composition root that provides the complete graph once |

- Let dependency direction run from public application surfaces through private feature capabilities to infrastructure capabilities; let Layer construction assemble the reverse provider graph.
- Keep the public Layer output as narrow as the supported application surface. Requirements used to construct it are not automatically outputs.
- Provide one configured graph around a complete multi-operation Effect program so operations share the intended configuration, clients, caches, and scope.
- Keep transaction-current views as ordinary callback-scoped values by default; make them contextual only when caller-supplied transaction context is a deliberate, enforced contract.
- Route detailed decisions to the narrow owner: service shape to `effect-service`, graph and lifetime mechanics to `effect-layer`, boundary representations to `effect-schema`, runtime resources to `effect-platform`, evidence to `effect-testing`, telemetry to `effect-opentelemetry`, and durable orchestration to `effect-workflow`.

## Gotchas

- If every feature function becomes a service, construction noise hides the domain and transaction-scoped values acquire false global identity; keep values ordinary until runtime ownership justifies context.
- If one public facade is imposed by convention, unrelated callers become coupled and the facade turns into an application-wide method catalog; group only capabilities with a coherent caller-facing contract.
- If public access functions provide their live dependencies internally, callers cannot share one graph or replace it coherently; provide the graph at the composition root around the whole program.
- If Layer construction embeds business branching, alternate provision paths can change application policy and runtime wiring becomes a second application layer; keep Layers focused on construction and lifetime.
- If Layer output includes every construction requirement, private adapters become reachable and tests start depending on internals; hide requirements and expose only intentional capabilities.
- If a transaction-current view is installed as a long-lived service, its validity can outlive the transaction that produced it; pass it as an ordinary scoped value unless context is an enforced part of the transaction API.
- If an entrypoint provides the graph separately for each public call, equivalent-looking operations can use different clients, caches, or scopes; provide once around the complete Effect program.
- If an internal module is omitted from package exports but still appears in a public service requirement or return type, the topology leaks through types anyway; close both exports and public contracts.

## References

- [`references/services-values-and-facades.md`](./references/services-values-and-facades.md): Read when: deciding whether a module is an ordinary value, effectful function, private service, or public facade.
- [`references/composition-roots-and-layer-graphs.md`](./references/composition-roots-and-layer-graphs.md): Read when: translating dependency direction into a Layer graph, resolving configuration, or choosing composition roots and scope.
- [`references/feature-and-transaction-ownership.md`](./references/feature-and-transaction-ownership.md): Read when: deciding how private feature requirements, transaction-scoped values, or resource lifetimes appear in the Effect graph.
- [`references/entrypoints-and-public-exports.md`](./references/entrypoints-and-public-exports.md): Read when: providing an entrypoint Effect program, choosing public Layer outputs, or hiding requirements and internal modules.
