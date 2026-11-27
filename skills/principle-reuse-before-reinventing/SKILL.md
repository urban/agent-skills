---
name: principle-reuse-before-reinventing
description: Inspect and exercise existing capabilities before adding variants, wrappers, components, services, adapters, or tooling. Use when deciding whether to reuse, configure, recompose, extend, or replace an existing capability.
---

# Reuse Before Reinventing

## Rules

- Inspect the existing capability, its supported contract, actual consumers, and relevant behavior before proposing another implementation. Exercise it when operation can settle whether it fits; distinguish unavailable observation from a missing capability.
- Try supported configuration, styles, and composition first. When the default almost fits, use its supported building blocks before copying the implementation or creating a parallel abstraction.
- Extend an existing owner when the added responsibility remains cohesive. Introduce a variant, wrapper, or replacement when you can name the requirement the existing capability cannot reasonably satisfy and explain the semantic mismatch, coupling, or maintenance cost.
- Keep a specialized solution local. Lift a shared capability only when actual sibling needs justify its contract; similar appearance or speculative reuse alone is insufficient.

## Constraints

- Do not force reuse by exposing private protocols, bypassing invariants, or accumulating unrelated flags. Preserve failure, state, cancellation, and lifetime guarantees when composing existing pieces.
- Do not copy production behavior into a demonstration or test substitute merely because the real capability is inconvenient to operate. Control dependencies through supported seams and state what remains unobserved.
- Do not preserve an unsafe, obsolete, or unsuitable design solely because it already exists, or turn a focused reuse decision into an unrelated architecture migration.

## Knowledge Boundaries

Applies to choosing among existing capabilities and justified additions across UI, application services, adapters, and development tooling. Inspect the requested behavior, existing owners and consumer contracts, supported extension points, and relevant runtime evidence.

Designing recomposable defaults, domain representations, test fidelity, and migration execution remain separate decisions. This principle requires neither a particular framework nor a new shared abstraction or decision document.

## Patterns

- **UI:** operate the current component in context; inspect its supported states, styles, configuration, and compositions. Use those surfaces for proposals. A distinct interaction may justify a local component; visual similarity alone does not justify shared ownership.
- **Adapters:** inspect the current provider owner and callers. Reuse or cohesively extend it when the contract fits; keep a separate capability when policy or lifetime obligations differ.
- **Tooling:** use an adequate existing command, preview surface, or test harness. Extend a genuine seam for a missing case before building a competing environment.

When adding something new, make the unmet requirement and why the existing options do not fit clear in the current explanation or owning record. Scale the explanation to the decision; no separate ceremony is required.

## Gotchas

- If inspection stops at a component's name or screenshot, supported behavior can be missed and a duplicate created. Read its contract and consumers, and operate the relevant state before deciding.
- If a proposal recreates production markup, approval applies to an imitation that can drift during integration. Review the actual component with controlled inputs and supported styling.
- If every mismatch becomes another flag, reuse couples unrelated responsibilities and makes the default harder to understand. Recompose supported pieces or introduce a cohesive local owner.
- If two capabilities have matching signatures but different failure or lifetime guarantees, substitution can break callers while types still pass. Compare semantics before reusing the implementation.
- If a one-off need immediately becomes shared infrastructure, speculative consumers inherit a configuration burden. Keep it local until actual sibling needs establish a useful shared contract.
