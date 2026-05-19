---
name: effect-service
description: Design Effect Context.Service boundaries with small domain contracts, dependency capture, typed errors, layers, scoped resources, test services, and modern service access patterns. Use when creating, refactoring, or reviewing Effect services, service shapes, layers, dependency access, error contracts, test doubles, or migration away from older Context APIs.
---

## Native Effect Standards

- Use `Context.Service` for new services. Do not use old v3 APIs such as `Context.Tag`, `Context.GenericTag`, `Effect.Tag`, or `Effect.Service`.
- Prefer class syntax for application services: `export class Thing extends Context.Service<Thing, ThingShape>()("pkg/path/Thing") {}`.
- Treat the service class as both the dependency key and an Effect. `const thing = yield* Thing` reads the implementation from the current fiber context.
- Treat the service shape as the public capability contract. Keep it small, domain-oriented, and stable.
- Use stable, package-scoped identifiers such as `"app/process/ProcessRunner"`, `"@app/plugin-openapi/OpenApiExtensionService"`, or `"app/State"`.
- Build implementations with `Thing.of({ ... })`. `of` just returns the implementation shape; resource acquisition, dependency capture, validation, and error mapping belong in `make`, `Layer.effect`, or private helpers.
- A `make` option on `Context.Service` stores a constructor effect, but it does not create a layer. Define `static readonly layer = Layer.effect(this, this.make)` or an exported `layer` yourself.
- In this project, use `Effect.fnUntraced` for effectful wrappers unless spans are required. Use `Effect.fn` only when the method should create spans.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not create giant service bags. Split by behavior boundary and compose layers.
- Do not pass service implementations as function arguments. Yield required services from context inside effect bodies.
- Do not expose low-level dependencies through high-level service shapes unless callers truly need them.
- Do not create stateful globals outside layers. Use `Layer`, `Ref`, `Queue`, `PubSub`, `Scope`, and finalizers so tests can replace and tear down services safely.
- Do not use `Context.Service(..., { make })` expecting it to auto-wire dependencies or create a layer.
- Do not use direct `JSON.parse` / `JSON.stringify` at implementation boundaries. Use `Schema.fromJsonString(...)` codecs.
- Do not use web `fetch` / `Response` at package boundaries. Prefer first-party Effect HTTP services.
- Do not expose generic failures like `XFailed`, `UnknownError`, or `InternalError` from service methods.
- Do not use `Effect.orDie`; handle typed errors with `Effect.catchTag` / `Effect.catchTags`, then `Effect.die` only for genuinely unrecoverable failures.
- Do not erase errors with `unknown`, `any`, broad catches, or untyped defects.
- Do not use non-null assertions or type assertions in service shapes or implementations.
- Do not overuse `Service.use` for workflows. Prefer `yield* Service` in `Effect.gen`.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- capability boundary and domain operations
- dependencies, resources, and external systems owned by the service
- typed expected failures and error mapping
- live, no-deps, parameterized, and test layer needs

Effect-native code should tend toward:

- `Context.Service` classes with stable identifiers and small shapes
- `make`, `layerNoDeps`, live layers, or parameterized layer factories
- typed domain errors and boundary error mapping
- test layers using `Layer.succeed`, `Layer.mock`, `Ref`, or scoped resources

Applies to:

- applying Effect Context.Service patterns to implementation, refactoring, review, or tests
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

- Bundled `references/patterns-*` files contain source-pattern detail for adding service classes, service layers, test doubles, or error contracts.
- Define a small domain-shaped service contract before choosing dependencies or implementation details.
- Use `Context.Service` class syntax with stable package-scoped identifiers and `Service.of` to build implementations.
- Capture dependencies in `make` or `Layer.effect` with `yield* Dependency`; do not pass service instances around manually.
- Expose `layerNoDeps`, live `layer`, or parameterized layer factories according to composition needs.
- Map lower-level errors into precise tagged service errors and keep non-actionable defects out of public expected failure channels.
- Test consumers with small test services or `Layer.mock`, and test implementations through the public service methods.

## Gotchas

- If a service shape becomes a giant dependency bag, callers couple to implementation details. Split by behavior boundary and expose domain verbs.
- If `Context.Service(..., { make })` is assumed to create a layer, dependencies will not be wired. Define `Layer.effect(Service, Service.make)` or an exported layer explicitly.
- If service implementations are passed as function arguments, context requirements disappear from types and layer replacement gets harder. Yield services inside effects.
- If raw HTTP, process, file, SQL, or vendor errors leak from high-level services, callers depend on adapter details. Normalize to domain tagged errors.
- If expected failures use `throw`, rejected promises, or `Effect.orDie`, the type system cannot force handling. Keep expected failures in the Effect error channel.
- If tests use global mutable mocks, service lifetime and isolation are false. Use layers, `Ref`, `Queue`, scoped resources, or `Layer.mock`.

## References

- [`references/patterns-01-effect-context-service-patterns-for-agents.md`](./references/patterns-01-effect-context-service-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Context.Service patterns for agents, First principles, Encapsulate behavior behind capabilities.
- [`references/patterns-02-split-the-contract-from-wiring.md`](./references/patterns-02-split-the-contract-from-wiring.md): Read when: you need source-pattern detail for Split the contract from wiring, Capture dependencies once in make.
- [`references/patterns-03-use-layer-factories-for-parameterized-resources.md`](./references/patterns-03-use-layer-factories-for-parameterized-resources.md): Read when: you need source-pattern detail for Use layer factories for parameterized resources, Use scoped acquisition for owned resources, Provide small test services.
- [`references/patterns-04-error-handling-patterns.md`](./references/patterns-04-error-handling-patterns.md): Read when: you need source-pattern detail for Error handling patterns, Accessing services, What to avoid.
