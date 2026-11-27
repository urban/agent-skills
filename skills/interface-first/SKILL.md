---
name: interface-first
description: Iterate on UI design and assess or repair fidelity using the actual application interface, matched comparisons and scoped feedback. Use for visual or interaction exploration/refinement, accepted-target review, and the UI review readiness needed for that work, directly or within another workflow.
---

## Rules

- Inspect and operate the existing interface before creating a variant or separate component. Try supported states, styles, configuration and compositions; name the unmet requirement that justifies an addition. Build proposals from actual application components/styles/compositions, with controlled dependencies through existing seams.
- Use the [UI contract](references/workflow-contract.md) for semantic ownership and runnable review coverage, the [review contract](references/review-contract.md) for matched evidence and scoped feedback, and [design records](references/design-records.md) for accepted targets and relevant rationale. Read affected entries and deeper links for the current question, not the whole project catalog.
- Preserve settled choices, surrounding behavior and unrelated edits. Associate feedback and approval with exact units/states and reconstructable source revisions. Keep proposed design, accepted target, implementation, verification and human acceptance distinct.
- Before choosing a new variant, wrapper, component or review tool, discover and read `principle-reuse-before-reinventing` when available. Resolve its actual entrypoint through host discovery/library inventory; do not assume a sibling install. The inspect/reuse rule above applies when this skill is installed alone.
- Read applicable [local principles](#references) for the decision. Use project visual guidance and owning decisions with them; explain consequential tradeoffs rather than scoring principles.

## Constraints

- Own UI design iteration and fidelity assessment/authorized repair. General project setup, planning, tracker task creation, execution and overall integration/completion belong to the caller (for example Work Mode). UI iteration may edit operable proposals and fidelity may report or repair within the assignment's authorization; these are valid specialist work.
- Do not require Work Mode, a ticket, a new document pack, a whole-project foundation, or a separate agent/chat to use this skill. Missing prerequisites justify focused preparation only; a broad UI foundation must be within the request.
- Do not infer new authority from prototype success, passing checks, silence or a saved target. Reuse existing approval within its actual scope; ask only for a consequential unresolved choice or additional authorization.
- Label simulations. Operable UI does not establish provider feasibility, persistence, real device behavior or production acceptance. Review-only dependencies and controls stay out of production interfaces/navigation and runtime outputs.
- Do not rename units or turn states into components to evade coverage. Local semantic interfaces do not imply public package exports. Preserve architecture invariants, supported imports, behavior/lifetime authority and affected consumers.
- Host/project permissions and execution policy govern tools and any delegation. Naming a skill/file does not load it; explicitly read selected entrypoints/leaves. This skill imposes no model, worker or concurrency policy.

## Requirements

Recover the requested UI outcome or question, affected units/states, current implementation, existing targets and feedback, settled decisions, and authorization including whether repairs are permitted. Use the project's design entry point (normally root `DESIGN.md`) and [project bindings](references/project-bindings.md) to find affected sources/review tools. If no baseline or accepted target exists, say so; do not invent one. A caller supplies relevant context and the expected result; direct use recovers the same from the request and project.

## Workflow

1. **Scope the UI assignment.** Identify design iteration, fidelity assessment/repair, or review readiness below. Preserve the exact approval state and the caller's expected result. A focused refinement does not reopen the surrounding design.
2. **Operate the actual interface.** Resolve launch/readiness and affected source/review paths. Fill missing prerequisites through [review readiness](references/review-readiness.md) only to the required depth. Report unavailable access and continue useful independent work; do not claim inspected behavior that was not operated.
3. **Run the selected procedure.** Read [design iteration](playbooks/design.md) for exploration/refinement and matched feedback; read [fidelity](playbooks/fidelity.md) for comparison with an accepted target and report or scoped repair. UI review preparation follows [review readiness](references/review-readiness.md), returning gaps when broader setup is needed. Compose only the relevant parts.
4. **Preserve and return.** Reconcile affected target/map/decision records within authorization. Return the actual UI result, approval state, source/revision/artifact references, evidence, simulations/limits, unresolved choices and implications. The caller consumes it and resumes planning, integration or other authorized work; specialist completion is intermediate when the user requested more.

## Gotchas

- If a proxy demo replaces the production component, the comparison can pass while the actual interface differs. Import and operate the real modules/styles through supported seams.
- If before/after use different content or state, incidental changes masquerade as design improvement. Match fixture, viewport, timing and reset paths, and explain unavoidable differences.
- If feedback loses its units or revision, a local approval silently becomes permission to redesign adjacent consumers. Preserve scoped provenance and settled choices in the next delta.
- If an attractive operable proposal becomes production acceptance, simulated dependencies acquire unearned authority. Return what was demonstrated and what remains unproven.
- If every spacing correction starts a full design catalog, preparation consumes the assignment. Repair affected review prerequisites; reserve broad coverage work for a requested foundation.
- If fidelity review silently changes the target to match implementation, defects disappear from the record. Repair within authorization or return the actual deviation for a decision.
- If this specialist declares a broader feature finished, production wiring and verification can remain undone. Return UI findings/refinements to the owning workflow and preserve completion limits.

## Deliverables

The assigned UI design, comparison, fidelity findings/repairs or review-readiness result, with editable/operable source where relevant, proportionate captures and actual feedback/status. Reuse owning records and the [review template](assets/review-template.md) when useful. Include exact provenance, verified behavior and limits, unresolved decisions and implications for the caller; create no separate completion file by default.

## References

- [Project bindings](references/project-bindings.md): Read when: resolving project paths, UI review tools and operating instructions.
- [Review readiness](references/review-readiness.md): Read when: actual components or affected states lack usable review access, or UI preparation is assigned.
- [UI contract](references/workflow-contract.md): Read when: naming elements, maintaining ownership/module interfaces and runnable review coverage.
- [Design records](references/design-records.md): Read when: preserving targets, scoped approval, rationale or affected map links.
- [Review contract](references/review-contract.md): Read when: constructing comparisons, incorporating feedback or reporting fidelity/status.
- [Decomposition rubric](references/decomposition-rubric.md): Read when: assigning UI behavior/lifetime authority or reuse/package placement.
- [UI coordination](references/delegation.md): Read when: permitted workers build isolated alternatives or critique a shared review surface.
- [Operable outcomes](principles/operable-outcomes.md): Read when: choosing what the UI comparison needs to demonstrate.
- [Compare equivalent states](principles/compare-equivalent-states.md): Read when: a comparison risks misattributing content, state or timing changes.
- [Preserve settled decisions](principles/preserve-settled-decisions.md): Read when: feedback or shared-control changes could reopen approved choices.
- [Explore before committing](principles/explore-before-committing.md): Read when: consequential interaction/visual alternatives remain unresolved.
- [Proportionate evidence](principles/proportionate-evidence.md): Read when: selecting review evidence or avoiding unnecessary artifacts/checks.
- [Semantic boundaries](principles/semantic-boundaries.md): Read when: UI naming, state ownership, reuse or placement need judgment.

## Deterministic Validation

Run `python3 <skill-dir>/scripts/check-links.py` to check bundled Markdown paths and heading fragments; pass additional files/directories to check project references. It does not check external URLs or runtime behavior. Run helper tests with `python3 -m unittest discover -s <skill-dir>/tests` when the helper changes.
