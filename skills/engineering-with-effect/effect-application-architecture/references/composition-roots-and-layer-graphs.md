# Composition roots and Layer graphs

## Translate dependency direction

Domain and application source dependencies point toward capabilities they consume. The provider graph runs in the other direction: infrastructure Layers construct low-level capabilities, feature Layers consume them, and public facade Layers consume the private features they hide.

A typical topology is:

```text
runtime adapters + validated configuration
                  ↓
infrastructure capability Layers
                  ↓
private feature Layers
                  ↓
public application Layer
                  ↓
entrypoint program
```

Pure domain modules do not appear in the Layer graph merely because feature implementations import them. A source import is not automatically a runtime requirement.

Compose by actual requirements and outputs. Use `Layer.provide` to satisfy construction dependencies without publishing them; retain them with `Layer.provideMerge` only when another intentional consumer needs them. Hiding a dependency from the output does not release it early: captured resources must remain alive for the consuming capability's lifetime.

## Composition boundaries

Give each runtime ownership and sharing domain an explicit, identifiable composition boundary. A conventional server, worker, or command process usually has a named root. Framework-hosted, reactive, command-dispatched, request-, tenant-, or job-scoped applications may combine an outer root with nested or lazily selected graphs. Complete means complete for that ownership domain, not every graph in the executable. A library of ordinary values should leave runtime composition to its host.

The boundary owns:

- resolving runtime configuration at the appropriate composition or adapter edge
- selecting concrete infrastructure and runtime adapters
- constructing the configured graph for its ownership domain
- opening or receiving the scope that owns its resources
- providing that graph around the operations which share it
- publishing or handing off terminal results at the runtime edge when applicable

It does not own domain transitions, authorization policy, protocol rendering, retry decisions, or feature orchestration.

Construct long-lived dependencies once per intended sharing domain. If one entrypoint flow invokes several public operations, provide the same graph around that flow rather than separately around each call. Use nested graphs when request-, run-, tenant-, job-, subscription-, or framework-owned lifetimes need distinct identity and release.

## Invocation selection and activation

Choose the activation boundary by which execution paths need the resource graph. Handler-only diagnostics usually belong after successful parsing and invocation selection, around the complete selected invocation. Resources needed by parsing or dispatch need an earlier owner. A short-lived process does not make process and handler lifetimes interchangeable.

For an Effect CLI, `Command` from `effect/cli` provides a handler boundary that can derive a Layer from parsed input. Apply `Command.provide` after assembling the command tree:

```ts
const commandTree = rootCommand.pipe(
  Command.withSubcommands([firstCommand, secondCommand]),
  Command.provide(({ debug }) => conditionalTelemetryLayer(debug))
)
```

Here `conditionalTelemetryLayer` resolves activation effectfully and selects the resource recipe. Static dependencies needed for that resolution can remain in the outer graph. Help, version, completion, and parse-failure paths should bypass handler-only activation and acquisition; placing the feature around the whole CLI runner would include those paths. CLI APIs and dispatch behavior can change: confirm the installed implementation and use the public runner when establishing that bypass.

Source anchors: `packages/effect/src/cli/Command.ts` (`provide`, `mapHandler`, `runWith`); `packages/effect/test/cli/Command.test.ts`.

## Configuration and dependency hiding

Resolve environment, files, flags, deployment metadata, or host values at a composition or adapter edge. Use explicit validated values or typed `Config` consumed during Layer construction. A feature should receive the resulting capability rather than repeatedly consult an ambient source during its operations.

When explicit input is authoritative, preserve absence separately from an explicit `false` and avoid evaluating an unused fallback. For a parsed optional boolean and an existing fallback-reading Effect:

```ts
const resolveActivation = (explicit: boolean | undefined) =>
  explicit !== undefined ? Effect.succeed(explicit) : readDebugFallback
```

This policy lets an explicit choice bypass invalid fallback configuration. Eagerly reading both sources can reject an otherwise valid invocation. If fallback configuration must be validated regardless of overrides, make that a separate validation policy rather than treating it as necessary to resolve activation.

Configuration belongs in the public application contract only when the embedding caller must choose it. Even then, expose the smallest stable configuration required to construct the supported public Layer; keep provider-specific credentials, client options, and migration controls behind infrastructure constructors when callers do not need them.

Capture common implementation dependencies once during Layer construction. A composition boundary may build a provider family or scoped router: validated input or application policy may select an already-wired capability or a bounded identity-specific child graph. Feature operations must not construct ad hoc long-lived production adapters or repeatedly reacquire shared resources.

## Lifetime alignment

The composition boundary opens or receives a scope; resource constructors used by Layers register release with that scope. A Layer value is a construction recipe, not an already running resource container. Align each resource with the narrowest correct sharing domain:

- application-wide pools, exporters, and supervised infrastructure live in the application scope
- tenant- or configuration-specific clients live with that identity
- request or job resources live in the corresponding nested scope
- transaction values live only inside the transaction owner's callback

Scope ownership and instance identity are separate decisions. Within a shared memoization domain, reusing a Layer value shares its construction; separate runtimes normally have separate memo maps. Reconstructing equivalent Layer values can duplicate resources, while opening a nested scope alone does not guarantee a new instance. Make tenant or configuration identity explicit in the graph rather than expecting a scope to replace a dependency already captured by a parent service.
