# TypeScript and Node

## Safety baseline

Prefer these checks for maintained TypeScript code. Keep the source compatible with Node's native type stripping by using erasable TypeScript syntax, even when the project also emits JavaScript.

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true
  }
}
```

The checks protect different contracts: indexed access can be absent, an absent optional property differs from a present `undefined`, overrides and fallthrough should be deliberate, and static type bindings must not become runtime imports. Inspect existing configuration and compiler support before adopting them; `erasableSyntaxOnly` requires TypeScript 5.8 or newer. Bound adoption rather than hiding diagnostics with casts.

## Native Node execution

Check the project's pinned Node version. Type stripping erases types without checking them and ignores `tsconfig.json`; run the configured type check separately.

For direct execution on a supporting Node version, a compiler profile can add:

```json
{
  "compilerOptions": {
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "noEmit": true,
    "rewriteRelativeImportExtensions": true
  }
}
```

- Use explicit relative source extensions such as `./email-address.ts`. For JavaScript distribution, enable emission and retain extension rewriting.
- Match package `type` and `.ts`/`.mts`/`.cts` semantics to the host; stripping does not convert module systems.
- Use `import type`, inline `type` specifiers, and `export type` for erased bindings.
- Avoid enums, parameter properties, runtime namespaces, and TypeScript import aliases that require transformation. Namespace imports (`import * as X`) are ordinary JavaScript; type-only namespaces are erasable but are not a default organizational tool.
- Do not rely on `tsconfig` path aliases or downlevel transformations at runtime. TSX needs a separate toolchain; Node does not strip TypeScript in `node_modules`.

Choose JavaScript syntax for the minimum supported runtime. Native execution and emitted distribution are separate checks when both are supported.

See [Node's TypeScript documentation](https://nodejs.org/api/typescript.html) for the supported syntax and runtime contract.

## Imports and public surfaces

For native Node ESM, make ownership and erased bindings explicit:

```ts
import * as EmailAddress from "./email-address.ts"
import { PasswordReset } from "./password-reset.ts"
import type { PasswordResetRequest } from "./password-reset.ts"
```

Namespace imports suit function-oriented domain modules; named imports suit focused helpers or classes. Preserve a mechanically enforced import spelling when it remains compatible with the runtime. A convention that emits a type as a value cannot satisfy native stripping.

Avoid internal `index.ts` barrels by default. Keep deliberate package entrypoints for supported external contracts; direct internal imports toward owning files. A `prelude.ts` should remain small and domain-neutral rather than collecting application policy.

## Negative type tests

Use documented `@ts-expect-error` on an expression that must be rejected. It reports an unused directive when the expression stops producing an error. Keep the rejected expression isolated so another diagnostic cannot accidentally satisfy the test, and pair it with an accepted case where useful. `@ts-ignore` does not provide that regression signal.

Keep ordinary production checks strict. A verified analyzer false positive may justify a narrow, reasoned configuration override; it does not justify suppressing a production defect.
