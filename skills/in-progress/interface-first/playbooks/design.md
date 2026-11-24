# Iterate and review design fidelity

**Enter when:** exploring or refining appearance/interaction, supporting planning, responding to feedback, or comparing authorized implementation with its accepted target.

**Read:** affected brief/slice, latest feedback, named states, current implementation and owning target; [review contract](../references/review-contract.md), [compare equivalent states](../principles/compare-equivalent-states.md), and [preserve settled decisions](../principles/preserve-settled-decisions.md). Use [explore before committing](../principles/explore-before-committing.md) when direction is unresolved, and [proportionate evidence](../principles/proportionate-evidence.md) to size the review.

## Build and steer

1. Name the target, states, user need, current limitation and requested change boundary. Preserve surrounding flows. Identify affected shared consumers and any necessary wider change explicitly. Resolve focused foundation gaps without automatically rerunning setup.
2. Identify the before as running UI, accepted target or prior proposal. Preserve a retrievable revision and fixture/state; disclose implementation/target gaps. A dirty working tree needs a scoped source snapshot or base-plus-patch that reconstructs the shown state.
3. Build proposals from actual application components, styling and existing compositions. Isolate intentional variants from unrelated consumers. Use realistic controlled services through existing seams, label simulations, and keep review controls outside product navigation. Do not imitate production controls with independent markup.
4. Present matched before/after together or through an immediate clear switch, with enough context to reveal incidental changes. Annotate the affected flow and explain the delta, applicable project guidance, benefit and tradeoffs. Make both paths resettable and operable when timing, focus, scrolling, cancellation or recovery matters.
5. Support approval, detailed revision, combined selections and rejection. Preserve settled choices in the next comparison; associate feedback with the exact units, states and revision. A rejected exploration can be a completed outcome. Coordinate materially changed scope with [planning](planning.md).
6. Maintain affected vocabulary, module/review links and states under the [workflow contract](../references/workflow-contract.md). On scoped approval, update the owning editable target and qualifying ADRs using [design records](../references/design-records.md), then update the map. Keep proposed, accepted, rejected and superseded records truthful. Do not use the review session as a parallel decision authority.

## Fidelity during authorized implementation

Compare the changed running interface with the approved target in matching states. Check consequential layout sizes, copy, controls, timing, keyboard/focus, failure/recovery and affected consumers. Correct unexplained differences within scope; bring consequential design deviations back for a decision. Automated checks alone do not establish fidelity. State inspection limits and preserve the runnable application.

## Delegate and deliver

Use [delegation](../references/delegation.md) for isolated alternatives or independent critique. Candidate writers have separate outputs; one owner drives a shared app and one coordinator integrates feedback. Do not duplicate the entire design environment for a small revision.

**Deliver:** editable/operable source, proportionate annotated captures, rationale, scoped feedback/status and evidence links using the [review template](../assets/review-template.md) or an existing equivalent. Requested artifacts are authorized; production integration, tickets and deployment remain within their own authorization. Carry approved refinements into owning records before the next slice.
