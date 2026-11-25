# Shape a demonstrable slice

**Enter when:** choosing or revising an operable product outcome, including a bounded preparation slice.

**Read:** selected slice, latest feedback, affected design-map entries, relevant implementation and owner/global decisions; [operable outcomes](../principles/operable-outcomes.md) and [preserve settled decisions](../principles/preserve-settled-decisions.md). Read [design records](../references/design-records.md) for records affected by a new decision.

## Shape and review

1. Recommend the smallest outcome that delivers the intended user value. Describe a concrete before-and-after journey. Separate effort from uncertainty, and include implementation, verification, demonstration and feedback in the slice's size. Keep adjacent work deferred unless required.
2. Identify what is real now, what becomes real, what remains simulated, and the relevant existing seam. Investigate technical uncertainty that could invalidate this outcome early. Record material assumptions the prototype has not established and the focused real integration checks still needed, using the [review contract](../references/review-contract.md) to distinguish demonstrated interaction from feasibility. Do not make unrelated future capabilities prerequisites.
3. Use [design](design.md) to show affected annotated screens in flow order and matched before/after states before finalizing scope. Make uncertain behavior operable when captures cannot settle it. Missing preview access leaves visual review pending while independent planning continues.
4. Resolve useful UI names and identify affected/new modules, owners, semantic entries, important states and runnable review scenarios under the [workflow contract](../references/workflow-contract.md). Plan supported-import, consumer-impact and production-exclusion changes where needed; use [semantic boundaries](../principles/semantic-boundaries.md) for consequential placement decisions.
5. Review the exact scoped design changes with the outcome. Reuse existing approval; ask only about unresolved or materially changed choices. If implementation needs an intermediate human decision, end this slice at that demonstrable decision and shape later work separately.
6. Record one compact plan using the project's existing IDs and conventions, adapting the [slice template](../assets/slice-template.md). Link requirements, exact reviews and baseline, capability boundaries, scope/risk/recovery, focused evidence, demonstration and final feedback checkpoint. Name required design-map, accepted-target and ADR updates. Preserve qualifying rationale in its owning decision record with actual status.

## Delegate and finish

Delegate bounded feasibility or source questions when useful; keep scope and user tradeoffs with the coordinator under [delegation](../references/delegation.md). Verify that the plan points to the exact reviewed flow, owners, simulations, unresolved risks and required record updates.

**Deliver:** reviewed slice scope and links, or a concrete proposal with the pending decision made explicit. Planning alone creates neither tickets nor implementation. Use [create tasks](create-tasks.md) when requested; do not add a separate hierarchy-approval ceremony to already authorized task creation.
