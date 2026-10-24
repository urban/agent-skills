---
name: effect-platform
description: Design Effect platform boundaries for files, paths, processes, sockets, terminals, crypto, and runtime adapters with portable capability ownership, scoped cleanup, typed reasons, and realistic test seams. Use when code crosses an OS or runtime boundary.
---

## Rules

- Inspect the installed platform services and runtime adapters before adding filesystem, process, socket, terminal, crypto, or lifecycle infrastructure; isolate only the concrete capability gap behind a narrow adapter.
- Put application meaning behind a domain capability; use low-level platform services directly only in reusable platform-polymorphic helpers or adapters.
- Keep runtime layers and the host's main runner at explicit composition edges; providing capabilities and owning application shutdown are separate responsibilities.
- Decide resource lifetime before exposing handles, streams, subprocesses, servers, or temporary paths.
- Preserve platform reason details until a domain boundary can translate the distinctions callers need.

## Constraints

- A portable capability does not guarantee every target supplies it or preserves identical OS behavior; choose adapters and supported semantics deliberately.
- Do not claim portability while a reusable domain module depends on a runtime-specific adapter.
- Temporary resources and owned handles must be scoped or have an equally explicit release owner.
- A fallback must recover only the failures it semantically handles; absence is not malformed data or permission failure.

## Knowledge Boundaries

Applies to:

- domain capability versus reusable platform helper design
- runtime adapter placement and dynamic selection
- process, file, socket, terminal, and temp-resource ownership
- platform error mapping and fake versus live integration tests

Does not cover:

- syntax, import linting, or compile-time requirement checks
- detailed HTTP or Stream protocol semantics

Decision inputs:

- runtime targets and portability requirement
- handle/resource owner, scope, and cleanup action
- platform error reasons that change domain behavior
- whether a test needs a fake capability, scoped real resource, or runtime integration

## Patterns

- Capture platform services while constructing a domain service when platform access is an implementation detail. Leave requirements visible for genuinely reusable platform helpers.
- In Effect v4, portable services live in `effect` (for example `effect/FileSystem` and `effect/process/ChildProcessSpawner`); runtime implementations come from adapters such as `@effect/platform-node`. Select capabilities at the edge rather than recreating older platform package boundaries.
- Keep resource consumption inside the owning scope, or let the caller's scope own acquisition. A stream or path returned from a completed local scope can outlive its underlying resource.
- Separate command output, exit status, and termination policy. Output collection alone is not evidence of command success.
- Preserve platform failure details through infrastructure layers; translate only distinctions that domain callers can act on.

## Gotchas

- A runtime helper can duplicate an existing capability and spread host assumptions into callers; prefer the installed service and isolate only the actual gap.
- Returning a handle or temp path from `Effect.scoped` closes its owner before the caller uses it; consume it within the scope or acquire in the caller's scope.
- Catch-all fallback can turn denied access or corrupted configuration into silent data loss; recover only the intended absence and propagate other failures.
- Adapter selection inside domain behavior couples every call to environment detection; select at composition time and inject the capability.
- Waiting on a raw process's exit without consuming piped output can deadlock; drain both channels concurrently or use the spawner's draining helpers. Whole-output helpers still require a size policy.
- A timeout does not guarantee prompt subprocess cleanup: Node termination can wait indefinitely without escalation; choose `forceKillAfter` when bounded shutdown is required.
- Matching `NotFound` as the outer error tag misses wrapped filesystem failures; inspect `PlatformError.reason._tag` and retain the original failure when it is not recoverable.

## References

- [`references/capability-and-runtime-boundaries.md`](./references/capability-and-runtime-boundaries.md): Read when: deciding whether to capture requirements, expose a platform-polymorphic helper, or compose runtime adapters.
- [`references/resources-and-processes.md`](./references/resources-and-processes.md): Read when: owning temporary resources, subprocesses, streams, sinks, sockets, or cleanup.
- [`references/platform-errors-and-tests.md`](./references/platform-errors-and-tests.md): Read when: mapping platform reasons or choosing fake versus real platform verification.
