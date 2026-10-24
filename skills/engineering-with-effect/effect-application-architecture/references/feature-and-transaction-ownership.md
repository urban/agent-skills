# Feature requirements and transaction-scoped values

## Private feature requirements

A private feature service may capture repositories, remote protocol services, clocks, identifiers, or other implementation capabilities when its Layer is constructed. Those requirements build the feature; they do not need to remain in the Layer output or in the requirements of each public method.

Keep provider vocabulary behind the capability that translates it. Infrastructure services expose semantic operations rather than rows, query builders, client handles, or vendor failures. Application topology decides whether a feature capability is private and which requirements its Layer hides; detailed service contracts remain service-level design.

Do not create a service merely because code belongs to a feature. Pure feature policy remains ordinary, and a one-shot Effect operation can declare requirements directly when shared construction or contextual replacement adds no value.

## Transaction-scoped values

One persistence capability should own the database client and complete transaction scope. A transaction-current semantic view supplied to feature policy is usually an ordinary value passed only within the transaction callback. Making that view a globally discoverable service obscures its lifetime and can permit reuse after the transaction closes.

Distinguish an application transaction view from a persistence driver's transaction propagation. Effect's `SqlClient.withTransaction` uses a client-specific transaction service internally so statements share the current connection and nested transactions can use savepoints. That does not justify publishing a transaction handle in the application graph or capturing it in a long-lived feature.

When a framework protocol deliberately requires contextual operation-local state, provide it only inside the owning scope. Contextual discoverability does not extend validity or prevent an escaped value or closure from retaining an expired handle.

A Layer can own the client or pool used to start transactions without turning an individual transaction handle into an application-wide capability. Consistency, commit uncertainty, retry, and transaction-versus-workflow policy belong to framework-neutral architecture guidance.

## Other scoped resources

The Layer constructing a client, pool, process, subscription, server, or exporter owns acquisition and release. The composition root chooses the enclosing provision scope and sharing domain, while feature services consume semantic capabilities rather than managing raw handles.

A background loop likewise needs an explicit lifetime and shutdown owner; detaching it from the caller does not assign it to the application. Attach service-owned work to the resource scope or host runtime that must stop it before releasing its dependencies, without exposing the concrete fiber as public application output.

If a public operation returns a raw handle or transaction session, lifecycle responsibility has moved to the caller. Make that transfer only when handle control is intentionally part of the public capability.
