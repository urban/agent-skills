---
name: brainstorming
description: Run collaborative design discovery and converge on one approved design artifact. Use when a request changes behavior, introduces a feature, or adds components with unresolved design decisions.
---

## Rules

- Keep this skill design-only because implementation and execution planning belong elsewhere.
- Ask one clarifying question per turn during discovery because multi-question dumps lower answer quality.
- Prefer multiple-choice questions when they reduce user effort without hiding important nuance.
- Review local repository context before recommending a final design when code, docs, or integrations already constrain the solution.
- Compare 2-3 viable approaches before converging because unchallenged first ideas drift into accidental decisions.
- Record trade-offs explicitly for complexity, risk, flexibility, and delivery speed.
- Resolve and preserve one stable `<artifact-name>` for the whole run.
- Apply [`references/artifact-naming.md`](./references/artifact-naming.md) when deriving, normalizing, or preserving `<artifact-name>`.
- Write the final artifact from [`assets/design-template.md`](./assets/design-template.md) and keep only the approved solution in it.
- Mark any unresolved high-impact detail as `TODO: Confirm` instead of smoothing it over.

## Constraints

- Do not write code, scaffolds, or implementation plans.
- Do not skip repository review unless the user forbids local inspection.
- Final output must be one file at `docs/ideas/<artifact-name>-design.md`.
- The design file must preserve the section order from [`assets/design-template.md`](./assets/design-template.md).
- Final frontmatter in the design file must include `name`, `created`, and `updated`.
- Keep `created` fixed to the original draft date and update `updated` on every approved revision.

## Requirements

Inputs:

- user request that needs design discovery
- scope boundaries, constraints, and success criteria when known
- local repository evidence when existing code or docs affect the design
- user feedback on alternatives and draft sections

Outputs:

- one approved design artifact at `docs/ideas/<artifact-name>-design.md`
- explicit `TODO: Confirm` markers for unresolved high-impact decisions

In scope:

- clarifying ambiguous feature or system requests
- comparing candidate approaches and recommending one
- drafting and revising the approved design artifact

Out of scope:

- code changes
- task breakdowns
- release planning
- documenting rejected options inside the final artifact

Failure modes to prevent:

- inventing constraints instead of inspecting the repo
- converging on the first idea without comparing alternatives
- letting rejected options leak into the saved design
- hiding missing decisions behind polished prose

## Workflow

1. Confirm this is a design-discovery task, not direct implementation.
2. Resolve `<artifact-name>` with [`references/artifact-naming.md`](./references/artifact-naming.md) and keep it stable for the run.
3. Inspect relevant repository files, docs, and recent changes when local context can constrain the design.
4. Run discovery one question at a time until problem, scope, constraints, and success criteria are explicit or marked `TODO: Confirm`.
5. Present 2-3 viable approaches with concrete trade-offs and recommend one.
6. Validate the selected direction section by section: `Solution`, `Architecture and Components`, `Data Flow`, `Error Handling`, and `Testing Decisions`.
7. Write `docs/ideas/<artifact-name>-design.md` from [`assets/design-template.md`](./assets/design-template.md) using only the approved solution plus any remaining `TODO: Confirm` items.
8. Re-check frontmatter dates and section completeness before handoff.

## Gotchas

- If you ask several discovery questions at once, users answer the easiest part and leave the risky ambiguity untouched. Ask one question, absorb the answer, then route the next question from what changed.
- If you skip repository review because the request sounds familiar, the design drifts from real constraints like existing APIs, naming, or deployment assumptions. Inspect the local evidence before locking the recommendation.
- If you present only one option, the discussion turns into defending your first draft instead of making a decision. Always compare 2-3 viable paths with explicit trade-offs.
- If rejected alternatives stay in the saved document, later readers treat them like half-approved scope and implementation starts arguing with the artifact. Keep final files limited to the approved solution.
- If `TODO: Confirm` items get rewritten as confident prose, downstream work inherits guesses as facts and the error gets harder to unwind. Leave uncertainty visible where it changes behavior or scope.
- If `<artifact-name>` changes mid-run, review notes and follow-on work split across mismatched paths. Resolve the name once and preserve it for every revision.

## Deliverables

- a reviewed design decision process with explicit alternatives and a recommendation
- `docs/ideas/<artifact-name>-design.md` written from [`assets/design-template.md`](./assets/design-template.md)
- final artifact containing only the approved solution and any remaining `TODO: Confirm` markers

## References

- [`references/artifact-naming.md`](./references/artifact-naming.md): Read when: deriving a new `<artifact-name>`, reusing an existing artifact basename, or normalizing the final design filename.

## Validation Checklist

- trigger was a design-discovery request rather than implementation-only work
- repository constraints were inspected when local context mattered
- 2-3 viable approaches were compared with explicit trade-offs
- final artifact path is `docs/ideas/<artifact-name>-design.md`
- final artifact preserves the template section order
- final artifact includes `name`, `created`, and `updated` frontmatter fields
- rejected alternatives are excluded from the saved design
- unresolved high-impact details remain marked `TODO: Confirm`
