# Optimistic updates, React, and tests

Keep query, mutation, derived, and optimistic atoms near the owning client/capability. Components read values, render lifecycle, refresh, and dispatch actions.

An optimistic mutation needs decisions for:

- reducer from current state and input
- rollback or refetch after failure
- concurrent overlapping mutations
- server-normalized response
- invalidation/reactivity keys

Use promise/exit-style dispatch when UI branches on success or typed failure without exception-driven event handlers.

Test through an Atom registry or provider. Seed values or replace runtime layers, mount atoms when lifecycle/subscription matters, and assert Initial/Success/Failure/waiting plus isolation across family keys. Drive delayed Effects with the Effect test clock in the runtime that executes them.
