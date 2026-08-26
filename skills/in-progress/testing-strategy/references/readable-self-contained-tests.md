# Readable self-contained tests

## Keep the scenario local

A self-contained test keeps behavior-relevant context local, not every mechanical detail. Its name and body should make these elements clear without requiring the reader to reconstruct distant setup:

- the behavior or rule under test
- the values and state that cause or distinguish the behavior
- the action being performed
- the independently stated expected outcome
- any boundary observation needed as evidence

Prefer straight-line code with a visible arrange, act, and assert relationship. Use multiple assertions when they jointly establish one behavior; do not split a coherent outcome merely to satisfy an assertion count.

## Repeat scenarios, extract mechanics

Controlled repetition is preferable when extraction would hide the causal details of a scenario. Keep the test's **what** local and extract only the **how** when doing so improves readability.

Reasonable extraction targets include:

- environment startup and guaranteed cleanup
- verbose protocol-harness plumbing
- temporary resource management
- valid-object construction whose details are irrelevant
- a focused assertion that requires distracting matching or iteration

Wait until a stable abstraction is visible. Do not extract code merely because several tests currently contain similar lines.

## Helper contracts

A test helper should:

- have a narrow, domain-oriented name
- accept behavior-relevant values explicitly
- return fresh state rather than mutate shared fixtures
- avoid flags or conditional branches that select different scenarios
- stay near its callers unless it is genuinely reusable infrastructure

If a helper's behavior must be inspected to understand why a test passes, the helper hides too much. Inline it, split it, or replace it with a more descriptive operation.

Use setup and teardown hooks for lifecycle obligations such as guaranteed cleanup or suite-owned resources, not as the default mechanism for sharing business context.

## Test data

Use builders or factories with valid defaults to hide irrelevant construction. Override every value that explains why the scenario behaves differently, and keep those overrides visible in the test.

Avoid broad named fixtures whose defaults silently become part of the scenario. Construct fresh mutable data for each test unless shared state is explicitly the behavior under test.

## Parameterized examples

Use a table when every row demonstrates the same rule. Each row should have:

- a diagnostic case name
- explicit inputs
- a literal expected result

Keep the test runner branch-free. Split rows into separate tests when cases require different setup, actions, or assertion logic.

## Oracle integrity

Prefer expectations that are simpler and independent from the implementation:

- state literal expected values instead of recomputing them with production logic
- avoid loops and conditionals that make an example difficult to verify by inspection
- reject tests that swallow failures, assert only that execution completed, or prove a tautology
- confirm that a new test would fail when the intended behavior is broken
- use targeted mutation testing for critical rules when ordinary review cannot establish assertion sensitivity
