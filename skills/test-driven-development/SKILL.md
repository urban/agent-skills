---
name: test-driven-development
description: Drive Effect-based feature and bug work through strict red-green-refactor cycles with behavior-first tests over public interfaces. Use when a user asks for test-first implementation, safer incremental delivery, or explicit TDD workflow in an Effect codebase.
---

## Rules

- Work in one behavior slice at a time because batched TDD hides failure cause and encourages speculative code.
- Write the next failing test before production code for that slice.
- Exercise public Effect interfaces and caller-visible outcomes instead of private implementation details.
- Prefer real collaborators inside the codebase; mock only true system boundaries.
- Keep each green step minimal and refactor only after tests pass.
- Re-run the smallest relevant test command first, then broaden verification as risk grows.
- Record missing high-impact scope or acceptance detail as `TODO: Confirm` before continuing.

## Constraints

- Do not batch all tests first and implementation later.
- Do not write speculative production code for behaviors without a failing test.
- Do not assert private methods, internal call order, or incidental interaction counts unless explicitly required.
- Do not refactor while tests are red.
- Do not claim completion without a failing-then-passing cycle for each delivered behavior.
- Use this skill only for Effect-oriented codebases that expose services, layers, or public Effect APIs.

## Requirements

Inputs:

- target behavior or bug to implement
- public Effect interface that should prove the behavior
- relevant test command for the repo and any scoped variant
- completion boundary for this task

Outputs:

- failing-first tests that now pass
- production code changes driven by those tests
- explicit deferred work and `TODO: Confirm` items

In scope:

- strict red-green-refactor execution
- behavior-first test design for Effect codebases
- post-green refactoring that preserves behavior

Out of scope:

- implementation-detail testing as the default strategy
- non-Effect testing guidance for unrelated stacks
- broad benchmarking or property-testing strategy work

Failure modes to prevent:

- a red test fails for the wrong reason
- one cycle bundles multiple behaviors
- mocks replace real in-process collaborators
- refactors change behavior without immediate re-verification

Routing guidance:

| Task                                                              | Read first                                                                 |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Decide whether a test is behavior-first or implementation-coupled | [`references/test-quality.md`](./references/test-quality.md)               |
| Choose where mocking is valid                                     | [`references/mocking-boundaries.md`](./references/mocking-boundaries.md)   |
| Identify safe refactors after green                               | [`references/refactoring-signals.md`](./references/refactoring-signals.md) |
| Simplify an interface for better tests                            | [`references/interface-design.md`](./references/interface-design.md)       |

TODO: Confirm

- preferred test level split for this repo
- whether unrelated pre-existing failures block completion
- whether coverage thresholds matter for this task

## Workflow

1. Confirm this is TDD work in an Effect codebase and record any blocking unknowns as `TODO: Confirm`.
2. Align on the next caller-visible behavior and the public Effect interface that should prove it.
3. Choose the smallest tracer bullet that demonstrates progress.
4. Run `RED`: write one test for one behavior and confirm it fails for the intended reason.
5. Run `GREEN`: make the smallest production change needed to pass that test.
6. Run `REFACTOR`: clean naming, duplication, or structure only after green, re-running tests after each meaningful change.
7. Repeat one behavior slice at a time until the requested scope is complete.
8. Run final verification and report delivered behaviors, deferred work, residual risks, and remaining `TODO: Confirm` items.

## Gotchas

- If the first failing test breaks because of setup noise instead of the intended behavior gap, the cycle gives false confidence and the production change chases the wrong problem. Fix the test setup until the failure names the real missing behavior.
- If one test covers several behaviors, the next green step balloons into a design session and you lose the tracer-bullet safety TDD is supposed to give you. Split the slice until one failing test points to one user-visible outcome.
- If you assert internals like call counts or private sequencing, harmless refactors start breaking tests and the suite resists cleanup. Move assertions back to observable outcomes through the public interface.
- If you mock inside the codebase instead of only at true boundaries, tests pass against a fake architecture that production never uses. Prefer real collaborators until the boundary crosses process, network, time, or external state.
- If you refactor during red, you mix diagnosis with redesign and can no longer tell whether the break came from the feature or the cleanup. Get to green first, then change structure.
- If you stop after focused tests only, wider regressions hide in adjacent flows and show up later as “unexpected” fallout. Broaden verification before handoff based on the risk of the change.

## Deliverables

- behavior-first tests that prove each completed slice through public Effect interfaces
- corresponding production changes with no speculative extra scope
- a handoff summary covering delivered behaviors, deferred work, risks, and `TODO: Confirm` items

## References

- [`references/test-quality.md`](./references/test-quality.md): Read when: deciding whether a planned test proves behavior or only mirrors implementation.
- [`references/mocking-boundaries.md`](./references/mocking-boundaries.md): Read when: deciding whether a collaborator should stay real or be replaced at a true boundary.
- [`references/refactoring-signals.md`](./references/refactoring-signals.md): Read when: choosing which cleanup is safe after green.
- [`references/interface-design.md`](./references/interface-design.md): Read when: the public interface shape is making behavior-first tests harder than it should be.

## Validation Checklist

- task is an Effect-oriented TDD request
- workflow enforces one behavior per red-green-refactor cycle
- tests target public interfaces and caller-visible outcomes
- mocks are limited to true system boundaries
- each delivered behavior has a failing-then-passing trail
- unresolved high-impact details are marked `TODO: Confirm`
- references include explicit `Read when:` triggers
