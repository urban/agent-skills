# Engineering Judgment

Engineering skills should improve decisions that automated checks cannot settle. Apply this distinction to both workflow and knowledge/capability skills without changing their section contracts.

## Content filter

For each proposed rule, pattern, example, or gotcha, ask:

- Could code pass the project's automated checks and still make this mistake?
- What domain intent, invariant, boundary, ownership decision, or trade-off must the agent understand to avoid it?
- What context makes the recommendation appropriate, and when would a different choice be better?

Keep guidance with a concrete answer. Drop rules that merely paraphrase diagnostics; rewrite broad advice into a decision with conditions, consequences, and a safer alternative. Do not pad a skill with generic engineering principles when domain-specific judgment is missing.

## Separate judgment from enforcement

| Tool-owned check | Skill-worthy decision |
| ---------------- | --------------------- |
| Unused imports, import ordering, or formatting | Which module should own a dependency, and whether crossing that boundary leaks infrastructure into domain code |
| Missing properties or incompatible types | Whether the model represents valid domain states and where untrusted data must be decoded |
| Floating-promise diagnostics | Whether work must be awaited, supervised, cancelled, or allowed to outlive its caller |
| Required error handling syntax | Which failures are recoverable, who owns recovery, and whether retries can duplicate side effects |
| Naming convention enforcement | Whether names express domain concepts and distinguish states with different business meaning |

Prefer examples where both alternatives compile and lint successfully but differ in correctness, coupling, lifetime, or operational behavior. Syntax may illustrate the choice; it should not be the lesson by itself.

## Preserve useful tooling

- Establish which checks the target project's tools actually enforce when coverage affects the skill's guidance. Do not assume every repository uses the same lint rules or compiler settings; mark unresolved high-impact coverage as `TODO: Confirm`.
- Keep exact validation commands and pass conditions when required by a workflow. Running a linter is useful; narrating every diagnostic it already reports is not.
- Retain a tool-related explanation when a warning exposes a non-obvious semantic issue or choosing a safe fix requires judgment. Explain why the fix preserves behavior rather than merely silencing the warning.
- When a mechanical rule matters but is not enforced, prefer configuring or adding a deterministic check when in scope. If prose is temporarily necessary, identify the enforcement gap rather than presenting it as architectural expertise.
- Do not remove domain or architecture rationale just because tooling enforces part of it. A boundary rule can be automated while choosing the boundary still requires judgment.
- Do not add workflows, deliverables, or validation checklists to knowledge skills merely to accommodate tooling.

## Gotchas

- If a skill says only “handle errors,” an agent can satisfy the type checker while retrying a non-idempotent operation. Teach failure classification, recovery ownership, and retry safety instead.
- If examples demonstrate only valid versus invalid syntax, tooling already distinguishes them and the skill adds little. Show valid alternatives whose semantic consequences differ.
- If “prefer composition” has no decision context, agents apply it everywhere and introduce needless indirection. State the coupling or ownership problem it solves and when a simpler design is sufficient.
- If “the LSP catches it” becomes a reason to omit domain invariants, type-correct code can still violate business rules. Distinguish representational checks from intended behavior.
- If missing lint configuration turns into a long prose checklist, the skill becomes a fragile substitute for enforcement. Address the tooling gap when in scope and reserve skill context for judgment.
