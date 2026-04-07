# Agent skills

This repo contains a small set of coding-focused skills that follow the [Agent Skills specification](https://agentskills.io/home).

## Skills

The `skills/` directory currently includes:

- `brainstorming`: design discovery that converges on one approved design doc
- `build-a-skill`: the repo's canonical pattern for creating and refining skills
- `test-driven-development`: strict red-green-refactor for Effect codebases
- `typescript-inline-documentation`: JSDoc-first inline docs for TypeScript codebases

## What is specific to this repo

These skills follow a few strong conventions:

- **Atomic skills**: each skill should work on its own without depending on other skills.
- **Progressive disclosure**: keep `SKILL.md` focused; move conditional detail into `references/`, `assets/`, and `scripts/`.
- **Clear boundaries**: `Rules` and `Constraints` are separate, and out-of-scope work is called out explicitly.
- **Useful gotchas**: `Gotchas` are treated as real execution guidance, usually written like short post-mortems.
- **Deterministic validation**: when something can be checked reliably, prefer a script over model judgment.

## Where to start

- Read a skill's `SKILL.md` first.
- If you want the clearest picture of this repo's conventions, start with `skills/build-a-skill/`.

## License

See `LICENSE`.
