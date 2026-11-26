# Review package and feedback contract

Produce the smallest record that makes the comparison and next decision reliable. Reuse the existing review surface and owning artifacts; the information below does not require one file per item. Use the [review template](../assets/review-template.md) for a new record, or adapt an equivalent. Follow [design records](design-records.md) for canonical ownership.

## Required comparison information

1. **Target and scope:** stable review ID, user goal, named units/states, primary owner, intended boundary and relevant shared consumers.
2. **Before:** running implementation, accepted target or prior proposal; reconstructable source/revision, fixture/content and starting state. Disclose any implementation/target gap. For dirty source retain a scoped snapshot or base-plus-patch; a clean commit ID alone is insufficient.
3. **After:** actual UI components/styles/compositions, intentional variations and retrievable proposed source. Do not change unrelated consumers to stage an unapproved experiment.
4. **Comparable experience:** both versions together or an immediate clear switch; matched fixture, viewport, state, scroll and timing where possible. Explain unavoidable differences and preserve enough context to reveal incidental changes.
5. **Operation:** stable scenario ID plus launch instructions, a ready-to-open URL when available, reset paths and controlled dependencies. Provide corresponding operable paths for consequential interaction, focus, pending/cancel, timing, scrolling or recovery. Static annotated captures can settle a purely visual decision.
6. **Delta and rationale:** what changes, the user need/current limitation, applicable blend of project guidance, benefit, tradeoffs and decision needed. Label real versus simulated behavior; simulations do not prove integration or provider feasibility.
7. **Feedback:** approval, requested revisions, rejection or pending decision tied to exact revision and units/states. Feedback may combine parts of alternatives. Preserve settled choices on the next delta; rejection can complete an exploration.

## Record metadata

`schema: interface-first-review/v1` identifies the template contract; it is artifact metadata, not skill-discovery or scheduling metadata. Read and verify it with the actual review. A schema label alone does not validate the content. Keep human rationale in the body and link detailed evidence rather than repeating it.

- Required identity: `id`, `owner`, `targets` and `baseline` with its `kind`, reconstructable `source`, `fixture` and `state`.
- Required comparison: `proposal_source`, `preview` with `instructions` and stable `entry`, plus viewport/state/reset information where relevant. Links are relative to the record unless explicitly marked as project-root paths. Localhost URLs alone are not durable identifiers.
- Separate relevant status axes: design `proposed/accepted/rejected/superseded`; implementation `not-started/partial/complete`; verification `not-run/passed/failed/limited`; acceptance `pending/accepted/rejected`. Omit an irrelevant axis rather than claiming it was assessed. The template starts pending, never approved.
- Accepted design needs approval provenance naming source, exact revision, approved units/states and exclusions. For partial approval, use scoped approvals and leave the aggregate proposed, or create scoped records. Superseded records link their successor. Rejected records identify the actual feedback.
- Verification references identify observations, actual checks and their limits. Acceptance needs actual user feedback for the implemented result; worker completion, green tests and scheduler signals do not provide it.

## Completion

Check metadata against actual source, fixture, preview, captures and feedback. Verify local paths and links; correct contradictory status or stale current-target links. Apply selected project gates and focused visual/interaction checks, including matching sizes, copy, keyboard/focus and failure/recovery where consequential. Report inaccessible paths and untested mechanisms precisely. No whole-project hash manifest or exhaustive capture matrix is required for a small change.

On approval, maintain the editable target and qualifying ADRs and update affected map links. Review history remains provenance, not another ongoing decision authority. End with result, exact artifact links, verification/limits and the next decision/action; do not require a separate completion document.
