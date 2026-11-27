# Iterate on UI design

**Enter when:** exploring or refining appearance/interaction, resolving a UI decision for planning, or responding to scoped design feedback. For comparison of an implementation with its accepted target, select [fidelity](fidelity.md).

**Read:** affected brief/slice, latest feedback, named states, current implementation and owning target; [review contract](../references/review-contract.md), [compare equivalent states](../principles/compare-equivalent-states.md), and [preserve settled decisions](../principles/preserve-settled-decisions.md). Use [explore before committing](../principles/explore-before-committing.md) when direction is unresolved, and [proportionate evidence](../principles/proportionate-evidence.md) to size the review.

## Build and steer

1. Name the target, states, user need, current limitation and requested change boundary. Preserve surrounding flows. Identify affected shared consumers and any necessary wider change explicitly. Resolve focused review gaps through [review readiness](../references/review-readiness.md); do not start whole-project setup.
2. Identify the before as running UI, accepted target or prior proposal. Preserve a retrievable revision and fixture/state; disclose implementation/target gaps. A dirty working tree needs a scoped source snapshot or base-plus-patch that reconstructs the shown state.
3. Inspect and operate the current component in context before choosing a variant or separate component. Try supported states, styling, configuration and composition; identify the remaining requirement before adding an implementation. Use `principle-reuse-before-reinventing` when available as described in the skill entrypoint. Build proposals from actual application components, styling and existing compositions. When direction remains unresolved, use [Explore alternatives](#explore-alternatives-when-direction-is-unresolved). Isolate intentional variants from unrelated consumers. Use realistic controlled services through existing seams, label simulations, and keep review controls outside product navigation. Do not imitate production controls with independent markup.
4. Present matched before/after together or through an immediate clear switch, with enough context to reveal incidental changes. Annotate the affected flow and explain the delta, applicable project guidance, benefit and tradeoffs. Make both paths resettable and operable when timing, focus, scrolling, cancellation or recovery matters.
5. Support approval, detailed revision, combined selections and rejection. Preserve settled choices in the next comparison; associate feedback with the exact units, states and revision. A rejected exploration can be a completed outcome. Return materially changed scope and its implications to the caller; a direct assignment asks only for the consequential changed decision.
6. Maintain affected vocabulary, module/review links and states under the [workflow contract](../references/workflow-contract.md). On scoped approval, update the owning editable target and qualifying ADRs using [design records](../references/design-records.md), then update the map. Keep proposed, accepted, rejected and superseded records truthful. Do not use the review session as a parallel decision authority.

## Explore alternatives when direction is unresolved

Use this branch for a consequential visual or interaction choice that remains unresolved after inspecting and trying the existing interface's supported options, including a decision needed during planning. Settled designs and small refinements continue through the main procedure directly.

1. Name one decision and what operating the alternatives should reveal. Keep unrelated product choices fixed.
2. Create a project-appropriate scratch directory using the existing preview tooling. Import actual application modules and styles; isolate candidate changes from production entry points, outputs and unrelated consumers. Reuse one review harness rather than installing a new platform or duplicating the environment per variant.
3. Build two or three meaningfully different, inexpensive candidates. Share realistic fixtures and controlled dependency seams, label simulations, and spend effort on the decision rather than polishing every candidate for production.
4. Put labeled candidates and the current or accepted baseline behind one shared switcher. Match content, viewport and starting state; provide reset paths when interaction matters. If no baseline exists, say so and compare the candidates under equivalent conditions.
5. Operate the relevant paths, capture proportionate evidence, and present tradeoffs with a recommendation. Support selection, combined parts, revision and rejection. Tie feedback to exact variants/revisions and preserve settled choices in each subsequent round.
6. Stop when the decision is resolved or the exploration is rejected. Carry scoped approval into the owning target and qualifying decision records through the main procedure. Hand the chosen direction to authorized implementation; scratch code is an experiment, not evidence of production readiness. Retain referenced revisions for review provenance without promoting scratch artifacts into a second design authority.

## Transition to fidelity

For an assignment to compare implemented UI with its accepted target, read [fidelity](fidelity.md). Return iteration findings or accepted refinements to the caller before broader integration; neither preview success nor design approval establishes production completion.

## Delegate and deliver

Use [delegation](../references/delegation.md) for isolated alternatives or independent critique. Candidate writers have separate outputs; one owner drives a shared app and one coordinator integrates feedback. Do not duplicate the entire design environment for a small revision.

**Deliver:** editable/operable source, proportionate annotated captures, rationale, scoped feedback/status and evidence links using the [review template](../assets/review-template.md) or an existing equivalent. State what the demonstration establishes and which dependencies remain simulated or untested under the [review contract](../references/review-contract.md). Requested artifacts are authorized; production integration, tickets and deployment remain within their own authorization. Preserve approved refinements in owning records and return their implications; continue broader work only within the existing assignment/authorization.
