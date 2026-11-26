# Agent skills

This repo contains agent skills that follow the [Agent Skills specification](https://agentskills.io/home).

## Structure

Skills are grouped by category under `skills/`:

- `skills/productivity/` — general workflow skills that are not code-specific.
- `skills/engineering/` — coding, design, review, and documentation skills, including Effect-specific standards.
- `skills/in-progress/` — tracked draft skills that are not yet in a stable category.

## Skills

The list below highlights available skills, including drafts.

### Productivity

- `brainstorming` — collaborative design discovery that converges on one approved design artifact.
- `build-a-skill` — the repo's canonical pattern for creating, refactoring, and debugging skills.

### Engineering

- [`effect-best-practices`](skills/engineering/effect-best-practices/SKILL.md) — Effect-specific design judgment, with selectively loaded principles and topics. Extends `typescript-best-practices`; API details stay in the Effect repository.
- `typescript` — pragmatic functional TypeScript style and constraints.
- `typescript-project-hygiene` — compiler configuration, diagnostic policy, and module hygiene.

### In progress

- `capture-decisions` — non-engineering decisions with rationale, consequences, and risks.
- `architecture` — deep modules, adapter and persistence seams, entrypoints, transactions, and idempotency.
- `prototyping` — bounded experiments and reusable architecture, UX, or feasibility findings.
- `testing-strategy` — contract-focused evidence through real internal composition and controlled external dependencies.
- `tdd` — deliberately selected red-green-refactor cycles and cheap regression reproductions.
- `to-spec` — reviewed product/feature contracts and execution handoffs.
- `vision` — project vision refined through evidence, hypothetical changes, and owner reasoning.
- `write-adr` — engineering decisions, alternatives, evidence, and supersession.

## What is specific to this repo

These skills follow a few strong conventions:

- **Atomic skills**: each skill should work on its own without depending on other skills.
- **Progressive disclosure**: keep `SKILL.md` focused; move conditional detail into `references/`, `assets/`, and `scripts/`.
- **Clear boundaries**: `Rules` and `Constraints` are separate, and out-of-scope work is called out explicitly.
- **Useful gotchas**: `Gotchas` are treated as real execution guidance, usually written like short post-mortems.
- **Deterministic validation**: when something can be checked reliably, prefer a script over model judgment.

## Where to start

- Read a skill's `SKILL.md` first.
- If you want the clearest picture of this repo's conventions, start with `skills/productivity/build-a-skill/`.
- For Effect work, use [`effect-best-practices`](skills/engineering/effect-best-practices/SKILL.md) alongside [`typescript-best-practices`](skills/in-progress/typescript-best-practices/SKILL.md). Read the applicable principles and the topic owning the current decision; get API facts from the project's Effect checkout.

## License

See `LICENSE`.
