# Compiler and diagnostics

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

- `strict` enables TypeScript's strict checking family.
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

## Diagnostic exceptions

Fix production defects in the type, function shape, or module boundary rather than suppressing them. When a tool verifiably misinterprets an established construct, use the narrowest supported centralized file-pattern override with a reason, leave the rule active elsewhere, and revisit the exception when tool support changes. Do not weaken a rule globally to contain one incompatibility.

Intentional negative type tests are different: use a documented `@ts-expect-error` on the expression that must be rejected. Unlike `@ts-ignore`, it reports an unused directive when that expression stops producing an error. Keep the rejected expression isolated so an unrelated diagnostic cannot satisfy the test, and pair it with an accepted case where useful. This exception does not permit hiding production errors.
