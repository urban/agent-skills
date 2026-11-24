# Turn reviewed scope into tickets

**Enter when:** task creation is requested for reviewed feature scope or preparation work. Creating tasks starts no implementation or worker dispatch.

**Read:** selected plan, exact reviewed flow and scoped decisions, affected design-map entries and implementation; [workflow contract](../references/workflow-contract.md), [design records](../references/design-records.md), and project task bindings. Use [operable outcomes](../principles/operable-outcomes.md) and [proportionate evidence](../principles/proportionate-evidence.md) to choose coherent task boundaries and checks.

## Create and verify

1. Inspect existing tracker records and extend them instead of duplicating work. Reuse project IDs, hierarchy, executors and claim conventions through the available task-backend skill. Resolve material scope/design gaps through [planning](planning.md); do not reopen absent historical rationale.
2. Create the slice parent using the project's hierarchy. Keep shared scope, plan/review/decision links, baseline, accepted delta, real/simulated boundaries, constraints, execution policy and integrated demonstration there. In Scribe each slice is an epic.
3. Split coherent outcomes by ownership, prerequisites or risk. Prefer one implementation task plus required integrated review for a tiny change when that provides adequate ownership and evidence. Do not split solely by artifact type. Each task contains its result, affected files/capability, owner, genuine dependencies, completion criteria, focused checks and specific exclusions or failures. Link shared context instead of repeating slice constraints in each task. Scheduling order and hierarchy do not by themselves imply dependencies.
4. Explicitly assign required accepted-target, vocabulary/map and qualifying ADR updates. Sequence approved target records before dependent interface work so workers share the same direction. If one worker owns both, put reconciliation first within that task's criteria rather than creating another ticket solely for ordering. Disclose stale records until reconciliation happens. Assign integration, supported imports, affected consumers, module/review coverage and production exclusions where relevant. Preserve scope and approval provenance through later steering.
5. Include the integrated demonstration and final human review required by project policy. A human decision required before further implementation ends the current slice. Do not hide it inside a long chain of dependent tasks.
6. Create parents before children, retain returned IDs and read back stored handoffs, hierarchy, prerequisites and executors. Verify exact design links and the first actionable task. Keep the tracker as execution truth; create no duplicate `tasks.md`.

## Delegate and finish

Independent readers may check ownership or prerequisites, but one writer owns tracker mutations and hierarchy. Follow [delegation](../references/delegation.md) and the backend's claim safety.

**Deliver:** parent/epic ID, task links, first actionable task and verification limits. Reviewed scope plus a request to ticket it needs no second hierarchy approval. Use [execute](execute.md) only when execution is also authorized.
