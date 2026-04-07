Build the skill as a directory because agents need an entrypoint plus optional tools they can load on demand.

```text
skill-name/
├── SKILL.md
├── references/*.md
├── assets/*
└── scripts/
```

- Keep `SKILL.md` as the required entrypoint.
- Add `references/` only when conditional detail improves runtime loading.
- Add `assets/` only when static reusable artifacts improve consistency.
- Add `scripts/` only when deterministic reusable behavior improves reliability.
- Bundle execution-critical guidance inside the skill directory so the skill remains atomic when copied on its own.
- Do not treat the skill as a single markdown file. Treat it as a toolbox with one required entrypoint.
