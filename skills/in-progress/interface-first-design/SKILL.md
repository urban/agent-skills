---
name: interface-first-design
description: Explore or refine interface behavior and appearance through annotated screens and operable previews. Use for design decisions and implementation fidelity; does not choose slice scope or create tickets.
---

# Refine the selected experience

Read AGENTS.md, the affected slice or brief, latest feedback, and the owning accepted design. Expand context only for a specific question. Reuse accepted navigation, components, typography, and interactions; explore alternatives where direction is unresolved.

## Make decisions concrete

- Show annotated screens in flow order, connecting actions to results and explaining changes. Use actual application captures or accepted references; label proposals and simulations. Prototype captures do not establish implementation.
- Make a small operable preview when the decision depends on interaction, timing, scrolling, cancellation, or recovery. Use realistic content and controlled services through a narrow seam; separate preview controls from product navigation.
- Maintain a compact shared vocabulary with the design: names for regions, controls, states, and behavior. Use these consistently in reviews and handoffs; add terms only when they clarify communication.
- Review consequential design changes during planning before task creation. Identify affected reference updates as explicit work alongside implementation. Keep proposed revisions distinct until approved; reuse approval within its scope.

## Preserve the accepted direction

The design reference evolves through approved slices. Update affected editable screens, interactions, and vocabulary to reflect approved changes, retaining enough revision context to distinguish the target from the running application. Carry approved refinements into that reference before planning the next slice. Avoid parallel design authorities or a comprehensive archive rebuild.

During authorized implementation, compare the changed running interface directly with the current approved target in matching states. Check visual details, copy, controls, timing, relevant layout sizes, keyboard/focus behavior, and consequential failure/recovery states. Correct unexplained differences before presenting the result. Bring consequential deviations back for a decision; passing tests alone does not establish fidelity. Keep the application runnable and state inspection limits honestly.

Deliver editable source or the existing preview, focused annotated captures, and concise decisions with the owning artifacts. Keep evidence proportional to the decision. Design work authorizes the requested artifacts; production integration, tickets, and deployment require their own authorization.
