---
name: effect-platform
description: Design Effect platform boundaries for files, paths, processes, sockets, terminals, crypto, and runtime adapters with portable capability ownership, scoped cleanup, typed reasons, and realistic test seams. Use when code crosses an OS or runtime boundary.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Inspect the installed platform services and runtime adapters before adding filesystem, process, socket, terminal, crypto, or lifecycle infrastructure; isolate only the concrete capability gap behind a narrow adapter.
- Put application meaning behind a domain capability; use low-level platform services directly only in reusable platform-polymorphic helpers or adapters.
- Keep Node, Bun, browser, Worker, and other runtime layers at explicit composition edges.
- Decide resource lifetime before exposing handles, streams, subprocesses, servers, or temporary paths.
- Preserve platform reason details until a domain boundary can translate the distinctions callers need.

## Constraints

- Some v4 platform capabilities, including process APIs, remain under unstable module surfaces; verify imports and API details against the installed release.
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

- mechanical diagnostics for direct runtime imports
- detailed HTTP or Stream protocol semantics

Decision inputs:

- runtime targets and portability requirement
- handle/resource owner, scope, and cleanup action
- platform error reasons that change domain behavior
- whether a test needs a fake capability, scoped real resource, or runtime integration

## Patterns

- Capture platform services while constructing a domain service when platform access is an implementation detail. Leave requirements visible for genuinely reusable platform helpers.
- Compose one runtime adapter set at the application edge; use dynamic selection only when one artifact intentionally supports multiple runtimes.
- Use scoped temporary files/directories and scoped process/server acquisition so interruption performs cleanup.
- Expose process output as Stream and input as Sink when data is incremental; keep raw process handles private unless process control is the capability.
- Translate not-found, permission, timeout, already-exists, and invalid-argument distinctions only when domain callers act differently.
- Use focused fake services for behavior tests and scoped real resources for platform integration tests.

## Gotchas

- A runtime-specific helper can duplicate an installed platform service and leak portability or cleanup obligations into callers; verify the current platform surface before adding it.
- A domain API returning file or process handles transfers lifecycle responsibility to callers, often unintentionally.
- Catch-all fallback to an empty/default value can turn corrupted configuration or denied access into silent data loss.
- Selecting a runtime adapter inside domain behavior couples every call to environment detection and complicates tests.
- Collecting subprocess output without a bound or concurrent stderr drain can deadlock or exhaust memory.
- Temporary resources created outside a scope survive failures and make tests order-dependent.
- Replacing every platform error with one generic error erases remediation such as create, request permission, retry, or fix input.

## References

- [`references/capability-and-runtime-boundaries.md`](./references/capability-and-runtime-boundaries.md): Read when: deciding whether to capture requirements, expose a platform-polymorphic helper, or compose runtime adapters.
- [`references/resources-and-processes.md`](./references/resources-and-processes.md): Read when: owning temporary resources, subprocesses, streams, sinks, sockets, or cleanup.
- [`references/platform-errors-and-tests.md`](./references/platform-errors-and-tests.md): Read when: mapping platform reasons or choosing fake versus real platform verification.
