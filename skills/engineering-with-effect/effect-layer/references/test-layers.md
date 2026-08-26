# Test layers

- Allocate fake state in a layer so scope closure defines its lifetime.
- Build a new layer per test when state must be isolated; share a block layer only for intentionally shared expensive setup.
- Retain a backing-state service in the output only when assertions need it. Otherwise hide it behind the service under test.
- Use partial mocks only to prove a narrow path does not use other capabilities; missing methods should fail loudly.
- For scoped resources, test normal release and interruption release.
- For sharing semantics, assert acquisition counts only when sharing itself is the public behavior under test.
