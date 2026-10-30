---
name: interface-first-design
description: Design and refine runnable interactive UX/UI prototypes, then capture their behavior, visual decisions, coverage, and review status as implementation references. Use when exploring an interface, iterating on user journeys and visual direction, or preserving an approved design baseline. Owns design artifacts, not development roadmaps, task decomposition, or production implementation.
---

## Rules

- Begin with what the user needs to operate and evaluate. Make important journeys interactive with realistic content before expanding visual polish or screen coverage.
- Design behavior and appearance together: navigation, timing, feedback, cancellation, recovery, and preservation of user work belong in the interface contract.
- Keep simulated capabilities explicit. Separate what can be operated, what is actually implemented, what was checked, and what the user approved.
- Scale fidelity and documentation to the decision. Reuse the project's design system and artifact conventions; propose alternatives only where direction is unresolved.
- Use controlled scenarios through a small command/state or service boundary where practical. Describe the seam for later integration without imposing speculative production architecture.
- Keep feedback traceable to the affected interaction or visual decision. Refine accepted work incrementally and surface conflicts with requirements rather than quietly changing scope.

## Constraints

- Do not invent requirements, approval, usability findings, or technical feasibility. A simulated success does not establish real capture, AI quality, persistence, privacy, or installed-product acceptance.
- Design work authorizes the requested prototype and supporting artifacts, not production integration, deployment, paid services, external user research, tracker publication, or unrelated specification changes.
- Do not make completion of the entire design a prerequisite for thin real integrations. Identify uncertain capabilities and affected decisions early; report needed feasibility evidence without starting unrequested experiments.
- Preserve existing approved baselines and unrelated work. Record proposed revisions separately until the user accepts the change; do not delete earlier artifacts as routine cleanup.
- Do not require sibling skills, a particular framework, a visualization host, or access to Scribe. Accept suitable requirements and planning inputs however they were produced.

## Requirements

- Product intent, primary users and tasks, target interaction surface, and relevant requirements or existing behavior.
- Available design references, brand constraints, approved decisions, and the requested design or revision scope.
- An artifact destination and preview method inferred from the request and project conventions; recover existing material before asking for missing consequential choices.
- Available tools for running and inspecting the prototype. If inspection cannot run, record the limitation rather than inventing verification evidence.

## Workflow

1. **Recover the design brief.** Read applicable instructions, requirements, existing designs, and relevant implementation patterns. Establish users, tasks, platform, scope, accepted decisions, and technical uncertainties. Ask only questions that materially change the experience; state reversible assumptions and proceed with independent work.
2. **Map journeys and states.** Identify entry points, meaningful actions, transitions, and outcomes. Include relevant empty/loading/invalid/canceled/failed/recovered states and what happens to user work on exit. Assign stable journey/behavior identifiers when useful. Map requirements to these behaviors, leaving missing or disputed scope visible.
3. **Choose the first demonstrator.** Make the smallest useful journey operable using realistic content and controlled services. Choose a lightweight standalone prototype or the project's existing preview environment based on the interaction and review needs. Keep prototype-only scenarios distinct from product navigation. Present a core-journey checkpoint with preview access, real/simulated scope, and focused feedback needs.
4. **Refine the visual direction.** Resolve hierarchy, typography, color, spacing, control geometry, and representative layouts in the working prototype. When direction is open, compare a small number of meaningful alternatives on a representative view; otherwise develop the accepted direction. Review a refined-interface checkpoint and incorporate feedback into affected states, not just the showcased screen.
5. **Complete the agreed experience.** Expand to the remaining in-scope journeys and consequential alternate states. Actions should demonstrate coherent behavior, including cancellation and recovery. Describe simulated inputs/outputs and ownership well enough to replace them later. Maintain a runnable preview as feedback changes earlier interactions.
6. **Verify and reconcile.** Exercise actual controls and transitions in the available browser or surface, inspect screenshots, and check relevant sizes, keyboard/focus behavior, scrolling, and content extremes. Check that dismissed failures remain unresolved until recovery succeeds and that completion follows the demonstrated prerequisite states. Distinguish inspection, automated assertions, human feedback, and untested claims. Record results against the artifact revision actually checked.
7. **Capture and hand off.** Adapt the design-reference asset to existing artifacts. Preserve editable source, a runnable preview, representative state captures, behavior, visual decisions, requirement coverage, verification evidence, and current review status. Present the complete-design checkpoint. Record approval only from explicit user evidence and preserve its scope and artifact identity. Report proposed requirement changes and remaining technical proof; update authoritative specs/plans only if authorized. Hand off source paths, accepted behaviors, simulated seams, open decisions, and evidence limits for later slice planning or task creation; stop at the requested design scope.

Checkpoint names are defaults, not mandatory ceremonies. Reuse existing agreements and approval, combine checkpoints for small work, and pause only dependent decisions while continuing independent work. A request to revise one interaction does not restart the entire process.

## Gotchas

- If only attractive screens are drawn, transitions stay implicit and implementation invents them. Make the principal journey operable and include consequential cancellation and recovery before calling the design complete.
- If a scenario selector becomes product navigation, test conveniences leak into the shipped scope. Visually separate preview controls and exclude them from the product behavior contract.
- If Cancel clears a simulated failure, the interface appears recovered without any corrective action. Preserve the unresolved state and demonstrate a deliberate way to reopen recovery.
- If realistic fixtures imply real processing, reviewers mistake visual fidelity for capability evidence. Identify fixture provenance and simulated mechanisms; distinguish measured data from illustrative labels, timing, and content.
- If screenshots and source belong to different revisions, approval becomes ambiguous. Regenerate affected captures or label them historical, and tie verification and approval to an identifiable baseline.
- If the most complex screen receives all the polish, setup, long content, errors, and narrow layouts diverge. Apply accepted visual rules across representative states and inspect overflow and focus behavior.
- If an earlier project's palette, typography, and page structure become the template, unrelated products inherit its assumptions. Reuse the review process and artifact contract while deriving visual and interaction decisions from the new brief.
- If a polished simulation delays difficult integration, expensive UI assumptions remain untested. Name the affected capability and needed proof early, and allow independent design and implementation slices to proceed.

## Deliverables

- A runnable interactive design for the agreed scope, with editable source, realistic content, operable journeys, representative screenshots or equivalent surface captures, and clear simulated boundaries.
- A proportionate reference covering visual decisions, behavior and alternate states, requirement coverage, actual verification, unresolved questions, and review status; sections may share one document.
- A compact handoff identifying accepted versus proposed decisions, baseline identity, simulation seams, remaining capability evidence, and the next review or implementation decision. Design approval does not certify production readiness.

## References

- [Scribe example and composition boundaries](./references/scribe-and-handoff.md). Read when: adapting the Scribe process, deciding how much evidence to retain, or handing design outcomes to planning and task workflows.

Use [the design-reference asset](./assets/design-reference.md) when capturing a checkpoint or baseline; adapt its fields to the project's existing documents rather than creating a parallel source of truth.
