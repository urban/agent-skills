# Assess and refine UI fidelity

**Enter when:** comparing a running implementation with its accepted UI target. A report-only assignment changes no implementation; explicit or existing repair authorization permits scoped corrections.

**Read:** exact accepted target and approval provenance, changed source/revision, affected map/module/state entries and feedback; [review contract](../references/review-contract.md), [compare equivalent states](../principles/compare-equivalent-states.md), and [preserve settled decisions](../principles/preserve-settled-decisions.md).

## Compare and resolve

1. Establish the baseline/target, scope, approved units/states/exclusions, actual running revision and affected consumers. Disclose missing targets, source gaps and simulations. If no accepted target exists, report that limit; use [design iteration](design.md) only for an authorized design question.
2. Operate the actual changed production UI in matching content, viewport, state, scroll and timing. Preserve a reconstructable source for dirty changes. Use the existing review environment and focused [readiness](../references/review-readiness.md) gaps; do not substitute copied markup or static captures for consequential interactive checks.
3. Compare consequential layout/sizes, copy, controls, keyboard/focus, pending/cancellation, timing, failure/recovery and affected compositions. Present matched evidence that reveals the intended delta and incidental differences. Automated tests support their own claims; they cannot establish visual/interaction fidelity alone.
4. Record concrete deviations and their effect with source/state/evidence pointers. In report-only scope, return findings. When repair is authorized, correct unexplained differences, preserve accepted direction and recheck affected behavior. A consequential design deviation needs the actual decision through [design iteration](design.md); do not rewrite the target to excuse implementation. Continue independent covered repairs while that decision is pending.
5. Maintain affected review coverage, owning accepted-target/decision/map links as needed under [design records](../references/design-records.md). Record actual feedback against the exact revision. Report inaccessible paths, untested mechanisms and remaining deviations without treating silence as acceptance.

**Deliver:** fidelity findings or scoped refinements, exact target/running source references, matched evidence/checks and their limits, real/simulated boundaries, actual approval/acceptance state and next implications. Return to the calling workflow for remaining production integration and completion. A directly requested fidelity assessment can finish with findings; it does not require a ticket or broader implementation.
