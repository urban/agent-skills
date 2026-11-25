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

## File cohesion

Name files for the concept they own, such as `email-address.ts` or `billing-period.ts`. Avoid catch-all names such as `utils.ts`, `helpers.ts`, or `misc.ts` that collect unrelated responsibilities.

No fixed file-size limit determines cohesion. Split when a file contains unrelated concepts, dependencies, or reasons to change, or when callers must understand unrelated material to use one part.

A `prelude.ts` may hold a very small set of ubiquitous, domain-neutral helpers and types. It must not become a dependency magnet or hold application policy. When a helper develops domain language or specialized dependencies, move it to that domain's module.

## Module evaluation

Ordinary module evaluation defines values and behavior. It should not start servers or workers, open connections, read environment configuration, register runtime handlers, start timers, mutate global registries, or read ambient time or randomness. Immutable constants and pure lookup tables are safe.

Defer those actions to a true entrypoint or explicit bootstrap/resource function. When a framework requires import-time registration or singleton state, isolate that requirement in a boundary module and expose a replaceable interface inward.
