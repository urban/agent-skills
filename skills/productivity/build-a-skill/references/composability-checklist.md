# Composability Checklist

Use this document before finalizing a new or updated skill.

## Boundary Checks

Confirm the skill keeps these responsibilities separate:

- requirements describe the requested capability and scope
- design guidance describes structure and operating constraints
- execution guidance describes how the agent should carry out the work

Planning must not redefine requirements.
Requirements must not become technical design.
Bundled guidance must not silently invent intent.

## Contract Checks

If the skill participates in a shared artifact type, confirm:

- section order matches the canonical contract
- naming rules match the canonical contract
- validation rules match the canonical contract
- uncertainty handling is explicit where interpretation is involved

Prefer vendoring the needed contract into local bundled resources instead of relying on another skill to supply it.

## Reuse Checks

Confirm:

- the skill has one clear responsibility
- the owned output is explicit
- borrowed guidance is bundled locally instead of hidden behind another skill dependency
- another orchestration skill could reuse it without modification

## Agent-Use Checks

Prefer:

- deterministic filenames
- explicit headings
- concise instructions
- direct workflow order
- local validation commands

Avoid vague prose, hidden assumptions, and output formats that require an LLM to infer structure.

## Atomicity Checks

For an atomic skill, confirm:

- execution-critical guidance lives in the skill directory itself
- any reused contract is vendored into `references/`, `assets/`, or `scripts/`
- runtime selection does not rely on `metadata.dependencies`
- the skill still works when copied or packaged on its own
