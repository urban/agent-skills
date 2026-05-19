# Agent skills

This repo contains agent skills that follow the [Agent Skills specification](https://agentskills.io/home).

## Structure

Skills are grouped by type under `skills/`:

- `skills/productivity/` — general workflow skills that are not code-specific.
- `skills/engineering/` — general coding, design, review, and documentation skills.
- `skills/engineering-with-effect/` — Effect-specific knowledge skills for current Effect-native TypeScript standards.

The `agentic-patterns/` directory contains longer Effect pattern notes used as source material for the Effect knowledge skills.

## Skills

### Productivity

- `brainstorming` — collaborative design discovery that converges on one approved design artifact.
- `build-a-skill` — the repo's canonical pattern for creating, refactoring, and debugging skills.

### Engineering

- `denotational-design` — full denotational architecture and API specs before implementation.
- `denotational-design-light` — lightweight denotational pass for API, data type, state, and refactor work.
- `review-pr` — thorough pull request review against requirements and repository standards.
- `test-driven-development` — strict red-green-refactor for Effect codebases.
- `typescript` — pragmatic functional TypeScript style and constraints.
- `typescript-inline-documentation` — JSDoc-first inline docs and TypeDoc-ready API documentation.

### Engineering with Effect

Effect skills are knowledge skills: they teach current Effect-native authoring standards and focused package patterns.

- `effect-core` — cross-cutting Effect v4 standards for services, layers, errors, streams, schemas, observability, and tests.
- `effect-ai` — Effect AI integrations, providers, tools, structured output, streaming, and tests.
- `effect-atom` — Effect Atom state modules, async lifecycles, React integration, optimistic updates, and tests.
- `effect-cluster` — Effect Cluster entities, RPC protocols, runners, persistence, proxies, and tests.
- `effect-fast-check` — property-based tests for Effect code.
- `effect-http` — Effect HTTP APIs, clients, schema bodies, status/error mapping, and in-process tests.
- `effect-layer` — Effect Layer composition, dependency wiring, scoped resources, sharing, and test layers.
- `effect-opentelemetry` — spans, metrics, logs, OTLP/OpenTelemetry layers, attributes, and telemetry tests.
- `effect-optic` — immutable reads and updates with Effect Optic.
- `effect-platform` — filesystem, process, terminal, socket, runtime, and other platform boundaries.
- `effect-schema` — runtime validation, codecs, tagged errors, transformations, HTTP contracts, and schema tests.
- `effect-service` — Context.Service boundaries, contracts, layers, errors, and test services.
- `effect-stream` — lazy back-pressured streams, adapters, protocols, cleanup, and stream tests.
- `effect-testing` — @effect/vitest, layer replacement, deterministic concurrency, typed errors, and integration seams.
- `effect-workflow` — durable Effect workflows, activities, deferreds, queues, compensation, proxies, and tests.

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
- For Effect work, start with `skills/engineering-with-effect/effect-core/`, then add narrower Effect skills as needed.

## License

See `LICENSE`.
