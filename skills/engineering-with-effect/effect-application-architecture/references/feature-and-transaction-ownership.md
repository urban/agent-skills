# Feature requirements and transaction-scoped values

## Private feature requirements

A private feature service may capture repositories, remote protocol services, clocks, identifiers, or other implementation capabilities when its Layer is constructed. Those requirements build the feature; they do not need to remain in the Layer output or in the requirements of each public method.

Keep provider vocabulary behind the capability that translates it. Infrastructure services expose semantic operations rather than rows, query builders, client handles, or vendor failures. Application topology decides whether a feature capability is private and which requirements its Layer hides; detailed service contracts remain service-level design.

Do not create a service merely because code belongs to a feature. Pure feature policy remains ordinary, and a one-shot Effect operation can declare requirements directly when shared construction or contextual replacement adds no value.

## Transaction-scoped values

One persistence capability should own the database client and complete transaction scope. A transaction-current semantic view supplied to feature policy is usually an ordinary value passed only within the transaction callback. Making that view a globally discoverable service obscures its lifetime and can permit reuse after the transaction closes.

Leave a transaction value contextual only when caller-supplied transaction context is a deliberate and enforced application contract. If it is contextual, its provider must be nested inside the transaction scope rather than included in the long-lived application Layer.

Concurrency-sensitive decisions still need transaction-current observations. The persistence owner must:

- establish the consistency or writer position required by the operation
- read and decode authoritative domain facts
- run the decision against those current facts
- apply semantic writes only for the chosen commit branch
- return only the durable meaning guaranteed by the transaction abstraction

A preview or pre-transaction read can inform presentation but does not reserve state and must not replace the transaction-current decision.

Do not keep the transaction scope open across remote calls, durable waits, human interaction, or other long-running work. A Layer can own the client or pool used to start transactions without turning an individual transaction handle into an application-wide capability.

Unknown commit outcome is not evidence of rollback. The persistence capability must preserve enough information for the application to reread authoritative state and reconcile the logical operation before retrying.

## Other scoped resources

The Layer constructing a client, pool, process, subscription, server, or exporter owns acquisition and release. The composition root chooses the enclosing provision scope and sharing domain, while feature services consume semantic capabilities rather than managing raw handles.

A detached fiber or background loop likewise needs an explicit scope, supervisor, and shutdown owner. Keep these ownership decisions visible in the provider graph without exposing the concrete resource as part of the public application output.

If a public operation returns a raw handle or transaction session, lifecycle responsibility has moved to the caller. Make that transfer only when handle control is intentionally part of the public capability.
