---
name: interface-first-tasks
description: Turn a reviewed slice into focused Task Manager tickets with dependencies and fresh-agent handoffs, or prepare sequential execution of its epic. Does not choose the next slice's scope.
---

# Turn reviewed scope into executable work

Read AGENTS.md, the selected plan, reviewed flow, accepted design changes and vocabulary, and relevant implementation. Expand context only for a named execution question. If scope or visual decisions are unresolved, return them to planning. If work requires an intermediate human decision or a long feedback cycle, propose smaller slices before creating dependent tickets.

Use task-manager for CLI operations and claim safety. A request to create tickets authorizes conversion of reviewed scope without another hierarchy approval. Task creation starts no agents or implementation.

## Create focused handoffs

- Inspect existing tickets and extend them rather than duplicating work. Each slice is an epic; split tasks/subtasks for coherent outcomes, ownership, prerequisites, or risk, not merely technical layers.
- Keep shared scope, plan/design/vocabulary links, constraints, real/simulated boundaries, execution policy, and integrated demonstration on the epic. Each ticket contains only its outcome, affected files or capability, ownership, prerequisites, completion criteria, focused verification, and task-specific failures or exclusions. Link shared context instead of copying it; fresh workers must read it.
- Explicitly ticket updates to the accepted design reference and vocabulary identified at planning approval. Sequence those updates before dependent interface implementation so agents share the approved target. Track later approved refinements there too; complete the updates before slice closure and subsequent slice planning.
- Record genuine prerequisite edges; hierarchy and sequential scheduling do not imply dependencies. Give integration, design comparison, and demonstration explicit ownership. Include one final human review ticket. A required decision before further implementation marks the end of this slice, not an intermediate review gate within it.
- Create parents before children, retain returned IDs, and verify stored handoffs, executors, hierarchy, dependencies, and first actionable work. Report the epic ID and next ticket. Keep Task Manager as the execution source of truth; create no duplicate task list.

## Enforce fresh-agent execution

When execution is requested, the coordinator uses this mandatory policy:

1. Select one actionable agent ticket within the epic, respecting prerequisites. Dispatch a fresh independent agent with fresh task context for each ticket; never reuse a worker across tickets. The coordinator may persist. Give the worker the exact ticket and shared-context links, explicit ownership, and instructions to preserve others' edits. Agree who owns the Task Manager claim.
2. Work sequentially. Verify returned behavior, evidence, and ticket status before dispatching the next fresh agent. Report blockers; continue only genuinely independent work. Respect repository hooks and the requested commit policy.
3. Use focused checks during edits and required completion gates. Repeat checks only when changes, failures, or unresolved risks justify them. Bound automation calls and retries; report inspection limits instead of looping indefinitely. Never replace required real-capability evidence with simulated success.
4. Demonstrate the integrated slice against its approved design and operable outcome, then stop for final human review. Refine feedback within scope; revise planning when scope materially changes. Keep implementation completion distinct from acceptance. Close only after required work, design-reference updates, and user acceptance are satisfied.
