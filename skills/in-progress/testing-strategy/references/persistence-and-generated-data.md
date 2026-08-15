# Persistence and generated data

## Persistence fidelity

Choose a persistence substitute from the semantics under test:

| Behavior | Suitable evidence |
| --- | --- |
| Application branching independent of storage details | Focused fake adapter |
| Mapping rows and database errors | Adapter test against local database |
| Constraints, joins, ordering, migrations, transactions | Real local database engine |
| Dialect, locking, isolation, or extension behavior | Same engine/version family as production when practical |

SQLite is useful when the application uses SQLite or when ordinary relational semantics are sufficient. It is not a universal stand-in for PostgreSQL, MySQL, or another engine when dialect, isolation, locking, extensions, or type behavior matter.

Keep each test isolated through transactions, schemas, databases, containers, or deterministic cleanup according to engine behavior. Assert through the public persistence/application surface unless direct database inspection is the behavior being verified.

## Test-data construction

Tests should create domain values through production parsers, smart constructors, builders that call those constructors, or schema-derived arbitraries. A cast-based fixture can construct an illegal state and make both success and failure assertions meaningless.

Keep small canonical examples for readability. Use property-based generation when a named law applies across a broad input or transition space, such as:

- parser/encoder round trip
- normalization idempotence
- state-machine invariant preservation
- ordering or monotonicity
- serialization compatibility

Ground each law in a public contract, domain invariant, documented behavior, real usage, or known regression. Reject tautological or vacuous properties, confirm generated values belong to the intended domain, and verify that a counterexample represents a real contract violation rather than an invalid assumption.

Generate valid values directly. Generate invalid categories deliberately when testing rejection. Avoid filtering arbitrary values until only a tiny fraction survive, because shrinking and coverage both degrade.

Colocate a domain-specific arbitrary near the domain module when that placement matches repository organization and multiple tests reuse it. Do not export test-only generators from the production public package surface solely for convenience; use a test-support entrypoint or local test module when appropriate.
