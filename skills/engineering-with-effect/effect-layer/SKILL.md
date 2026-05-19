---
name: effect-layer
description: Compose Effect services with focused layers, explicit dependencies, scoped resources, dynamic composition, sharing semantics, typed construction errors, and maintainable test layers. Use when creating, refactoring, debugging, or reviewing Effect Layer wiring, service construction, resource lifetimes, layer sharing, dependency provision, dynamic live layers, or test layer composition.
---

## Native Effect Standards

- A `Layer<ROut, E, RIn>` is a recipe for building services: it **provides** `ROut`, can fail with `E`, and **requires** `RIn`.
- Use layers as composition boundaries, not as business logic modules. Domain behavior belongs behind `Context.Service` contracts; layers wire concrete implementations and lifetimes.
- Prefer one focused layer per service implementation. Compose those layers into application layers at the edge.
- Capture dependencies from context inside `Layer.effect` / service `make` effects with `yield* Service`. Do not pass service instances as ordinary function arguments.
- Use `Layer.succeed` for pure, already-created implementations and fakes.
- Use `Layer.effect` for implementations that need Effect services, configuration, validation, references, or scoped resource acquisition.
- Use `Layer.effectDiscard` only when a layer intentionally provides no services, such as background tasks or startup instrumentation.
- Use `Layer.unwrap` when configuration or runtime state chooses which layer to build.
- Treat layer sharing as intentional. Layers are memoized by the current `MemoMap`; the same layer value is built once and shared until its observers close.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not put domain branching, parsing, or orchestration directly in a top-level application layer. Put it in services and provide those services with layers.
- Do not build layers manually inside ordinary service methods. Manual `Layer.build`, `Layer.buildWithScope`, or `Layer.buildWithMemoMap` belongs at runtime lifetime boundaries.
- Do not rely on default sharing for request-bound resources, sockets, streams, or Worker I/O objects that must be scoped to one request.
- Do not use `Layer.provideMerge` by default. If callers should not see dependency services, use `Layer.provide`.
- Do not use `Layer.orDie` to hide recoverable configuration, validation, network, SQL, or auth failures.
- Do not expose `unknown` error channels from layers. Keep layer and service errors precise.
- Do not create generic errors like `ServiceFailed` or `UnknownError`; define specific tagged errors with actionable fields.
- Do not use partial mocks as a substitute for behavior tests. `Layer.mock` is for replacing external boundaries or services irrelevant to the assertion.
- Do not use module-level mutable state for test doubles when the state should be tied to layer lifetime. Use `Ref`, `Layer.effect`, and scoped test layers.
- Do not add spans around every layer by habit. Use `Layer.withSpan` only when layer construction or lifetime needs explicit observability; method-level spans should use `Effect.fn` when required by the project rules.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- service contracts and dependency graph
- resource lifetimes and sharing requirements
- construction-time configuration and recoverable failures
- test-layer replacement strategy

Effect-native code should tend toward:

- focused service layers and edge compositions
- explicit `Layer.provide`, `provideMerge`, or `mergeAll` usage
- scoped resource acquisition with finalization
- test layers that replace external boundaries without global state

Applies to:

- applying Effect Layer patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for changing layer composition, scoped resources, sharing, or test wiring.
- Keep domain behavior in `Context.Service` methods; use layers to construct, wire, and own lifetimes.
- Choose the layer constructor intentionally: `succeed` for pure fakes, `effect` for dependency capture/config/resources, `effectDiscard` for background startup, and `unwrap` for dynamic composition.
- Use `mergeAll`, `provide`, and `provideMerge` according to whether dependencies should remain visible to callers.
- Model resource acquisition inside scoped layers with finalizers and avoid manual layer builds except at real lifetime boundaries.
- Keep layer construction errors typed and map or recover with specific `Layer.catchTag` only where a fallback is meaningful.
- Build test layers with `Layer.succeed`, `Layer.mock`, `Ref`, scoped resources, and `provideMerge` only when tests need access to backing state.

## Gotchas

- If business logic lands in top-level layers, dependency wiring becomes an untestable orchestration script. Move behavior behind services and let layers construct implementations.
- If `provideMerge` is the default, lower-level dependencies leak into callers and become accidental API. Use `provide` unless tests or middleware need those services exposed.
- If request-bound resources rely on default layer memoization, one request can reuse another request's handles. Build with a fresh memo map only at true lifetime boundaries.
- If `Layer.fresh` is sprinkled around to fix state bugs, resource acquisition duplicates unpredictably. Use it only when independent state is required.
- If layer errors are hidden with `orDie`, recoverable config, auth, or network setup failures become defects. Keep construction failures typed until the final unrecoverable boundary.
- If test doubles store mutable module globals, tests affect each other after layer scopes close. Put fake state in `Ref` or scoped layer resources.

## References

- [`references/patterns-01-effect-layer-patterns-for-agents.md`](./references/patterns-01-effect-layer-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Layer patterns for agents, First principles, Encapsulate behavior behind services, not layers.
- [`references/patterns-02-compose-with-the-right-operator.md`](./references/patterns-02-compose-with-the-right-operator.md): Read when: you need source-pattern detail for Compose with the right operator, Resource and lifetime patterns, Use scoped acquisition in Layer.effect.
- [`references/patterns-03-test-layer-patterns.md`](./references/patterns-03-test-layer-patterns.md): Read when: you need source-pattern detail for Test-layer patterns, Background and entrypoint layers, What to avoid.
