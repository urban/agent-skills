---
name: interface-first-tasks
description: Decompose selected interface-first development slices into executable tasks with real/simulated capability transitions, dependency edges, acceptance evidence, and demonstration handoffs. Use when creating or revising tasks from an existing slice plan. Does not create a new product roadmap, implement tasks, or publish tickets without authorization.
---

## Rules

- Treat the selected slice's user-visible outcome and requirements as the contract; organize technical work underneath that outcome.
- Carry real/simulated capability transitions into tasks so executors know what they are replacing, retaining, and proving.
- Give each task enough context to execute in a fresh session: source references, current state, scope/owner, dependencies, observable completion, and verification.
- Prefer cohesive task boundaries with explicit responsibility and real prerequisite edges. Independence is about actual resource/code/data readiness, not an arbitrary technical-layer order.
- Include integrated demonstration and regression evidence before declaring a slice complete; component task completion alone is insufficient.
- Preserve the project's task format and identifiers. Use a compact local Markdown artifact when no task-system destination is authorized.

## Constraints

- Do not invent requirements, settle unapproved product/architecture choices, or silently reorder the roadmap while decomposing it. Surface material conflicts as proposals.
- Do not treat simulated success as real provider, filesystem, hardware, acoustic, or installed-product acceptance.
- Task authoring does not authorize execution, source changes, downloads, deployment, or publication to an external tracker.
- Do not require a sibling skill, a particular tracker, a new document hierarchy, or a fixed number of tasks. Accept a suitable slice plan regardless of how it was produced.

## Requirements

- Selected slice identifiers or an unambiguous scope in an existing plan, plus its requirements and current decision status.
- Enough current implementation context to identify existing contracts, supplied services, relevant ownership, and dependencies.
- A task destination and format inferred from project conventions or the request; resolve only missing choices that materially change the output.

## Workflow

1. **Recover the selected contract.** Read applicable instructions, the selected slices, requirement/acceptance sources, and available implementation state. Identify completed work, current simulations, accepted decisions, and open evidence gates. If no slice outcome exists, ask for that scope instead of inventing a roadmap.
2. **Establish entry and exit states.** Read the decomposition reference. Record which services are real before and after the slice, which controlled scenarios remain useful, what must keep working, and which capability evidence is still required. Name only assumptions that affect execution.
3. **Decompose by responsibility.** Adapt the task-breakdown asset to the established task format. Include needed contract/domain work, adapter or simulation changes, interface behavior, meaningful failure/recovery handling, and integration evidence. Reuse existing capabilities instead of recreating scaffolding. Split tasks only when ownership, prerequisites, risk, or reviewability justify it.
4. **Connect prerequisites.** Preserve existing IDs and add explicit dependency edges. Check for missing targets, cycles, and artificial ordering. A demonstration depends on every task needed for that path. Allow parallel work only when contracts and ownership permit it; a task graph is not authorization to launch agents.
5. **Write executor handoffs.** Put the outcome, source paths, scope and exclusions, required services, real/simulated state, relevant failure semantics, acceptance evidence, and applicable verification commands on each task or its referenced slice contract. Avoid copying the entire product spec or prescribing incidental internals. Surface unresolved blockers only on dependent work.
6. **Validate and persist.** Check requirement coverage, real/simulated transitions, truthful statuses, executable dependencies, and the user's feedback checkpoints. Run available task/document checks. Save only to the authorized destination and report the first executable work, blocked work, and slice demonstration. Stop at task creation unless execution was separately requested.

## Gotchas

- If tasks are merely grouped as UI, backend, and tests, agents finish layers without a usable journey. Keep slice membership and a final integrated demonstration explicit.
- If a task says only replace the mock, the executor changes transport, semantics, and state ownership together. Identify the existing contract and the real capability it must supply.
- If integration is an unowned final note, every component can pass while the product flow fails. Assign demonstration/integration work with dependencies on the actual path.
- If all missing decisions block all tasks, available UI or contract work stalls. Bind each unresolved question to the work that depends on its answer.
- If a fabricated service result satisfies a real-recognition criterion, status tracking overstates delivery. State the required real mechanism and retain honest simulation labels.
- If tracker publication or implementation starts during decomposition, planning scope becomes an unexpected mutation. Produce the requested task artifact and reuse only explicit authorization for further action.
- If fresh agents receive a task title without the slice's state and sources, they reconstruct intent and drift. Preserve a compact handoff plus stable links to the authoritative contract.

## Deliverables

- Executable tasks for the selected slices in the authorized format, with stable IDs, responsibility/owner, prerequisites, acceptance evidence, and verification/handoff context.
- A clear entry/exit capability inventory, requirement coverage, retained simulations, unresolved decisions, and their affected tasks.
- Integrated demonstration criteria and the next review checkpoint, with task completion distinguished from slice acceptance.

## References

- [Decomposition and Scribe example](./references/decomposition-and-scribe.md). Read when: establishing capability transitions, choosing task boundaries, connecting dependencies, or preparing executor handoffs.
- [Approach and research](./references/approach-and-research.md). Read when: explaining why tasks follow demonstrable journeys, adapting the method, or distinguishing simulation from real capability evidence.

Use [the task-breakdown asset](./assets/task-breakdown.md) when drafting; preserve the project's task conventions.
