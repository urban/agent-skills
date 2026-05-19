Design the skill so agents load only the information needed for the current step, because overloading `SKILL.md` wastes context and weakens composition.

## Loading model

- **Tier 1: Frontmatter** (`name`, `description`)
  - Loaded for all skills at startup.
  - Used for routing and skill selection.
- **Tier 2: `SKILL.md`**
  - Loaded when the skill is triggered.
  - Contains the required workflow and links to deeper docs.
- **Tier 3: Bundled resources**
  - Loaded on demand.
  - Should contain optional, advanced, or task-specific detail.
  - For directory-specific guidance, see `references/resources.md`.

## Rules

- Keep `SKILL.md` focused on required execution steps.
- Move optional or conditional detail to Tier 3 and link to it.
- Link instead of duplicating because duplication drifts.
- Add explicit navigation so the agent does not guess what to read next.
- In `SKILL.md`, every reference entry must include `Read when: [specific condition]` so the agent can decide whether to load the file.
- Keep routing metadata in `SKILL.md` instead of repeating it at the top of each reference file.
- Keep folder-level decisions in `references/resources.md`.
- Do not restate split thresholds outside `references/resources.md`.

## Navigation patterns

When `references/` exists, include one lightweight routing table or list in `SKILL.md` near the workflow or references section.

| Task                      | Read first                             |
| ------------------------- | -------------------------------------- |
| Draft frontmatter         | `references/frontmatter.md`            |
| Choose supporting dirs    | `references/resources.md`              |
| Use folder skeleton       | `references/structure.md`              |
| Write post-mortem gotchas | `references/gotchas.md`                |
| Design tiered docs        | `references/progressive-disclosure.md` |

Implementation notes:

- Keep link labels specific and action-oriented.
- Put navigation near where decisions are made.
- Prefer one authoritative location for each rule.

## Gotchas

- If you keep optional detail in `SKILL.md`, agents pay the token cost every time instead of loading it on demand.
- If references do not say when to read them, agents either ignore them or read all of them.
- If multiple files restate the same rule, the rule drifts and composition breaks.
- If navigation is far from the decision point, agents guess instead of following the intended path.
- If split logic lives in multiple docs, authors update one threshold and forget the others.
