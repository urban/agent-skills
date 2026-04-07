Use this guide to decide when to add supporting directories to a skill.
This file is the source of truth for directory-specific decisions and split thresholds.
Do not duplicate numeric thresholds in other Markdown docs; link back to this guide.
Deterministic validators may encode matching thresholds and must be kept aligned with this file.

## `scripts/`

Put deterministic utilities here because generated one-off code is harder to trust and reuse.

Add scripts when:

- the operation is deterministic
- the same code would be generated repeatedly
- errors need explicit handling
- scripts save tokens and improve reliability versus generated code

Implementation guidance:

- Make every script composable: one deterministic responsibility, explicit inputs, stable exit codes.
- Avoid hidden cwd assumptions or side effects because they make scripts hard to reuse.
- Allow orchestration scripts, but keep leaf scripts independently callable.
- Document each script in `SKILL.md` under `Deterministic Validation`.

## `references/`

Put conditional detail here because agents should not load it until the task requires it.

Split content into `references/` when:

- different tasks need different subsets of information
- content has distinct domains
- sections are mutually exclusive
- large examples, schemas, or tables would bloat `SKILL.md`

Threshold guidance:

- Recommend splitting when content grows beyond ~200 lines.
- Strongly expect splitting at 500+ lines.

Implementation guidance:

- Keep `SKILL.md` concise and link reference files from the `References` section.
- In `SKILL.md`, add `Read when: [specific condition]` to every reference entry so agents can decide whether to load the file.
- Keep routing metadata in `SKILL.md` instead of duplicating it inside each reference file.
- Organize references by topic with clear, specific filenames.
- Vendor shared contracts or borrowed guidance here when that keeps the skill atomic and self-contained.
- Avoid duplicating canonical instructions across multiple files.
- Split reusable guidance into references instead of burying it in `SKILL.md`.

## `assets/`

Put static reusable artifacts here because they improve consistency without adding executable complexity.

Add `assets/` when:

- reusable files improve consistency across executions
- structured templates are required for output shape or formatting
- large static content would bloat `SKILL.md`

Implementation guidance:

- Treat assets as source-of-truth inputs and reference them explicitly in workflows.
- Keep assets versionable, human-readable, narrowly scoped, and reusable.
- Do not place executable logic in `assets/`; use `scripts/` for executable behavior.

## Gotchas

- If you put deterministic logic in prose instead of `scripts/`, every run re-generates slightly different behavior.
- If a script only works from one cwd, it looks reusable but fails as soon as another skill calls it.
- If references duplicate rules from `SKILL.md`, authors fix one copy and leave the other stale.
- If assets contain executable logic, agents cannot tell what is static input versus behavior.
- If support files exist without a clear reason, the skill becomes harder to load and harder to maintain.
