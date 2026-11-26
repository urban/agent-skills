Write `Gotchas` like post-mortems because abstract warnings do not reliably change agent behavior.

Use this pattern:

- failure pattern
- why agents fall into it
- what damage it causes
- what to do instead

Good gotchas are:

- specific
- actionable
- experience-derived
- scoped to this skill's real failure modes

Bad gotchas are:

- generic “be careful” advice
- restatements of obvious rules
- style preferences with no failure story
- vague warnings that do not change execution

Aim for 5–9 gotchas per skill.

## Gotchas

- If a gotcha does not describe a failure pattern, it reads like style advice and agents ignore it.
- If every gotcha is generic, the section becomes redundant with `Rules` and loses its value.
- If gotchas only say what not to do, agents still do not know the safer replacement.
- If gotchas are too long, agents stop scanning them at the exact moment they should be using them.
- If gotchas are invented instead of observed, they optimize for theory instead of redirecting real failure modes.
