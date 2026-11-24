# Prepare the existing interface

**Enter when:** the user requests a reusable interface-first foundation or substantial missing preparation. An assessment-only request stays an assessment.

**Read:** project instructions, existing design map and accepted references, current UI implementation and review conventions; [project bindings](../references/project-bindings.md), [workflow contract](../references/workflow-contract.md), and [design records](../references/design-records.md). Use [semantic boundaries](../principles/semantic-boundaries.md) for decomposition and placement, and [proportionate evidence](../principles/proportionate-evidence.md) for verification scope.

## Prepare

1. Reconcile the existing root `DESIGN.md`, or create it using the [design-map template](../assets/design-map-template.md). Make it complete and immediately usable for the supported interface: names, composition/flow relationships, ownership, behavior, known guidance, source, accepted targets, decisions and reachable review entries. Include read-as-needed navigation. Preserve known rationale without inventing historical motives. Keep assessments and preparation backlogs outside the map.
2. Link the map from `AGENTS.md` with instructions to read the overview and affected records for UI work. Consolidate a superseded UI index, update incoming links and preserve detailed owning artifacts; keep one discovery route. Reconcile rather than overwrite existing content.
3. Apply the workflow contract's inventory and named-module requirements. Establish each named renderable element's ownership, small semantic interface and runnable review of its production implementation, with important states, supplied dependencies, reset paths and in-context compositions. Follow project rules for owning directories, module entries and colocation. Preserve supported imports; a local interface does not imply a public package export.
4. Reconcile accepted designs and qualifying non-code decisions with their existing owners. Use the project's owner-local design/ADR convention, repairing relative assets and executable path consumers when authorized moves are necessary. Map foundational UI, product interaction, domain and host roles onto the actual architecture.
5. Record project bindings for the selected review tools and task system. Extend the existing environment for matched baseline/proposal review; use an available tooling skill for its mechanics. Keep fixtures and review-only dependencies outside production interfaces and outputs.
6. Identify material gaps and carry substantial preparation through [planning](planning.md), [task creation](create-tasks.md) and authorized [execution](execute.md). Reuse settled decisions and authorization. Do not create a competing task list or require a completed foundation before every focused revision.

## Delegate and verify

Independent readers can inventory disjoint owners or review gaps using [delegation](../references/delegation.md). One writer reconciles the map and global records. Implementation ownership and scheduling follow project policy.

Verify map coverage, source/reference navigation, named module/review discovery, supported imports, important states and production exclusions. Run the relevant project review, type, boundary and build checks for actual implementation changes. Demonstrate one representative production interaction, its controlled states, a matched deliberate variation, and its parent context under the [review contract](../references/review-contract.md).

**Deliver:** the usable map and foundation, with implemented, approved, simulated, verified and missing capabilities distinguished. If access or scope blocks required work, identify concrete remaining preparation and report setup as incomplete while keeping the map usable. Assessment-only work reports findings without claiming foundation delivery.
