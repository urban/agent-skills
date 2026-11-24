# Shared interface-first workflow contract

This contract defines named units, semantic interfaces and review coverage across the playbooks. Read only the affected inventory entries and follow deeper links for the current question. Project instructions select concrete filenames, package boundaries and tooling through [project bindings](project-bindings.md).

Root `DESIGN.md`, or the project’s existing design entry point, is a complete usable map of names, relationships, behavior, ownership, known guidance and review entries. It is not a setup assessment or run log. Setup establishes it from the existing project; planning, design and execution maintain affected entries and supported rationale. Missing historical motives do not block its use and must not be invented. Follow [design records](design-records.md) for owning targets/ADRs and [review contract](review-contract.md) for comparisons, feedback and status.

## Inventory record

Use stable human-readable names that identify the same part for the user and agent. Distinguish interface names from code identifiers. Link aliases if existing terminology would otherwise be ambiguous.

For a meaningful unit, record:

- **Identity and context:** name, purpose, parent/children or related flow, and an annotated visible reference where useful.
- **Responsibility and interface:** what it owns, supported inputs, semantic actions/outputs, views/projections, and supplied dependencies. For a renderable element, link its owning implementation and semantic entry, following the project's directory and module conventions. Record supported consumer imports and any public package entry where applicable; identify consumers and keep implementation details private.
- **Behavior:** important named states, events/transitions, local lifetime, external/controlled values, authoritative facts, effect and cleanup owners. A static part can simply have no lifecycle of its own.
- **Reuse and placement:** foundational UI, product interaction, local host composition, or another existing owner; boundary rationale and evidence using the [rubric](decomposition-rubric.md).
- **Review and impact:** for a renderable element, link the review source and stable runnable entry, map important states and variants to its review scenarios, and explain controlled dependencies and reset paths. Link the in-context entry, affected consumers and intentional variants.
- **Status:** running implementation, accepted target, proposed boundary/variation, or historical reference. Link the source/revision and relevant decision; disclose gaps and unresolved questions.

Distinguish named renderable elements from states, variants, flows and vocabulary annotations. Retain useful names and their relationships; do not delete or reclassify elements to evade module/review coverage. An element’s local module interface and its package-level public export remain separate decisions.

## Named UI modules and review coverage

Every named renderable UI element, including a screen, region, composition or control, has clear implementation ownership, a small semantic interface and discoverable runnable review coverage. Apply the project's requirements for owning directories, module entries, colocation and tooling. Nested directories are appropriate when the project requires modules and ownership is local. A single-file application can identify named regions and operable review states in that implementation; a focused revision does not authorize a directory migration. Explicit project requirements, such as a per-element directory, semantic entry file and colocated story, remain mandatory.

Expose a small, truthful semantic interface that hides meaningful implementation complexity. Export the component and only the inputs, actions, projections or types its consumers need. Keep rendering helpers, private state/machine events, effects and fixture plumbing inside their owners. Production consumers and review scenarios use supported module/package entries. Preserve deliberate package exports without exposing every element globally.

Review scenarios operate the actual production element through that interface with realistic controlled inputs and supplied dependencies. Cover important states and variants within the owning element’s scenarios; do not manufacture a component, directory or machine for each state. A flow or non-renderable annotation links its participating elements and review entries instead of requiring an artificial component. Compositions retain enough context to verify relationships, while each named child remains directly reviewable. Copied markup, static captures or proxy demos do not replace required runnable production-module coverage. Static annotated comparisons can still support decisions that do not depend on interaction.

Keep review-only fixtures, service simulations and test utilities out of production interfaces and runtime dependency paths. Verify discoverability, reset paths, important states and in-context behavior with the selected tooling. Preserve the running application’s behavior, dependency direction and lifetime ownership while moving files and updating imports.

Setup creates this coverage for the existing named interface. Planning identifies affected/new modules and states; design uses and maintains their review scenarios for exploration and accepted targets; tasks includes implementation, inventory links and verification in handoffs. Renaming, splitting or moving an element updates its module, review coverage, consumers and affected `DESIGN.md` links together. Record material boundary decisions in the owning references/ADRs with their actual status; code-discoverable path changes need no new ADR.
