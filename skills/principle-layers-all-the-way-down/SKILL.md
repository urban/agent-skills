---
name: principle-layers-all-the-way-down
description: Build opinionated defaults from supported, recomposable pieces. Use when designing reusable capabilities, application layers, UI components, or styling systems, especially when a higher-level default almost fits.
disable-model-invocation: true
---

# Layers All the Way Down

## Rules

- Design opinionated defaults for the common 80%; chasing 100% produces sprawling configuration. Treat 80% as a design heuristic, not a coverage quota.
- Assemble higher-level capabilities from the same supported lower-level pieces consumers can use. Keep those pieces independently composable and replaceable through explicit contracts.

## Constraints

- Preserve invariants when recomposing. Expose failure, state, cancellation, and lifetime obligations wherever correct composition depends on them.
- Publish deliberate building blocks; private implementation details need not become public APIs.

## Knowledge Boundaries

Applies across application capabilities, runtime assembly, UI components, and foundational, semantic, and component tokens; no particular framework or layer count is required.

## Patterns

Use the default when it fits. When supported configuration is insufficient, step down a layer, rearrange its building blocks, and add custom code or layers for the remaining need.

Test: can consumers replace the default arrangement through supported pieces without copying its implementation or breaking its guarantees?

## Gotchas

- Special-case flags obscure the default; offer recomposition for divergent requirements.
- Privileged default wiring forces forks; build defaults through supported contracts.
- Mere forwarding adds navigation; keep layers that contribute behavior, policy, or useful control.
- Matching types can conceal incompatible behavior; preserve semantic guarantees when swapping pieces.
- Custom compositions can bypass safety; keep invariant enforcement with its owning capability.
