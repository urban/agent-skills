# Domain model and routing

Separate roles:

| Role | Owns |
| --- | --- |
| Domain AI capability | Product behavior, prompt intent, output normalization, caller errors |
| Router/registry | Configured provider/model selection and availability |
| Provider adapter | Provider request/response mapping and transport |
| Execution/fallback plan | Attempts, equivalent alternatives, and retry boundaries |

Use structured generation when fields drive downstream behavior. A decoded schema value still needs domain validation for constraints a model schema cannot guarantee reliably.

Use chat only when history and tool results are part of the behavior. Persist history through a stable schema and version/normalize it at the boundary.

Expose streaming text or domain events rather than provider part variants. Decide whether partial output remains valid after terminal failure and what callers should render or retain.
