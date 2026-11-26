---
name: project-hygiene
description: Align project checks and module policy with the runtime across programming languages. Use when configuring compiler or analyzer diagnostics, reviewing dependencies and public surfaces, organizing source files, or isolating initialization effects.
---

## Rules

- Inspect the existing toolchain, package boundaries, and runtime contract before changing checks or module settings. Scope stricter policies to a bounded migration.
- Align source syntax, dependency resolution, and build output with the actual host. Follow project conventions that satisfy that runtime contract.
- Depend on the module that owns a concept, respecting language visibility and package conventions. Reserve public package entrypoints for deliberate consumer contracts.
- Expose supported caller-facing behavior and keep implementation details private. Name files for their concepts and split by independent reasons to change.
- Keep application startup and resource acquisition at explicit runtime boundaries. Isolate initialization required by a language or framework so ordinary imports or module loading do not start application work.

## Constraints

- Do not suppress production defects to make checks pass. For verified tool false positives, use the narrowest supported override with a reason; leave the rule active elsewhere.
- Do not add forwarding modules, re-export layers, or shared preludes solely for convenience when they obscure ownership or introduce cycles. Preserve intentional package facades and required language conventions.
- Do not turn a local change into an unrelated tooling migration or impose one language's layout and import rules on another.

## Knowledge Boundaries

Applies to compiler and analyzer policy, dependency resolution, module visibility, package surfaces, file cohesion, and initialization behavior in compiled or interpreted languages. Inspect the supported runtime, build and package configuration, and configured checks.

Domain modeling, expression style, configuration decoding, resource-lifetime design, test strategy, dependency upgrades, and general CI design are outside this skill.

## Patterns

| Decision | Default |
| --- | --- |
| Check baseline | Select supported checks that expose consequential mistakes; inspect severity and adoption cost before expanding policy. |
| Runtime compatibility | Match language features, module resolution, and emitted artifacts to the minimum supported host. |
| Dependency ownership | Use the owning module within a package; use supported entrypoints across package boundaries, following the language's access rules. |
| Initialization | Defer I/O, configuration reads, handler registration, and ambient time or randomness to explicit startup; isolate required registration. |
| Configuration changes | Run configured checks over affected dependencies; use supported clean or forced validation when stale artifacts could hide errors. |
| Intentional rejection tests | Use the toolchain's expected-diagnostic mechanism; distinguish deliberate negative cases from concealed production errors. |

## Gotchas

- Routing internal dependencies through a public facade can hide ownership and create initialization cycles. Use direct ownership paths where the language and package contract allow them.
- Copying another project's settings can pass static checks while breaking runtime resolution. Check the actual host, loader, packaging, and output contract.
- Enabling strict checks across legacy code can turn a small task into a rewrite. Bound adoption instead of hiding defects with assertions or suppressions.
- Applying one language's module style universally can bypass supported package boundaries. Preserve idiomatic facades and visibility rules while keeping ownership clear.
- Starting resources or reading ambient state during module loading makes discovery and tests order-dependent. Defer startup or isolate the required initialization boundary.
- Blanket suppression bans also block intentional rejection tests. Use a supported expected-diagnostic assertion that detects when rejection stops occurring.

## References

- [`references/compiler-and-diagnostics.md`](./references/compiler-and-diagnostics.md): Read when: choosing checks, diagnostic exceptions, or validation across cached build artifacts.
- [`references/imports-exports-and-files.md`](./references/imports-exports-and-files.md): Read when: deciding module ownership, package surfaces, file cohesion, or initialization behavior.
- [`references/typescript-and-node.md`](./references/typescript-and-node.md): Read when: applying TypeScript compiler policy, preserving Node type-stripping compatibility, or choosing type-only imports and negative type tests.
