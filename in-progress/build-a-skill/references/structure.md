Build the skill as a directory because agents need an entrypoint plus optional tools they can load on demand.

```text
skill-name/
├── SKILL.md
├── references/*.md
├── assets/*
└── scripts/
```

- Keep `SKILL.md` as the required entrypoint.
- Select exactly one section contract before drafting: workflow or knowledge/capability.
- Add `references/` only when conditional detail improves runtime loading.
- Add `assets/` only when static reusable artifacts improve consistency.
- Add `scripts/` only when deterministic reusable behavior improves reliability.
- Bundle execution-critical guidance inside the skill directory so the skill remains atomic when copied on its own.
- Do not treat the skill as a single markdown file. Treat it as a toolbox with one required entrypoint.

## Section contracts

Use the workflow contract when the skill teaches an ordered procedure:

```text
Rules
Constraints
Requirements
Workflow
Gotchas
Deliverables
References                  # optional
Deterministic Validation    # optional
```

Use the knowledge/capability contract when the skill teaches standards, judgment, domain expertise, or reusable capability:

```text
Rules
Constraints
Knowledge Boundaries
Patterns
Gotchas
References                  # optional
Deterministic Validation    # optional
```

Do not mix the two contracts at top level. If a skill needs supporting expertise for a workflow, put that detail in `references/`. If a knowledge skill needs illustrative steps, keep them as examples under `Patterns` or in `references/` instead of adding a top-level `Workflow`.

## Template mapping

- Workflow skills start from `assets/workflow-skill-template.md`.
- Knowledge/capability skills start from `assets/knowledge-skill-template.md`.

## Gotchas

- If the section contract is chosen after drafting, the skill keeps accidental leftovers from the wrong template.
- If `Workflow` appears in a knowledge skill, agents treat domain expertise as a checklist and stop applying judgment to the live task.
- If `Knowledge Boundaries` appears in a workflow skill, the entrypoint starts carrying background material that belongs in references.
- If optional sections are titled `References (optional)` or `Deterministic Validation (optional)`, validators and readers treat them as custom headings. Use exact headings when present, or omit the section entirely.
