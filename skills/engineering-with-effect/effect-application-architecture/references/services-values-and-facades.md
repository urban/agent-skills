# Services, values, and facades

## Preserve ordinary values

Effect requirements describe capabilities needed at runtime; they are not a module system for every named concept. Keep a value or function ordinary when its identity is entirely in its inputs and outputs and it owns no independently configured or shared runtime concern.

Ordinary shapes commonly include:

- schemas, canonical values, and pure domain policy
- deterministic comparators, transitions, and evidence construction
- immutable commands, mutation intents, and operation results
- operation-local preparation or execution functions
- transaction-scoped semantic views and writers that are valid only inside one callback

A reusable function may still return an `Effect` and declare requirements. That alone does not require a new service. Promote a capability to `Context.Service` when callers need a coherent runtime identity with replaceability, shared state, configuration, owned resources, or construction that captures implementation dependencies.

## Private feature capabilities

A private feature capability coordinates a caller-meaningful use case while hiding infrastructure vocabulary. Its methods speak in domain inputs, outcomes, and expected failures. Its constructing Layer captures repositories, remote protocol services, clocks, identifiers, or other dependencies that are implementation details.

Not every feature module needs a service. Pure features remain ordinary modules, and a one-shot operation can remain a named Effect function when contextual replacement or shared construction adds no value. Conversely, a cohesive private service can be worthwhile even when it has one current caller if it hides a meaningful dependency and policy boundary.

Private does not mean untestable. Test through the public surface when that proves behavior; test a private feature directly only when it owns a substantial contract that the public surface cannot isolate clearly.

## Public facades

A public facade earns its place when it gives callers a stable, cohesive vocabulary while hiding multiple private features and their graph. It may capture private capabilities during construction and expose only supported application operations. Callers then require the facade rather than recreating feature composition.

Do not add a facade that only renames each private method. A facade should reduce caller burden by owning cross-feature policy, hiding graph shape, stabilizing a supported surface, or presenting one coherent capability to an entrypoint or embedding application.

One application may expose:

- one facade for a tightly cohesive product surface
- several facades for independently useful caller groups
- direct public feature capabilities when no extra facade adds depth
- ordinary public Effect functions when a service identity is unnecessary

Choose from caller cohesion and replacement needs, not from a rule that an application must have exactly one service.

## Dependency visibility

Capture implementation requirements while constructing private features and facades. Leave a requirement visible on a public operation only when supplying that capability is intentionally the caller's responsibility, such as request-local context chosen by the caller.

A service's contextual requirements, method inputs, successes, failures, and returned values all contribute to the public contract. Hiding an internal module from exports is insufficient if a public type still mentions its service or representation.

Detailed service granularity, constructor shapes, method errors, and fake implementations belong to service-boundary guidance. Application architecture decides where the service sits and whether it is public; it does not redefine those mechanics.
