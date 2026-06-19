Use this guide before drafting `SKILL.md`. The archetype controls the template, required sections, and validation contract.

## Archetypes

| Archetype | Choose when | Required shape |
| --------- | ----------- | -------------- |
| Workflow skill | The agent must execute a repeatable procedure, preserve sequence, pass gates, or produce a defined artifact. | `Rules`, `Constraints`, `Requirements`, `Workflow`, `Gotchas`, `Deliverables` |
| Knowledge/capability skill | The agent must apply domain expertise, standards, judgment, patterns, or anti-patterns inside many possible tasks. | `Rules`, `Constraints`, `Knowledge Boundaries`, `Patterns`, `Gotchas` |

## Workflow skill signals

Create a workflow skill when the request includes:

- ordered actions such as gather, inspect, draft, validate, review, publish, or hand off
- a concrete artifact or completion state
- inputs and outputs that must be tracked
- gates, branch points, approvals, or deterministic commands
- a failure mode caused by doing steps in the wrong order

Good workflow-skill examples:

- run a TDD red-green-refactor cycle
- review a pull request
- create a design artifact
- package and validate a release
- extract data into a required schema

## Knowledge/capability skill signals

Create a knowledge/capability skill when the request includes:

- standards the agent should apply while doing other work
- domain vocabulary, invariants, or architecture rules
- language, framework, or library expertise
- preferred patterns and anti-patterns
- judgment calls that do not have one fixed sequence
- a failure mode caused by stale defaults, hallucinated APIs, or misapplied conventions

Good knowledge/capability-skill examples:

- write Effect-native TypeScript
- use a project domain model correctly
- apply repository architecture standards
- model errors with a specific schema convention
- follow a language or framework style guide

## Hybrid requests

Do not create a tangled hybrid by default.

When a request contains both workflow and knowledge:

1. Choose the dominant runtime behavior.
2. Split into two atomic skills if both parts are independently useful and separately triggerable.
3. If one part is secondary, keep the primary archetype in `SKILL.md` and move secondary detail into local `references/`.
4. Ask one clarifying question when the dominant archetype changes the generated section contract.
5. Mark unresolved high-impact uncertainty as `TODO: Confirm`.

Examples:

- “Create a PR review process that checks security conventions” → workflow skill, with security convention details in `references/`.
- “Teach agents our security conventions” → knowledge/capability skill, with examples in `references/` when they are large.
- “Teach agents Effect and how to migrate a service step by step” → likely two skills: a knowledge Effect skill and a workflow migration skill.

## Section contract rules

- Workflow skills own `Workflow` and `Deliverables` because they tell the agent what to do and what to produce.
- Knowledge/capability skills own `Knowledge Boundaries` and `Patterns` because they tell the agent how to judge, choose, and avoid stale habits.
- Do not add top-level workflow sections to knowledge skills unless the user explicitly wants an artifact-producing procedure.
- Do not add top-level knowledge sections to workflow skills; use `references/` for supporting expertise.
- Keep `Gotchas` in both archetypes because both workflows and knowledge skills need concrete failure redirection.

## Gotchas

- If a knowledge skill gets a fake workflow, agents optimize for finishing steps instead of applying judgment in the current task.
- If a workflow skill only lists principles, agents improvise sequencing and skip validation gates.
- If hybrid content is not split or subordinated, the frontmatter trigger becomes vague and agents cannot reliably select the skill.
- If examples dominate `SKILL.md`, the archetype signal gets buried. Move large examples into `references/`.
- If the archetype is guessed silently, future maintainers cannot tell whether missing sections are intentional. Record `TODO: Confirm` when classification is uncertain.
