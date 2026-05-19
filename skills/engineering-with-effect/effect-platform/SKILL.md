---
name: effect-platform
description: Implement OS and runtime boundaries with Effect platform services for files, paths, stdio, terminals, child processes, sockets, HTTP runtime adapters, scoped resources, and deterministic tests. Use when code crosses filesystem, path, process, terminal, stdio, socket, worker, HTTP-server, Node, Bun, or runtime-entrypoint boundaries in an Effect codebase.
---

## Native Effect Standards

- Encapsulate platform behavior behind domain services. Callers should ask for `WorkspaceFileSystem.writeFile`, `Profile.setProfile`, or `GitVcsDriver.execute`, not receive `FileSystem` and `Path` plumbing.
- Yield platform services from context inside an effect body: `const fs = yield* FileSystem.FileSystem`. Do not pass `fs`, `path`, or process spawners as normal arguments.
- Keep runtime-specific layers at the application edge. Domain services should depend on Effect service tags, not on `@effect/platform-node` or `@effect/platform-bun` modules.
- Prefer `Effect.fnUntraced` for platform methods unless a span is intentionally required. Use `Effect.fn` only when tracing is desired.
- Use `Stream.Stream` and `Sink.Sink` for streaming platform data. Do not write ad hoc reader loops in application implementations when `Stream` can model the flow.
- Use scoped resource APIs for temporary files, file handles, subprocesses, servers, and background work. Prefer `makeTempDirectoryScoped`, `makeTempFileScoped`, `Effect.scoped`, and `Effect.acquireRelease`.
- Keep final live layer compositions typed as `Layer.Layer<ProvidedServices>`. Let local and test layers infer naturally.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not import `node:fs`, `node:path`, `node:child_process`, or Bun-specific APIs inside domain services. Use Effect platform services.
- Do not pass `FileSystem`, `Path`, or child-process service instances as function parameters. Yield services from context.
- Do not let high-level domain APIs expose platform primitives unless platform access is the purpose of the API.
- Do not map every platform failure to a generic `XFailed`, `InternalError`, or `UnknownError`. Use specific tagged errors with actionable reasons.
- Do not erase error channels with `unknown`; preserve `PlatformError.PlatformError` or map to a precise domain error.
- Do not use `Effect.orDie` in this project. If Effect source examples use it for release finalizers, adapt the code to handle typed errors explicitly or defect only at a final unrecoverable boundary.
- Do not use type assertions, non-null assertions, `any`, direct `JSON.parse`, or direct `JSON.stringify` in application code. Use Effect Schema codecs at boundaries.
- Do not top-level import `@effect/platform-node` from code that can run under Bun or in the browser. Choose runtime adapters at the edge with `Layer.unwrap` or dynamic imports.
- Do not test platform behavior by sleeping, relying on wall-clock races, or leaving temp files behind. Use `Effect.scoped`, `TestClock` where applicable, and platform test layers.
- Do not hand-roll async generators, web readers, or stream loops when `Stream` and `Sink` model the platform interaction.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- platform capability needed and owning domain service
- runtime target such as Node, Bun, browser, Worker, or test
- resource lifetime and cleanup requirements
- typed error mapping and test boundary

Effect-native code should tend toward:

- domain services over Effect platform capabilities
- runtime-specific layers composed at the edge
- scoped temp/resource/process management
- tests using platform test layers, scoped temp resources, or fake process handles

Applies to:

- applying Effect Platform patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for using files, paths, child processes, runtime services, scoped resources, or platform tests.
- Encapsulate platform access behind domain services; callers should not receive raw `FileSystem`, `Path`, spawner, or handle plumbing.
- Yield platform services from context inside effect bodies or service construction and keep runtime-specific adapters at composition edges.
- Use `Stream` and `Sink` for streaming platform data, not manual reader loops.
- Acquire temporary files, handles, subprocesses, servers, and background work with scoped APIs and finalizers.
- Translate `PlatformError` or adapter errors into domain tagged errors at service boundaries when callers can act.
- Test with `FileSystem.layerNoop`, fake `ChildProcessSpawner`, scoped temp resources, or real platform services only for integration tests.

## Gotchas

- If domain services import `node:fs`, `node:path`, or `child_process`, runtime and test portability disappear. Depend on Effect platform services and compose Node/Bun layers at the edge.
- If platform service instances are passed as ordinary arguments, dependency visibility and layer replacement break. Yield them from context.
- If high-level APIs expose file handles or process handles, callers inherit lifecycle bugs. Expose domain operations and keep handles private.
- If platform failures are all mapped to `UnknownError`, useful reasons like not-found, permission, timeout, and bad argument are lost. Preserve or translate typed reasons.
- If subprocess output is collected with ad hoc loops, backpressure and cleanup are easy to miss. Use `Stream`, `Sink`, and scoped process handles.
- If tests leave temp files or rely on sleeps around processes, failures become order-dependent. Use scoped temp resources, fake spawners, and `TestClock` where applicable.

## References

- [`references/patterns-01-effect-platform-patterns-for-agents.md`](./references/patterns-01-effect-platform-patterns-for-agents.md): Read when: you need source-pattern detail for Effect Platform patterns for agents, What Platform means here, First principles.
- [`references/patterns-02-leave-requirements-explicit-for-reusable-platfor.md`](./references/patterns-02-leave-requirements-explicit-for-reusable-platfor.md): Read when: you need source-pattern detail for Leave requirements explicit for reusable platform helpers, Compose platform adapters at the edge, Error handling patterns.
- [`references/patterns-03-prefer-scoped-temp-resources-over-manual-cleanup.md`](./references/patterns-03-prefer-scoped-temp-resources-over-manual-cleanup.md): Read when: you need source-pattern detail for Prefer scoped temp resources over manual cleanup, Mock child processes with services, streams, and sinks, What to avoid.
