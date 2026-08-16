This repo is a library of skills that follow the [Agent Skills spec](https://agentskills.io/home).

For this repo:

- When creating or editing skills, treat `skills/build-a-skill/` as the canonical pattern.
- Preserve the repo's house style: atomic skills, progressive disclosure, separate `Rules` and `Constraints`, strong `Gotchas`, and deterministic validation when practical.
- For `skills/engineering-with-effect/`, treat the skills as knowledge skills that teach current Effect-native authoring standards. Do not add workflow steps, deliverables, or validation checklists to those entrypoints unless the user explicitly asks.
- Keep `README.md` human-facing and concise.

## Implementation simplicity

- For every TypeScript change, read and follow `skills/engineering/typescript/SKILL.md`.
- Prefer direct values and native language constructs over helpers, wrappers, or configuration that only rename, concatenate, forward, or copy.
- Introduce an abstraction only when it names a domain concept, enforces an invariant, hides meaningful complexity, or provides a real variation point. Multiple call sites alone do not justify an abstraction.
- Before finishing, review changed code for behavior-preserving simplifications: remove obsolete workarounds, redundant conditions, unnecessary annotations or copies, parallel index-based data structures, and helpers whose deletion does not spread meaningful complexity.

## Static-analysis integrity

- Never silence or bypass TypeScript, OxLint, or Effect diagnostics.
- Do not add `@effect-diagnostics`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `oxlint-disable`, `eslint-disable`, unsafe type assertions, or non-null assertions.
- Do not weaken rule severity, expand ignore patterns, exclude authored code from typechecking, or change validation scripts to make a failing check pass.
- Fix the underlying code instead.
