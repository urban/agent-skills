---
name: build-a-skill
description: Creates high-quality workflow skills or knowledge/capability/domain-expertise skills from ambiguous ideas, using the appropriate archetype template. Use when you need to design a new skill, refactor an existing skill, or debug a skill that produces vague or inconsistent results.
---

## Rules

- Classify the requested skill as either a workflow skill or a knowledge/capability skill before choosing a template, because each archetype needs a different runtime shape.
- Build a skill as a directory toolbox, not as a standalone document, because agents need modular resources they can load on demand.
- Keep `SKILL.md` as the entrypoint, not the whole skill, because monolithic skills waste context and are harder to compose.
- Write for agents, not humans, because README-style explanation dilutes triggerability and execution.
- Skip obvious advice and spend tokens on failure-prone decisions, because agents already know generic patterns.
- Redirect the agent away from default habits when those habits would produce a weak skill.
- Use progressive disclosure aggressively: keep core execution or core knowledge in `SKILL.md`, move conditional detail into `references/`.
- Design for loose composition at runtime: make the `description` and `Use when ...` trigger strong enough that an agent can choose the skill without hidden coupling.
- Prefer atomic skills with no skill-to-skill dependencies. If shared guidance is needed, vendor it into local `references/` instead of relying on `metadata.dependencies`.
- Make support files composable. Each script, reference, and asset should stay useful on its own.
- Keep rules and constraints separate because agents follow them differently.
- Do not force workflow sections onto knowledge skills; domain expertise should teach standards, boundaries, patterns, and anti-patterns without inventing deliverables.
- Do not hide an ordered procedure inside a knowledge skill; if the agent must execute steps in sequence, make it a workflow skill.
- Do not create a separate `Validation Checklist` section in generated skills; put subjective quality criteria in `Deliverables` for workflow skills and executable checks in `Deterministic Validation` when scripts exist.

## Constraints

- Output must be a complete skill directory with `SKILL.md` as its required entrypoint.
- The produced `SKILL.md` must be created from the template that matches the selected archetype:
  - workflow skills use [`assets/workflow-skill-template.md`](./assets/workflow-skill-template.md)
  - knowledge/capability skills use [`assets/knowledge-skill-template.md`](./assets/knowledge-skill-template.md)
- Archetype classification must follow [`references/skill-archetypes.md`](./references/skill-archetypes.md).
- Frontmatter and naming must satisfy [`references/frontmatter.md`](./references/frontmatter.md).
- Support-directory and split decisions must follow [`references/resources.md`](./references/resources.md).
- Composition guidance must follow [`references/composability-checklist.md`](./references/composability-checklist.md).
- The produced skill must be atomic: do not depend on other skills, and vendor any reused contract into local bundled resources instead.
- Do not add “helpful” extras that change scope.
- Any missing high-impact detail that changes behavior must be captured as `TODO: Confirm`.
- `Gotchas` is required and should be one of the strongest sections in the skill.

## Requirements

- Requested archetype or enough evidence to classify it as workflow or knowledge/capability.
- User intent and trigger conditions (`Use when ...`).
- In-scope and out-of-scope boundaries.
- Expected inputs/outputs (files, formats, APIs, artifacts) for workflow skills, or expected decisions/standards/failure modes for knowledge skills.
- Failure modes to prevent (hallucination risks, format drift, ambiguity, stale domain patterns).
- Composition boundaries: what should stay in `SKILL.md`, what should move into `references/`, `scripts/`, or `assets/`, and what should remain independently reusable.

## Workflow

Execute in this order unless the user already provided equivalent inputs. If a step is skipped because inputs already exist, verify the same outcome before continuing.

1. **Classify the skill archetype**

   Use [`references/skill-archetypes.md`](./references/skill-archetypes.md) before selecting a template.

   Classify as:
   - **Workflow skill** when the agent must execute a repeatable procedure, preserve sequence, or produce a defined artifact.
   - **Knowledge/capability skill** when the agent must apply standards, domain expertise, judgment, patterns, or anti-patterns inside many possible tasks.

   If the request mixes both:
   - split into two atomic skills when both parts are independently useful
   - otherwise choose the dominant archetype and move secondary guidance into local `references/`
   - ask one clarifying question when the dominant archetype would change the generated section contract

   If the user refuses details, choose the best-supported archetype and mark the uncertainty as `TODO: Confirm`.

2. **Gather archetype-specific requirements**

   Ask about shared basics:
   - what the skill is for and what should trigger it
   - what is in-scope vs out-of-scope
   - whether it needs bundled resources
   - which failure modes it must prevent
   - how it should compose with other skills without tight coupling

   For workflow skills, also ask about:
   - required inputs and outputs
   - ordered steps and branch points
   - expected deliverables or artifacts
   - deterministic validation commands or transforms

   For knowledge/capability skills, also ask about:
   - domain standards or rules the agent must internalize
   - decisions the agent should be able to make differently after loading the skill
   - preferred patterns, anti-patterns, and examples worth bundling
   - stale defaults or hallucination-prone habits the skill must override

   If user input is incomplete, mark unknown high-impact details as `TODO: Confirm`.

3. **Draft the skill directory**
   - Start `SKILL.md` from the archetype-specific template:
     - [`assets/workflow-skill-template.md`](./assets/workflow-skill-template.md) for workflow skills
     - [`assets/knowledge-skill-template.md`](./assets/knowledge-skill-template.md) for knowledge/capability skills
   - Apply [`references/frontmatter.md`](./references/frontmatter.md) while drafting frontmatter and naming.
   - Add `references/`, `scripts/`, and `assets/` only when criteria in [`references/resources.md`](./references/resources.md) are met.
   - Apply [`references/progressive-disclosure.md`](./references/progressive-disclosure.md) when deciding what stays in `SKILL.md` versus what moves into `references/*.md`.
   - Vendor any shared contract or borrowed guidance into local bundled resources so the final skill stays atomic.
   - Check composition decisions against [`references/composability-checklist.md`](./references/composability-checklist.md).

   Use these section contracts after copying the selected template:

   | Archetype | Required section order | Optional sections |
   | --------- | ---------------------- | ----------------- |
   | Workflow | `Rules` → `Constraints` → `Requirements` → `Workflow` → `Gotchas` → `Deliverables` | `References`, `Deterministic Validation` |
   | Knowledge/capability | `Rules` → `Constraints` → `Knowledge Boundaries` → `Patterns` → `Gotchas` | `References`; add `Deterministic Validation` only when bundled scripts exist |

   Section decisions:

   | Section | Include when | Omit when |
   | ------- | ------------ | --------- |
   | optional dispatch section | The skill branches or agents need a compact runtime router | The skill is short and linear, or a knowledge skill can express routing through `Knowledge Boundaries` |
   | `References` | Any `references/*.md` file is included | No bundled references are needed |
   | `Deterministic Validation` | A `scripts/*` command must be run for validation or transforms | No bundled script must be run; omit by default for knowledge/capability skills |

   Do not add `Validation Checklist`; it duplicates `Deliverables` and `Deterministic Validation` for workflow skills and does not fit knowledge skills.

4. **Write `Gotchas` early**
   - Add 5–9 gotchas.
   - Write them like post-mortems: specific failure, why it happens, what damage it causes, what to do instead.
   - For workflow skills, focus gotchas on wrong sequencing, skipped gates, invalid artifacts, and ambiguous handoffs.
   - For knowledge/capability skills, focus gotchas on stale defaults, bad domain assumptions, misapplied patterns, and overgeneralization.
   - Prefer experience-derived corrections over abstract “best practices”.
   - Use `Gotchas` to redirect agents away from their normal but wrong patterns.
   - Check the draft against [`references/gotchas.md`](./references/gotchas.md).

5. **Review with user**

   Present the draft and ask:
   - Did I choose the right archetype: workflow or knowledge/capability?
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more or less detailed?

   If the user refuses details, proceed with a minimal skill and mark assumptions as `TODO: Confirm`.

## Gotchas

- If you classify too late, the template choice inherits accidental structure from the first draft and knowledge skills grow fake workflows. Classify before writing sections.
- If a skill teaches judgment but includes `Workflow` and `Deliverables`, agents try to complete artifacts instead of applying expertise inside the current task. Use the knowledge/capability template instead.
- If a skill requires ordered execution but uses only standards and patterns, agents skip sequencing and produce inconsistent results. Use the workflow template when order matters.
- If a hybrid request becomes one tangled skill, runtime routing gets vague and agents cannot tell whether to execute steps or apply background expertise. Split it or make one archetype primary and vendor the other as references.
- If you explain the skill like a README, agents over-read narrative and under-read triggers. Lead with routing, boundaries, and actions or standards.
- If `SKILL.md` tries to hold everything, future skills duplicate buried rules instead of composing with reusable references or scripts.
- If the `description` is vague, agents cannot select the skill at runtime and authors try to compensate with tighter coupling.
- If you model shared guidance as another skill dependency instead of vendoring the needed contract into local bundled resources, the skill stops being atomic and becomes harder to package, reuse, and route reliably.
- If `Gotchas` only restate generic rules, they do not change behavior. Write them from observed failure patterns.

## Deliverables

Return a complete, atomic skill directory that is ready to use and follows the section contract for its selected archetype.

Required artifacts:

- `SKILL.md` with valid frontmatter and required sections for either the workflow or knowledge/capability contract.
- Support directories only when justified by [`references/resources.md`](./references/resources.md).
- Skill folder shape must follow [`references/structure.md`](./references/structure.md).
- Any borrowed contract needed by the skill is vendored locally under bundled resources instead of another skill dependency.
- `Gotchas` with 5–9 specific, actionable, experience-derived items.
- Workflow skills include `Deliverables`; knowledge/capability skills do not invent deliverables unless the user explicitly asks for an artifact-producing workflow.
- No separate `Validation Checklist`; quality criteria belong in `Deliverables` for workflow skills, and executable validation belongs in `Deterministic Validation` only when scripts exist.

## References

- [`references/skill-archetypes.md`](./references/skill-archetypes.md): Read when: deciding whether to create a workflow skill or a knowledge/capability skill, especially for hybrid requests.
- [`assets/workflow-skill-template.md`](./assets/workflow-skill-template.md): Read when: drafting or refactoring a workflow skill entrypoint `SKILL.md`.
- [`assets/knowledge-skill-template.md`](./assets/knowledge-skill-template.md): Read when: drafting or refactoring a knowledge/capability skill entrypoint `SKILL.md`.
- [`references/frontmatter.md`](./references/frontmatter.md): Read when: naming the skill, writing the description, or confirming that the skill stays atomic without cross-skill dependency metadata.
- [`references/resources.md`](./references/resources.md): Read when: deciding whether to add `references/`, `scripts/`, or `assets/`, or how to keep those files composable.
- [`references/structure.md`](./references/structure.md): Read when: shaping the skill as a directory toolbox and applying the workflow or knowledge section contract.
- [`references/progressive-disclosure.md`](./references/progressive-disclosure.md): Read when: deciding what to keep in `SKILL.md` and what to move behind conditional loading.
- [`references/gotchas.md`](./references/gotchas.md): Read when: writing or reviewing the `Gotchas` section so it reads like post-mortems instead of generic warnings.
- [`references/notify-hook.md`](./references/notify-hook.md): Read when: wiring automatic validation after each turn.
- [`references/composability-checklist.md`](./references/composability-checklist.md): Read when: checking whether the skill composes cleanly at runtime without tight coupling.

## Deterministic Validation

Validate this skill or a generated skill directory with:

- `bash scripts/validate-skill.sh <target-skill-dir>`

The command checks frontmatter, section structure, references, and size thresholds. It accepts both workflow and knowledge/capability section contracts. If a generated skill has its own scripts, list only the exact script commands it must run here.

Codex supports a `notify` command hook that runs after each agent turn and receives a JSON payload. You can use it to run validation automatically. See [`references/notify-hook.md`](./references/notify-hook.md) for a ready-to-use snippet.
