# Imports, exports, and files

## Import ownership

Import an abstraction from the file that owns it:

```ts
import * as EmailAddress from "./email-address"
import { PasswordReset } from "./password-reset"
import type { PasswordResetRequest } from "./password-reset"
```

Namespace imports can preserve the shape of a function-oriented domain module. Named imports suit classes and focused helpers. This is not permission to use the TypeScript `namespace` declaration, which introduces a separate legacy module model and should be reserved for required interop.

Follow an explicit repository import policy first. Otherwise use `import type` and `export type` when the binding has no runtime role and the configured compiler and lint rules support that spelling. This makes runtime dependencies visible and avoids accidental emitted imports under stricter module settings. Some projects intentionally use import type expressions or another mechanically enforced form; do not replace that local contract with a universal preference.

## Barrels and package entrypoints

Avoid internal `index.ts` re-export layers by default. They obscure ownership, invite circular initialization, increase accidental public surface, and make repository search less direct.

A deliberate package entrypoint is different: it defines the supported public surface for external consumers. Keep internal source imports directed toward owning files rather than back through that public entrypoint.

## Export surface

Export only what production callers are meant to use. Keep implementation helpers local. If several production modules need a helper, move it to a precisely named owner instead of exporting it from an unrelated module.

Do not export a private helper merely for unit testing. Test the observable module contract; if the helper contains an independently valuable concept, promote that concept deliberately and give it its own interface.

## File cohesion

Name files for the concept they own:

- `email-address.ts`
- `billing-period.ts`
- `invoice-number.ts`
- `string-case.ts`

Avoid names that collect unrelated leftovers:

- `utils.ts`
- `helpers.ts`
- `common.ts`
- `misc.ts`

No fixed file-size limit determines cohesion. Split when a file contains unrelated concepts, dependencies, or reasons to change, or when callers must understand unrelated material to use one part.

A `prelude.ts` may hold a very small set of ubiquitous, domain-neutral helpers and types. It must not become a dependency magnet or hold application policy. When a helper develops domain language or specialized dependencies, move it to that domain's module.
