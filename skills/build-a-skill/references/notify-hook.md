Use this optional setup to run deterministic validation after each agent turn.

## Example `notify` snippet

```json
{
  "notify": {
    "command": "bash /absolute/path/to/build-a-skill/scripts/validate-skill.sh /absolute/path/to/target-skill --quiet"
  }
}
```

## Notes

- Replace both absolute paths with real paths in your environment.
- Keep `build-a-skill` script paths stable to avoid false failures.
- Use `--json` instead of `--quiet` if your integration expects machine-readable output.

## Gotchas

- If the notify hook points at a relative path, it often works locally once and then fails in automation.
- If the target path points at a file instead of a skill directory, validation fails after the turn instead of during authoring.
- If you move scripts without updating the hook, the hook becomes noise and gets ignored.
- If the hook emits the wrong format for the integration, failures disappear into logs instead of surfacing clearly.
- If you wire validation too early to an unstable path, authors disable the hook instead of fixing the pathing.
