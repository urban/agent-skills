# Composition and runtime ownership

Use an explicit composition root when an executable or independently started runtime must assemble configuration, dependencies, or managed resources. A library made only of ordinary values and pure functions should leave composition to its caller rather than inventing a runtime boundary.

## Composition root

Give each executable or runtime one named composition root. It owns runtime assembly: resolve and validate explicit configuration, select concrete infrastructure, construct the dependency graph, acquire managed resources, and run the complete application flow within their lifetimes.

Keep invocation parsing and result publication at the entrypoint edge, and keep business decisions in domain or application modules. The composition root connects those owners; it does not become another place for policy.

Construct shared dependencies once for a flow. When one invocation makes several application calls, provide the same configured graph around the whole flow rather than rebuilding it per call. Public operations should not select their own production adapters, read hidden global configuration, or open process-lifetime resources internally.

## Modules and ordinary values

Construct and inject a dependency-bearing module when a cohesive capability needs runtime configuration, replaceable infrastructure, shared state, or resource ownership. Keep schemas, immutable domain values, pure policy, comparators, mutation intents, and operation-local or transaction-scoped values as ordinary values and functions unless they have an independent runtime identity.

Do not promote every helper, command, callback, or transaction value into a constructed module. Construction is justified by runtime ownership or a meaningful capability boundary, not by the desire to make all calls look uniform.

## Infrastructure ownership

Apply the same boundary to non-storage infrastructure as to persistence. Concrete adapters own provider protocols, filesystem and process access, network clients, queues, telemetry transports, vendor representations, failure translation, and their acquisition or release semantics. The composition root configures and connects those adapters; application modules depend on narrow caller-meaningful capabilities.

Make lifetime ownership explicit. The adapter defines what acquisition, sharing, freshness, and cleanup mean, while the composition root determines the scope in which that resource is available.

## Public surface

Expose the application capabilities and domain contracts callers need, not the assembled graph. Keep concrete adapters, provider clients, resource constructors, transaction handles, internal configuration shapes, and lifecycle controls behind the runtime boundary.

A public application operation should remain usable with an alternate complete dependency graph. Runtime wiring belongs at the composition edge, so callers do not need internal imports or partial knowledge of how production dependencies are assembled.

## Gotchas

- If each public operation constructs its own dependencies, multi-call flows silently use different configuration, caches, clients, or lifetimes. Assemble once around the complete flow.
- If the composition root contains business branching, alternate entrypoints can bypass policy and wiring becomes difficult to test. Keep the root limited to assembly, lifetime, and invocation.
- If non-storage clients are created ad hoc inside features, provider errors and cleanup leak into application logic. Give their concrete adapters explicit ownership and compose them at the edge.
- If transaction-scoped values become global modules, their valid lifetime is obscured and accidental reuse crosses transaction boundaries. Pass them as ordinary scoped values.
- If concrete adapters or resource handles are public, callers couple to production wiring and cannot replace the application graph cleanly. Export the capability contract while hiding its assembly.
