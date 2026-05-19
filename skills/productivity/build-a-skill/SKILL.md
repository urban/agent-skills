---
name: build-a-skill
description: Creates high-quality skill directories from ambiguous ideas. Use when you need to design a new skill, refactor an existing skill, or debug a skill that produces vague or inconsistent results.
---

## Rules

- Build a skill as a directory toolbox, not as a standalone document, because agents need modular resources they can load on demand.
- Keep `SKILL.md` as the entrypoint, not the whole skill, because monolithic skills waste context and are harder to compose.
- Write for agents, not humans, because README-style explanation dilutes triggerability and execution.
- Skip obvious advice and spend tokens on failure-prone decisions, because agents already know generic patterns.
- Redirect the agent away from default habits when those habits would produce a weak skill.
- Use progressive disclosure aggressively: keep core execution in `SKILL.md`, move conditional detail into `references/`.
- Design for loose composition at runtime: make the `description` and `Use when ...` trigger strong enough that an agent can choose the skill without hidden coupling.
- Prefer atomic skills with no skill-to-skill dependencies. If shared guidance is needed, vendor it into local `references/` instead of relying on `metadata.dependencies`.
- Make support files composable. Each script, reference, and asset should stay useful on its own.
- Keep rules and constraints separate because agents follow them differently.

## Constraints

- Output must be a complete skill directory with `SKILL.md` as its required entrypoint.
- The produced `SKILL.md` must be created from [`assets/report-template.md`](./assets/report-template.md).
- Frontmatter and naming must satisfy [`references/frontmatter.md`](./references/frontmatter.md).
- Support-directory and split decisions must follow [`references/resources.md`](./references/resources.md).
- Composition guidance must follow [`references/composability-checklist.md`](./references/composability-checklist.md).
- The produced skill must be atomic: do not depend on other skills, and vendor any reused contract into local bundled resources instead.
- Do not add “helpful” extras that change scope.
- Any missing high-impact detail that changes behavior must be captured as `TODO: Confirm`.
- `Gotchas` is required and should be one of the strongest sections in the skill.

## Requirements

- User intent and trigger conditions (`Use when ...`).
- In-scope and out-of-scope boundaries.
- Expected inputs/outputs (files, formats, APIs, artifacts).
- Failure modes to prevent (hallucination risks, format drift, ambiguity).
- Composition boundaries: what should stay in `SKILL.md`, what should move into `references/`, `scripts/`, or `assets/`, and what should remain independently reusable.

## Workflow

Execute in this order unless the user already provided equivalent inputs. If a step is skipped because inputs already exist, verify the same outcome before continuing.

1. **Gather requirements**

   Ask about:
   - what the skill is for and what should trigger it
   - what is in-scope vs out-of-scope
   - what the inputs and outputs are
   - whether it needs bundled resources
   - which failure modes it must prevent
   - how it should compose with other skills without tight coupling

   If user input is incomplete, mark unknown high-impact details as `TODO: Confirm`.

2. **Draft the skill directory**
   - Start `SKILL.md` from [`assets/report-template.md`](./assets/report-template.md).
   - Apply [`references/frontmatter.md`](./references/frontmatter.md) while drafting frontmatter and naming.
   - Add `references/`, `scripts/`, and `assets/` only when criteria in [`references/resources.md`](./references/resources.md) are met.
   - Apply [`references/progressive-disclosure.md`](./references/progressive-disclosure.md) when deciding what stays in `SKILL.md` versus what moves into `references/*.md`.
   - Vendor any shared contract or borrowed guidance into local bundled resources so the final skill stays atomic.
   - Check composition decisions against [`references/composability-checklist.md`](./references/composability-checklist.md).

   Use these section rules when deciding what stays in the generated `SKILL.md`:

   | Section                    | Include when                                                  | Omit when                        |
   | -------------------------- | ------------------------------------------------------------- | -------------------------------- |
   | optional dispatch section  | The workflow branches or agents need a compact runtime router | The workflow is short and linear |
   | `References`               | Any `references/*.md` file is included                        | No bundled references are needed |
   | `Deterministic Validation` | `scripts/*` exists for validation or transforms that must run | No scripts are bundled           |

3. **Write `Gotchas` early**
   - Add 5–9 gotchas.
   - Write them like post-mortems: specific failure, why it happens, what damage it causes, what to do instead.
   - Prefer experience-derived corrections over abstract “best practices”.
   - Use `Gotchas` to redirect agents away from their normal but wrong patterns.
   - Check the draft against [`references/gotchas.md`](./references/gotchas.md).

4. **Review with user**

   Present the draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more or less detailed?

   If the user refuses details, proceed with a minimal skill and mark assumptions as `TODO: Confirm`.

## Gotchas

- If you explain the skill like a README, agents over-read narrative and under-read triggers. Lead with routing, boundaries, and actions.
- If `SKILL.md` tries to hold everything, future skills duplicate buried rules instead of composing with reusable references or scripts.
- If the `description` is vague, agents cannot select the skill at runtime and authors try to compensate with tighter coupling.
- If you model shared guidance as another skill dependency instead of vendoring the needed contract into local bundled resources, the skill stops being atomic and becomes harder to package, reuse, and route reliably.
- If scripts only work from one cwd or one hard-coded path, agents skip them or misuse them instead of composing them.
- If `Gotchas` only restate generic rules, they do not change behavior. Write them from observed failure patterns.
- If the `References` section in `SKILL.md` lacks specific `Read when:` triggers, agents either load too much or miss the one file that should have redirected them.

## Deliverables

Return a complete, atomic skill directory that is ready to use and follows all section contracts and constraints in this skill.

Required artifacts:

- `SKILL.md` with valid frontmatter and required sections.
- Support directories only when justified by [`references/resources.md`](./references/resources.md).
- Skill folder shape must follow [`references/structure.md`](./references/structure.md).
- Any borrowed contract needed by the skill is vendored locally under bundled resources instead of another skill dependency.
- `Gotchas` with 5–9 specific, actionable, experience-derived items.

## References

- [`assets/report-template.md`](./assets/report-template.md): Read when: drafting or refactoring the entrypoint `SKILL.md` from the canonical template.
- [`references/frontmatter.md`](./references/frontmatter.md): Read when: naming the skill, writing the description, or confirming that the skill stays atomic without cross-skill dependency metadata.
- [`references/resources.md`](./references/resources.md): Read when: deciding whether to add `references/`, `scripts/`, or `assets/`, or how to keep those files composable.
- [`references/structure.md`](./references/structure.md): Read when: shaping the skill as a directory toolbox instead of a single document.
- [`references/progressive-disclosure.md`](./references/progressive-disclosure.md): Read when: deciding what to keep in `SKILL.md` and what to move behind conditional loading.
- [`references/gotchas.md`](./references/gotchas.md): Read when: writing or reviewing the `Gotchas` section so it reads like post-mortems instead of generic warnings.
- [`references/notify-hook.md`](./references/notify-hook.md): Read when: wiring automatic validation after each turn.
- [`references/composability-checklist.md`](./references/composability-checklist.md): Read when: checking whether the skill composes cleanly at runtime without tight coupling.

## Validation Checklist

Before returning:

- Run deterministic validation and confirm it passes.
- `Gotchas` exists and contains 5–9 specific, actionable, post-mortem-style items.
- `References` and `Deterministic Validation` are included only when their conditions apply.
- The skill is atomic and does not rely on other skills for execution-critical guidance.
- The description is strong enough to support runtime selection without relying on cross-skill dependency metadata.
- `Requirements`, `Workflow`, `Gotchas`, and `Deliverables` are concrete enough that an unfamiliar agent can execute without guessing.

## Deterministic Validation

Validate a generated skill directory with:

- `bash scripts/validate-skill.sh <target-skill-dir>`

Codex supports a `notify` command hook that runs after each agent turn and receives a JSON payload. You can use it to run validation automatically. See [`references/notify-hook.md`](./references/notify-hook.md) for a ready-to-use snippet.
