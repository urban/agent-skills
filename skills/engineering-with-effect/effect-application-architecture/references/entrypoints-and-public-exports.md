# Entrypoint provision and public Effect exports

## Provide the complete entrypoint program

Once an entrypoint adapter has translated an invocation into the public application vocabulary, keep the resulting operations in one Effect program and provide the configured application graph around that complete program. Public access functions must not select or provide their own production Layers.

Providing dependencies separately around each public call can reacquire scoped resources and split one flow across different configuration, clients, caches, or service instances. The composition root owns the intended sharing domain and provision scope.

When several calls are represented by one public operation, its implementation Layer may capture private feature services while exposing only the public capability. Application topology governs that requirement hiding; the framework-neutral decision about where business coordination belongs remains outside this skill.

## Executable runtime bridge

The executable runtime bridge hands the prepared Effect program and Layer graph to the runtime and publishes the terminal process or protocol result. Runtime-specific adapters belong at this edge because it owns the final application scope.

If several executables share most providers, they may reuse a Layer-producing module, but each independently started runtime still has an explicit composition root for its final scope and invocation. Reusable domain and application modules do not import that runtime choice.

## Public Effect surface

Treat the public module root, service requirements, and Layer outputs as one boundary. Supported callers may need:

- canonical domain input and result contracts
- expected error types they can handle
- public service contracts or named Effect operations
- a supported live Layer or parameterized Layer factory for an embedding host
- stable configuration types the host intentionally supplies

Keep private feature services, infrastructure services, concrete provider Layers, transaction handles, resource constructors, and internal configuration out of the public surface unless the caller deliberately owns them.

Not every application needs one public facade or one exported Layer. An embedding host may need several independently useful capabilities, while a closed executable may expose no live Layer outside its composition module. Match Layer outputs and exports to actual caller requirements rather than exposing the assembled graph.

## Close requirement and output leaks

Hiding an internal module path is insufficient when a public operation still requires its service, accepts its representation, or returns its type. Capture private requirements while constructing the public service so downstream operations depend only on intentional caller-supplied capabilities.

Layer output is a second visibility channel. A private service left in the output remains available downstream even if its module is absent from the root barrel. Conversely, a narrow Layer output does not help if public method signatures mention internal types. Close export, requirement, signature, and Layer-output leaks together.

Entrypoint adapters should import public Effect operations and contracts through the supported application root rather than reaching into private feature or infrastructure modules. Public-boundary tests should use that same surface so accidental requirement and export leaks remain observable.
