# Refactoring Signals

Refactor only after tests are green, and keep behavior stable.
These signals assume an Effect codebase that uses public Effect APIs, `Layer` wiring, and tagged errors.

## Common signals

- Repeated `Layer` setup or provisioning logic across tests.
- Multiple `Effect.gen` blocks duplicating the same sequence.
- Repeated ad-hoc error branches that should become tagged errors with `catchTag`.
- Large `Effect.fn` bodies mixing orchestration, validation, and boundary calls.
- Naming or service contracts that hide domain intent.

## Safe sequence

1. Ensure all relevant tests are green.
2. Make one structural change.
3. Re-run tests.
4. Continue only while still green.

## Typical refactor moves

- Extract repeated effectful logic into a named `Effect.fn("...")`.
- Move boundary wiring into `ServiceMap.Service` + static `Layer`.
- Replace untyped failures with `Schema.TaggedErrorClass` errors.
- Collapse branching into focused domain operations with `Effect.catchTag`.
- Use `Effect.acquireRelease` for resource lifecycles instead of manual cleanup.

If tests fail during refactor, either revert that change or re-enter `RED` intentionally with a new behavior test.
