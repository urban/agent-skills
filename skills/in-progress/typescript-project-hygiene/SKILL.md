---
name: typescript-project-hygiene
description: Apply TypeScript compiler configuration and module policy. Use when configuring compiler or lint diagnostics, reviewing imports and package exports, or isolating import-time effects.
---

## Rules

- Inspect the existing toolchain and runtime contract before changing compiler settings; scope stricter checks to a bounded migration.
- Align module settings with the actual host, and follow explicit project type-import conventions.
- Import from owning source modules internally; reserve package entrypoints for the supported public surface.
- Export deliberate caller-facing contracts. Name files for their concepts and split by independent reasons to change.
- Keep ordinary module evaluation free of application I/O, resource acquisition, configuration reads, handler registration, and ambient time or randomness.

## Constraints

- Do not suppress production defects to make checks pass. For verified tool false positives, use the narrowest supported configuration override with a reason; leave the rule active elsewhere.
- Do not add internal barrels, TypeScript namespaces, or shared preludes as default conveniences.
- Do not turn a local change into an unrelated compiler or lint migration.

## Knowledge Boundaries

Applies to compiler settings, diagnostic policy, imports, exports, file cohesion, and module evaluation. Inspect package boundaries, runtime, and configured checks. Domain modeling, expression style, configuration decoding, runtime ownership, and test strategy are outside this skill.

## Patterns

| Decision | Default |
| --- | --- |
| Compiler baseline | Prefer `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, and `noFallthroughCasesInSwitch`. |
| Module semantics | Match `module` and `moduleResolution` to the host; use `verbatimModuleSyntax` when supported. |
| Type-only bindings | Follow local policy; otherwise prefer `import type` and `export type` when supported. |
| Configuration changes | Run configured checks; use a supported forced or clean build when stale project-reference output could hide errors. |
| Negative type tests | Allow documented `@ts-expect-error` to verify intended rejection; keep ordinary production checks strict. |

## Gotchas

- Internal imports through a package barrel obscure ownership and invite initialization cycles. Import from the owning file.
- Enabling strict flags across legacy code can turn a small task into a rewrite. Bound the migration instead of hiding errors with casts.
- Replacing an enforced import convention with a preferred spelling breaks valid code. Preserve the project's configured contract.
- Starting resources or reading ambient state during import makes discovery and tests order-dependent. Defer those actions to explicit runtime boundaries.
- Blanket suppression bans also block intentional rejection tests. Distinguish negative type assertions from comments that conceal production defects.

## References

- [`references/compiler-and-diagnostics.md`](./references/compiler-and-diagnostics.md): Read when: choosing compiler settings, diagnostic exceptions, or incremental validation behavior.
- [`references/imports-exports-and-files.md`](./references/imports-exports-and-files.md): Read when: deciding import ownership, package surfaces, file cohesion, or import-time behavior.
