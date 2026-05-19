This is the validity specification for Codex skill frontmatter in `SKILL.md`.
These requirements are enforced by `scripts/frontmatter.sh`.

## Required structure

- `SKILL.md` MUST start at line 1 with an opening YAML fence: `---`.
- Frontmatter MUST include a closing YAML fence: `---`.
- Frontmatter MUST be YAML only.
- Frontmatter MUST include both required keys:
  - `name`
  - `description`
- Optional fields MUST use existing supported top-level keys such as `metadata`.
- For atomic skills, omit unused optional fields and prefer no `metadata.dependencies`.

## `name` requirements

- Match `^[a-z0-9]+(-[a-z0-9]+)*$` because runtime discovery depends on stable names.
- Keep `name` equal to the skill directory name because mismatches break packaging and validation.
- Keep `name` at 64 characters or fewer.
- Use a single-line scalar.

## `description` requirements

Hard requirements:

- Include `description`.
- Keep it at 1024 characters or fewer.

Recommended requirements:

- Keep it at least 20 characters. Prefer 50+ for reliable activation.
- Include an activation phrase:
  - `Use when ...`
  - or `Use for ...`

## Skill Description Guidelines

Write the description so an agent can choose the skill at runtime without relying on tight coupling.

- State what the skill does.
- Add a clear `Use when ...` trigger.
- Be explicit about triggers and context.
- Do not rely on cross-skill dependency metadata to compensate for a weak description.

## Atomic skill guidance

The frontmatter schema supports `metadata`, but atomic skills in this repo should avoid `metadata.dependencies`.

- Vendor shared contracts or reusable guidance into local `references/`, `assets/`, or `scripts/` instead of declaring another skill dependency.
- Keep the description strong enough for runtime selection on its own.
- Omit the `metadata` block entirely unless another supported metadata field is genuinely needed.
- If a skill would otherwise depend on another skill for instructions, copy the needed contract into local bundled resources instead.

## Valid frontmatter example

```yaml
---
name: extract-pdf
description: Extract text and tables from PDF files, fill forms, and merge documents. Use when working with PDF files or when a user mentions PDFs, forms, or document extraction.
---
```

## Avoid for atomic skills

This shape is supported by the schema but should not be used for atomic skills in this repo:

```yaml
---
name: extract-pdf
description: Extract text and tables from PDF files, fill forms, and merge documents. Use when working with PDF files or when a user mentions PDFs, forms, or document extraction.
metadata:
  dependencies:
    - shared-pdf-contract
---
```

Why to avoid it:

- it introduces cross-skill coupling
- it makes the skill less portable as a standalone directory
- the same guidance should live in local bundled resources instead

## Invalid examples

```yaml
---
name: Extract PDF
description: Helps with documents.
---
```

Why invalid:

- `name` is not lowercase-hyphen format.
- `description` is too vague and does not include a trigger phrase.

```yaml
---
description: Extracts structured data from invoices. Use when parsing invoice PDFs.
---
```

Why invalid:

- Missing required `name`.

## Gotchas

- If the description says what the skill is but not when to use it, agents fail to route to it at runtime.
- If the directory name and frontmatter `name` drift, install and validation behavior split in confusing ways.
- If authors keep shared guidance behind `metadata.dependencies` instead of bundling it locally, the skill stops being atomic and becomes harder to package or reuse.
- If the description is short but generic, it passes validation while still failing activation.
- If frontmatter grows new top-level keys casually, tooling has to guess which keys matter.

## Deterministic validation

- Run `scripts/frontmatter.sh <path-to-SKILL.md>` for frontmatter and naming checks.
- Run `scripts/validate-skill.sh <skill-dir>` for full skill validation.
