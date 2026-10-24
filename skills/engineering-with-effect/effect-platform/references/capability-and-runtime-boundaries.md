# Capability and runtime boundaries

## Capture or expose requirements

Capture platform services during domain-service construction when storage, paths, crypto, or processes are implementation details. For example, a report repository can capture `FileSystem` and `Path` but expose reports and repository failures, not file descriptors. Test consumers with a fake repository; test the filesystem-backed implementation against filesystem semantics.

Leave platform requirements explicit for reusable helpers whose purpose is filesystem or process manipulation. Wrapping every platform call in a domain service adds indirection without creating a meaningful boundary.

## Runtime edges

Capability definitions are in `effect`; process command descriptions and spawning are under `effect/process`. Runtime packages supply implementations. `NodeServices.layer`, `BunServices.layer`, and `DenoServices.layer` provide filesystem, paths, crypto, child processes, stdio, and terminal services. They do not provide every transport or server: select those layers separately.

Choose only capabilities the deployment supports. Browser adapters are not substitutes for an OS filesystem or child-process service. Dynamic selection is appropriate only when one deployed artifact genuinely supports multiple runtimes; runtime-specific static imports can still make a supposedly portable bundle unloadable.

A shared interface also does not erase host semantics. Choose host-native path behavior for host files, or explicit POSIX behavior for a portable path format. `Path.resolveWithin` checks lexical containment, not symlinks or filesystem races; it is not a security sandbox.

## Application lifetime versus service provision

A services layer supplies capabilities; it does not install the host's shutdown policy. A standalone Node program typically composes them separately:

```ts
import { NodeRuntime, NodeServices } from "@effect/platform-node"
import { Effect, FileSystem } from "effect"

const main = Effect.gen(function*() {
  const fs = yield* FileSystem.FileSystem
  const text = yield* fs.readFileString("message.txt")
  yield* Effect.log(text)
})

NodeRuntime.runMain(main.pipe(Effect.provide(NodeServices.layer)))
```

`NodeRuntime.runMain` interrupts the main fiber on SIGINT/SIGTERM and translates completion to a process exit policy. Do not terminate the host inside a reusable capability: let its failure reach the application's boundary so scoped finalizers can run. Code embedded in another host must respect that host's lifetime rather than install another process-level main runner.

Browser shutdown differs: `BrowserRuntime.runMain` interrupts on non-persisted `pagehide`, but asynchronous finalization is best-effort. Persist important state during normal operation rather than relying on page teardown.
