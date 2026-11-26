# Imports, exports, and files

## Dependency ownership

Depend on the module that owns the concept. Inside a package, prefer a direct ownership path when the language permits it. Across package boundaries, use the supported public entrypoint; do not reach into another package's private source to avoid a facade.

Respect idiomatic visibility, package initialization, and import conventions. A language may define a package as the unit of ownership rather than a single file. The goal is to make ownership clear without bypassing that contract.

Keep runtime dependencies distinguishable from references needed only for static analysis when the language supports that distinction. Ensure every runtime dependency can actually resolve under the host's loader, rather than assuming a checker or editor alias supplies runtime behavior.

## Re-exports and package entrypoints

Avoid internal forwarding or re-export layers introduced solely for convenience. They can obscure ownership, invite cycles, and grow an accidental public surface.

A deliberate package facade is different: it defines the supported contract for external consumers, or satisfies the language's package model. Preserve it. Keep dependencies within a package directed toward the owning module where possible, rather than looping through the package's external entrypoint.

## Public surface

Expose only what supported callers are meant to use. Keep implementation helpers private. If several modules need a helper, give it a precisely named owner instead of exposing it from an unrelated module.

Do not publish private internals solely to support test spies. A supported lower-level building block may be public when consumers actually need to compose it and its invariants remain enforceable.

## File cohesion

Name files and modules for the concepts they own, using the language's naming conventions. Catch-all utility modules tend to collect unrelated responsibilities and make dependency ownership harder to infer.

No fixed file-size limit determines cohesion. Split by unrelated concepts, dependencies, or reasons to change, or when callers must understand unrelated material to use one part. Respect language rules that determine which declarations can share a file.

A shared prelude may hold a very small set of ubiquitous, domain-neutral helpers and types when it is idiomatic. Keep application policy and specialized dependencies in their owning domain modules so the prelude does not become a dependency magnet.

## Initialization and module loading

Ordinary module loading should define values and behavior without starting application work. Immutable constants and pure lookup tables are safe. Defer servers, workers, connections, configuration reads, handler registration, timers, mutable global registries, and ambient time or randomness to an explicit entrypoint or bootstrap/resource function.

When a language or framework requires load-time registration or singleton initialization, isolate it in a boundary module. Expose a replaceable interface inward and keep lifetime obligations explicit. Do not spread required initialization across otherwise ordinary domain imports.
