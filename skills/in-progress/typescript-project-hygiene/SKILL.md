---
name: typescript-project-hygiene
description: Maintain TypeScript project boundaries through strict compiler settings, deliberate imports and exports, cohesive files, justified type-safety escape hatches, parsed configuration, and isolated module side effects. Use when configuring or reviewing TypeScript project structure and safety hygiene.
---

## Rules

- Enable strict compiler checks that expose unsafe absence, indexing, overrides, and switch fallthrough unless a documented compatibility constraint prevents them.
- Import from the module that owns an abstraction and export only the surface callers should use.
- Prefer type-only imports and exports when a symbol has no runtime role.
- Name files for the concept they own and split by independent reasons to change, not arbitrary line counts.
- Treat casts as proof obligations rather than routine ways to silence the compiler; do not introduce `any` or non-null assertions.
- Parse configuration once at startup or the earliest boundary into typed, redacted domain configuration.
- Keep module import evaluation free of application I/O, resource acquisition, ambient time/random reads, handler registration, and server startup.

## Constraints

- Do not introduce `any`; isolate untyped interop as `unknown` and narrow it.
- Do not introduce a non-`as const` cast without a narrow interop or type-system limitation and a local justification.
- Do not use non-null assertions; branch, parse, narrow, or redesign the type instead.
- Do not read `process.env` throughout application modules.
- Do not export internals solely so a test can reach them.
- Do not add a barrel, namespace, singleton, or shared prelude as a default convenience.

## Knowledge Boundaries

Applies to:

- TypeScript compiler safety baseline
- import, export, barrel, namespace, file, and prelude decisions
- prohibiting `any` and non-null assertions; casts, safety comments, and targeted lint suppression
- environment configuration, top-level effects, globals, and import-time ambient reads

Does not cover:

- functional expression style or domain-state modeling
- module architecture, persistence capabilities, or testing strategy
- project-specific formatter and import-order configuration

Decision inputs:

- package and runtime module system
- existing compiler and lint configuration
- public package entrypoints versus internal source modules
- runtime ownership of configuration, import-time registration, resources, and global state

Failure modes this knowledge helps avoid:

- type safety erased by undocumented assertions
- circular or ambiguous module ownership hidden by barrels
- import-time behavior that leaks resources or makes tests order-dependent
- secrets and invalid configuration propagating as ordinary strings

## Patterns

- Prefer `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, and `noFallthroughCasesInSwitch`; adopt incrementally when legacy errors make an immediate switch unsafe.
- Align `module` and `moduleResolution` with the package and runtime, and use `verbatimModuleSyntax` when the toolchain supports its explicit import/export semantics.
- Use direct source-module imports internally. Reserve package-root entrypoints for intentional public package surfaces, not recursive internal barrels.
- Keep helpers private unless multiple production callers share them. Test through the owning public behavior rather than widening exports.
- Use precise filenames such as `email-address.ts` or `billing-period.ts`; avoid catch-all `utils.ts`, `helpers.ts`, `common.ts`, and `misc.ts`.
- Permit a small `prelude.ts` only for ubiquitous, domain-neutral primitives. Keep product policy and feature helpers in their owning modules.
- At an unavoidable cast, state the invariant already established and why TypeScript cannot express it. Scope any lint disable to the exact line and rule.
- Decode environment input once, wrap secrets before they enter application code, and unwrap only at the exact adapter call that needs the raw value.
- Create connections, servers, subscriptions, and mutable registries in bootstrap or an explicit resource owner; do not acquire them during module evaluation.

## Gotchas

- If internal modules import through a barrel, circular dependencies and ownership become invisible until runtime initialization fails. Import from the owning file and keep package entrypoints one-way.
- If a test requires exporting a private helper, the suite starts coupling to implementation and prevents refactoring. Exercise the behavior through the module surface or move the helper into a real shared module.
- If every cast gets a generic “TypeScript limitation” comment, the comment proves nothing and unsafe assumptions accumulate. Name the checked invariant and containment boundary precisely.
- If configuration remains raw strings, invalid values and secrets travel far beyond the boundary that understood them. Parse and redact once before constructing application modules.
- If a module opens a connection or registers a handler at import time, test order and tool discovery change runtime behavior. Move acquisition and registration into explicit bootstrap.
- If import evaluation reads a clock, RNG, or mutable singleton, merely importing a module becomes nondeterministic and order-dependent. Defer that read to an explicit runtime owner.
- If strict flags are enabled without scoping a legacy migration, unrelated work balloons into a repository rewrite. Keep the target baseline explicit and adopt it through bounded changes.

## References

- [`references/compiler-and-escape-hatches.md`](./references/compiler-and-escape-hatches.md): Read when: selecting strict compiler flags, containing untyped interop, or justifying a cast or lint suppression.
- [`references/imports-exports-and-files.md`](./references/imports-exports-and-files.md): Read when: designing imports, package entrypoints, barrels, export surfaces, namespaces, filenames, or a prelude.
- [`references/configuration-and-module-effects.md`](./references/configuration-and-module-effects.md): Read when: loading configuration, handling secrets, acquiring resources, avoiding import-time effects, or isolating ambient state.
