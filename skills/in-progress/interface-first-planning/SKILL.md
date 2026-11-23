---
name: interface-first-planning
description: Shape or revise a small demonstrable slice, review its annotated flow and design changes, and finalize a compact plan. Use when choosing scope; task decomposition belongs to interface-first-tasks.
---

# Plan a short feedback loop

Start with what the user can operate and evaluate. Read AGENTS.md, the current slice, latest feedback, and relevant implementation and accepted design. Distinguish planned, implemented, and accepted behavior. Expand reading only to answer a named question.

## Shape and review the experience

- Recommend the smallest outcome delivering the user's intended value. Explain effort and uncertainty separately; keep adjacent features deferred unless this outcome requires them. Describe a concrete before-and-after journey before asking for a choice.
- Size the entire loop: implementation, verification, demonstration, and feedback must be quick enough to preserve momentum. If work needs a human decision before continuing, end the slice at that demonstrable decision; subsequent work becomes another slice. Investigate uncertain capabilities early without making future capabilities prerequisites.
- Show annotated affected screens in flow order before finalizing scope: what changes, why, actions, and results. Use the latest accepted design and actual application as the baseline; label proposed overlays, fixture data, and simulated behavior. Make uncertain interactions operable when static captures cannot settle them. Missing preview access leaves visual review pending while independent planning proceeds.
- Establish or reuse a compact UI vocabulary alongside the design reference: named regions, controls, states, and behaviors, anchored to annotated screens where useful. Resolve ambiguous terms; distinguish interface names from code identifiers.
- At the planning approval gate, review the exact design changes with the scope. Identify the owning design reference, affected screens and vocabulary, and updates required to carry the approved direction forward. Reuse prior decisions; seek review only for unresolved or materially changed choices. Approval establishes the design target, not implementation evidence.

## Record one compact plan

Read and adapt the [slice-plan template](assets/slice-plan.md) when recording the plan. Preserve the project's existing slice IDs and artifact conventions, and keep one authoritative plan. Aim for one page plus visuals, linking shared requirements:

- **Outcome and flow:** Operable result, reviewed screens, decisions, and design-reference updates to ticket alongside implementation.
- **Capability change:** Real now, becoming real, remaining simulated, and the existing seam where relevant.
- **Scope and risk:** Included/deferred behavior, consequential failures and recovery, requirements, and evidence needed before dependent work.
- **Demonstration:** Short path to evaluate the result, focused verification, and the final user feedback checkpoint.

Planning ends with the reviewed slice contract. During authorized task creation, each slice becomes a Task Manager epic including its design-reference updates. Planning alone starts neither ticket creation nor implementation. Design exploration is available when needed, not an extra mandatory ceremony. Simulations prove interaction only; a slice does not silently amend final product requirements.
