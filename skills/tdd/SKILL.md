---
name: tdd
description: Run deliberately selected red-green-refactor cycles for Effect services and public APIs. Use when the user explicitly requests TDD/test-first work, or a bug has an obvious cheap local regression target; ordinary feature work does not automatically require this mode.
---

## Rules

- Select a small caller-visible behavior and the narrowest existing practical executable check.
- Within a selected TDD cycle, write the failing test before production code, confirm the intended failure, make the smallest green change, then refactor.
- Exercise the production capability with real internal collaborators; supply genuine external dependencies through services and Layers.
- Derive expected results and typed failures from requirements rather than the implementation under test.
- Re-run the focused check after meaningful changes, then run the task's stated completion checks and mandatory project gates.

## Constraints

- Do not treat every feature request or desire for safer delivery as a request for strict TDD.
- Do not build broad harnesses, brittle mocks, slow end-to-end infrastructure, or unrelated fixtures solely to obtain a red-green trail.
- Do not batch all tests first and implementation later within a selected cycle, or mix refactoring into the red step.
- Do not assert private methods, incidental call order, or interaction counts unless they are the observable contract.
- Do not claim a failing-then-passing cycle without demonstrating it. When a practical failing-first path is unavailable, report that limit and the closest useful verification instead.
- Use this skill for Effect-oriented codebases that expose services, Layers, or public Effect APIs.

## Requirements

Inputs:

- selected behavior or bug, its intended outcome, and the public Effect interface
- an existing practical test target or executable reproduction
- stated completion checks and required project gates

In scope: deliberate red-green-refactor work, cheap behavior-first regression tests, and post-green refactoring.

Out of scope: universal test-first mandates, implementation-detail tests, coverage targets, broad benchmarking, and creating an expensive test environment for a small fix.

When available, use `principle-test-capabilities` for test boundaries, production composition, substitute fidelity, and evidence selection; this skill owns the selected red-green-refactor cycle. Resolve the companion skill by name through host discovery.

Read only the reference owning the current question:

| Question | Reference |
| --- | --- |
| Does this test establish behavior? | [Test quality](references/test-quality.md) |
| Which dependencies may be replaced? | [Mocking boundaries](references/mocking-boundaries.md) |
| Which cleanup is useful after green? | [Refactoring signals](references/refactoring-signals.md) |
| Is the interface making tests unnecessarily hard? | [Interface design](references/interface-design.md) |

## Workflow

1. Confirm the selected behavior and choose the smallest existing executable reproduction. If a practical red-green path is unavailable, use the closest useful check and state the limit; do not manufacture a harness to satisfy the mode.
2. Run `RED`: write one focused test and confirm it fails because of the intended missing or broken behavior. Fix setup noise before proceeding.
3. Run `GREEN`: implement the smallest change satisfying that behavior while preserving neighboring contracts.
4. Run `REFACTOR`: improve structure after green and rerun the relevant check after meaningful changes.
5. Repeat for remaining selected behaviors, then run the stated completion checks and mandatory project gates. Broaden only for a distinct newly exposed risk or failure; a fresh reviewer does not create another acceptance bar.

## Gotchas

- If the red test fails because of setup rather than the behavior gap, the cycle chases the harness. Correct the reproduction until its failure identifies the real defect.
- If one cycle bundles unrelated behaviors, the green step becomes a speculative rewrite. Choose a coherent observable change.
- If internal services are all replaced, the suite proves fixture agreement rather than production behavior. Keep internal composition real and replace genuine external uncertainty.
- If expected values are computed by the implementation, the same defect can make both agree. Use requirement-derived examples.
- If refactoring starts during red, diagnosis and redesign become indistinguishable. Reach green before changing structure.
- If a tiny fix requires slow end-to-end setup just to satisfy TDD, the workflow costs more than its evidence. Use a narrower existing check and disclose any missing fail-before proof.

## Deliverables

- focused public-behavior tests and corresponding production changes
- the intended failing-before and passing-after results, or an explicit limit with the closest executable evidence
- stated completion-check results, residual acceptance gaps, and deferred scope

## References

- [Test quality](references/test-quality.md): Read when: deciding whether a test proves behavior or mirrors implementation.
- [Mocking boundaries](references/mocking-boundaries.md): Read when: choosing which external dependency to supply.
- [Refactoring signals](references/refactoring-signals.md): Read when: selecting useful cleanup after green.
- [Interface design](references/interface-design.md): Read when: the public interface makes a focused behavior hard to exercise.
