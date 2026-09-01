# Compiler and escape hatches

## Safety baseline

Prefer these compiler checks for maintained TypeScript code:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true
  }
}
```

They prevent different failures:

- `strict` enables the core family of soundness checks.
- `noUncheckedIndexedAccess` makes missing array/record entries visible.
- `exactOptionalPropertyTypes` distinguishes a missing property from an explicitly present `undefined` unless the type allows both.
- `noImplicitOverride` makes inheritance overrides explicit.
- `noFallthroughCasesInSwitch` catches accidental fallthrough.
- `verbatimModuleSyntax` preserves explicit runtime versus type-only imports and exports.

Choose `module` and `moduleResolution` from the actual package and runtime contract—for example Node ESM/CJS behavior, a bundler, or another host—rather than copying a universal pair. `verbatimModuleSyntax` is appropriate when the selected compiler/toolchain supports those explicit semantics.

Inspect the existing config before changing it. For legacy code, prefer a bounded migration or newly scoped package over hiding thousands of diagnostics with casts.

## Compiler and diagnostic ownership

Use TypeScript compilation for language and project-reference soundness. Treat framework-aware or advisory diagnostics as a separate configured layer whose recommended profile and severity policy must be inspected rather than guessed. Do not blanket-enable every experimental, nursery, pedantic, or advisory rule, and do not turn all warnings into errors without reviewing whether the resulting rules express project policy.

Keep tests under the same correctness baseline as implementation code. Add an override only for a real test-runtime or generated-fixture distinction, not to excuse large examples or broad style violations.

Run the repository's configured validation commands after TypeScript or diagnostic configuration changes. If a change affects inference across project references, use the repository-supported forced or clean build so stale incremental information cannot masquerade as a successful check; do not hardcode one package manager or command into a reusable rule.

## Escape-hatch hierarchy

Before asserting, try:

1. improve the domain type or generic constraint,
2. branch on absence,
3. narrow `unknown` with a parser or type guard,
4. preserve a relationship with generics,
5. isolate untyped interop in one adapter.

`as const` is a normal inference tool. Other casts are exceptional and should remain at verified boundaries, branding internals, or highly generic helpers whose invariant TypeScript cannot express.

Do not use `!`. A non-null assertion records no evidence and remains valid even when the assumption later becomes false.

## Safety comments

A useful safety comment states:

- the invariant that has already been checked,
- why TypeScript cannot represent it,
- how callers are prevented from violating it,
- the narrow scope in which the assertion is valid.

```ts
// SAFETY: `decodeUserId` validated the canonical UUID representation.
// This module does not export another UserId constructor.
return input as UserId
```

Do not introduce `any` for untyped interop; contain the value as `unknown`, then parse, narrow, or adapt it. If a third-party declaration itself contains `any`, keep that unsafety behind one adapter rather than reproducing it in project-owned types.

Do not use source-level suppression to make project-owned code pass. Fix the type, function shape, or module boundary first. When a rule verifiably misinterprets an established construct, prefer the narrowest centralized file-pattern override with a reason, leave the rule active elsewhere, and revisit the exception when tool support changes. Do not weaken a rule globally when one boundary contains the incompatibility.
