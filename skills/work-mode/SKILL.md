---
name: work-mode
description: Recover intent, decisions, constraints, and authorization from a prompt, conversation, or session evidence; select a playbook and carry scoped work through completion. Use when starting or resuming agent work through setup, brainstorming, planning, task creation, execution, bounded prototypes, codebase reviews, or retrospectives, with specialist calls where needed.
---

## Rules

- Reconstruct the desired outcome before selecting a procedure. Preserve settled choices, their rationale, and existing authorization; ask only about consequential gaps the available context cannot resolve.
- Enter at the current decision. A previous design, experiment, or review may already supply its prerequisites; do not restart discovery or require every lifecycle stage.
- Carry authorized work through execution and verification, whether acting directly or coordinating permitted subagents. A plan or delegation is not completion of an implementation request.
- Keep evidence, interpretation, proposed choices, accepted decisions, implementation, and verification distinct. Preserve enough actual context for a fresh executor, rather than merely naming a skill or summarizing a conclusion.
- Load the selected playbook and expertise for the decision at hand. Architecture, TypeScript, Effect, principles, and other standards stay in their own skills; honor the selected workflow's reading requirements without loading the whole library by default.
- Before proposing or implementing a new variant, wrapper, component, service, adapter, or tool, select `principle-reuse-before-reinventing` through [skill routing](references/skill-routing.md) when available. Inspect and exercise the existing capability, try supported configuration and composition, and name the unmet requirement that justifies an addition. Keep this decision focused on the requested scope.

## Constraints

- Do not expand scope through a transition, create tickets automatically, or infer approval from silence, a saved artifact, passing checks, or prototype success.
- Do not ask again for approval already covering the work. Ask for a material unresolved decision or genuinely additional authorization; host and project permissions still apply.
- Do not replace specialist workflows with a generic pipeline. Specifications route to `to-spec`, engineering decision records to `write-adr`, and UI design iteration and fidelity assessment to `interface-first`. Work Mode owns general setup, planning, task creation, execution and overall completion.
- Do not require delegation or impose model, concurrency, worker-reuse, or scheduling policy over host/project rules. Local execution is valid.
- Do not treat a source mention as access to its contents, a worker report as verified integration, or a missing tool as proof the underlying capability is absent.

## Requirements

A prompt, an ongoing/previous conversation, or session evidence identifying work to recover. Use relevant project instructions, owning artifacts, current code, prior decisions, and tools when available. Name inaccessible history and its effect; do not invent it. No new document pack, tracker, or handoff file is required.

## Workflow

1. **Recover context.** Use [context intake](references/context-and-handoff.md) to establish outcome, scope, decisions/rationale, authorization, evidence, open questions, and the actual current state. Inspect sources to answer named questions. Continue independent work while a dependent decision is pending.
2. **Choose the next work.** Use the table below, respecting an explicit playbook choice. If the request is already executable, select execution; do not force brainstorming, planning, setup or ticket creation first. Resolve external skills through [skill discovery](references/skill-routing.md).
3. **Execute and follow through.** Read only the selected playbook(s) and their required resources. Invoke specialists at the step that needs them using the [call-and-return instructions](references/skill-routing.md#call-and-return-within-a-playbook), consume the result, and resume the owning playbook. This need not create a separate agent or chat. Use [coordination](references/coordination.md) when handing off or delegating. Evaluate transitions against the recovered current outcome and authorization, including explicit scope changes: continue when already covered, propose genuinely new work otherwise. A completed playbook is a milestone when the user authorized a larger outcome.
4. **Close accurately.** Verify the actual result against the selected scope. End at completion, a genuine blocker, or a user decision; state which one. Preserve continuation context in the existing project record or a concise handoff when another executor needs it.

| Current need | Read / route | Expected result |
| --- | --- | --- |
| Prepare a project or fill concrete readiness gaps | [Setup](playbooks/setup.md) | Proportionate workspace and run/check readiness |
| Shape a deliverable and resolve its dependencies | [Planning](playbooks/planning.md) | Scoped plan with decisions, evidence and remaining uncertainty |
| Create tracker handoffs from scoped work | [Create tasks](playbooks/create-tasks.md) | Read-back tasks and genuine prerequisites; no implementation |
| Implement or repair authorized work, ticketed or direct | [Execute](playbooks/execute.md) | Integrated result and focused verification |
| Resolve an open-ended idea or unsettled design direction | [Brainstorming](playbooks/brainstorming.md) | Reviewed direction, rationale, and explicit remaining decisions |
| Obtain evidence about a specific uncertain choice | [Bounded prototyping](playbooks/bounded-prototyping.md) | Inspectable findings with limits and decision implications |
| Assess existing codebase quality or ease of future change | [Codebase review](playbooks/codebase-review.md) | Prioritized improvements through `continuous-improvement`'s codebase lens |
| Learn from how actual work was performed | [Retrospective](playbooks/retrospective.md) | Evidence-backed improvements through `continuous-improvement`'s process lens |
| Author a spec, engineering rationale, or UI-specific result | [Specialist routing](references/skill-routing.md) | Existing `to-spec`, `write-adr`, or `interface-first` workflow |

Patch/PR review assesses a particular diff and its regressions; use the project's patch-review guidance directly. Do not silently turn it into a codebase audit. Both improvement lenses may be selected when requested, with one consolidated backlog.

## Gotchas

- If the latest message replaces the whole recovered task, a status question or correction can erase the original goal. Treat it as steering unless it actually cancels or changes the outcome.
- If every request starts at brainstorming, approved implementation becomes another proposal. Recover prior decisions and enter the work that remains.
- If a handoff says only “use the spec,” the next executor loses approval scope, exceptions, and why a boundary exists. Include the actual commitments, rationale, locations, and pending decisions.
- If a prototype's success becomes adoption, shortcuts acquire production authority. Return evidence to the owning decision and continue only within authorization.
- If a broad review follows only a recent diff, local observations masquerade as codebase coverage. Map the requested scope and disclose what was not inspected.
- If a retrospective reads only source code, plausible delays and motives become invented history. Use actual session evidence and limit conclusions when it is missing.
- If specialist or delegated completion closes the parent task, integration and verification can remain undone. Check the owned result against the original completion conditions.
- If recording a decision creates a new approval gate or document hierarchy, preservation stalls authorized work. Update the owning record proportionately and preserve the existing authority.

## Deliverables

- The requested result, with proportionate artifacts and evidence from the selected playbook or specialist workflow; reuse the project's owning records and destinations.
- A concise report of what completed, where the result lives, what was verified and its limits, and any blocker or precise user decision still needed. Distinguish recommendations from executed changes.
- When continuing elsewhere: sufficient context to act, including accepted scope, rationale not recoverable from code, existing authorization, current state, and the next action. Internal working notes stay local unless another destination was requested.

## References

- [Context and handoff](references/context-and-handoff.md): Read when: recovering session intent, resolving conflicting evidence, or preparing a fresh executor.
- [Skill routing](references/skill-routing.md): Read when: locating specialist or review methodology, selecting technical expertise, or handling an unavailable skill.
- [Coordination](references/coordination.md): Read when: deciding whether to delegate, assigning ownership, integrating work, or transitioning between executors.
