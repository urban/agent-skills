# Entrypoint provision and public Effect exports

## Provide by ownership domain

Once an entrypoint adapter has translated an invocation into the public application vocabulary, provide long-lived dependencies around the complete program or set of operations that share them. Public access functions must not select fixed production adapters or rebuild the long-lived application graph.

Providing shared dependencies separately around each public call can reacquire scoped resources and split one flow across different configuration, clients, caches, or service instances. Bounded request-, run-, tenant-, job-, subscription-, or framework-owned capabilities may instead be provided inside their explicit nested scope.

When several calls are represented by one public operation, its implementation Layer may capture private feature services while exposing only the public capability. Application topology governs that requirement hiding; the framework-neutral decision about where business coordination belongs remains outside this skill.

## Runtime bridge

A conventional executable bridge hands the prepared Effect program and graph to the runtime and publishes the terminal process or protocol result. A framework-hosted or reactive application may instead establish an outer registry or host lifetime while nested graphs serve mounted features or invocations. Runtime-specific adapters belong at the edge that owns their scope.

Several runtimes may reuse a Layer-producing module while retaining distinct composition boundaries for their final ownership domains. Reusable domain and application modules do not import those runtime choices.

## Public Effect surface

Audit publicness through distinct channels:

- source-level TypeScript exports used among internal modules
- paths reachable through package export maps and build outputs
- documented entrypoints whose compatibility supported callers may rely on
- service requirements, method signatures, and Layer outputs visible to Effect consumers

Supported callers may need canonical domain contracts, expected error types, public service contracts or named Effect operations, a supported Layer for an embedding host, and stable configuration types the host intentionally supplies. Keep private feature services, concrete adapters, provider clients, transaction handles, resource constructors, and internal configuration out of those channels unless the caller deliberately owns them.

Not every TypeScript export is supported API, and omission from a root barrel is not access control when a build or export map exposes the path. Not every application needs one public facade or one exported Layer: an embedding host may need several capabilities, while a closed executable may expose no supported Layer. Match each visibility channel to actual caller requirements rather than exposing the assembled graph.

## Close requirement and output leaks

Hiding an internal module path is insufficient when a public operation still requires its service, accepts its representation, or returns its type. Capture private requirements while constructing the public service so downstream operations depend only on intentional caller-supplied capabilities.

Layer output is another visibility channel. A private service left in the output remains available downstream even when absent from the root barrel. Conversely, a narrow Layer output does not help if public method signatures mention internal types. Close package reachability, documented support, requirements, signatures, and Layer-output leaks together.

At an actual supported package boundary, entrypoint adapters and public-boundary tests should import through documented application entrypoints so accidental leaks remain observable. Closed executables and unpublished examples may intentionally use direct internal imports; do not mistake those imports for a compatibility contract.
