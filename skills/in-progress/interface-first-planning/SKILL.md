---
name: interface-first-planning
description: Plan interface-first, iterative and incremental development with simulated services progressively replaced by real implementations. Use when shaping a project or feature into demonstrable slices, choosing an early interactive experience, or revising a slice roadmap from feedback. Produces a slice plan, not implementation tasks or application code.
---

## Rules

- Begin with the experience the user needs to operate and evaluate; choose a desktop UI, web interface, CLI, or other appropriate surface.
- Combine breadth and depth: expose important journeys early, then add real capabilities through small end-to-end increments while revisiting earlier decisions.
- Supply simulated services through the intended application contracts so that real implementations can replace them without creating a second UI or workflow.
- Define slices by observable outcomes, including a demonstration and feedback opportunity, rather than organizing the roadmap solely by technical layers.
- Preserve the distinction between an interactive demonstrator, a real capability, and an accepted release; identify what each demonstration actually establishes.
- Scale the plan to the work and reuse the project's existing planning artifacts, identifiers, architecture, and review conventions.

## Constraints

- Do not invent product requirements, redesign an approved baseline, or weaken feasibility/privacy/delivery gates to make an intermediate slice look complete.
- Do not turn the whole interface into a prerequisite for any real integration. Investigate uncertain capabilities early and establish a thin real path as soon as useful.
- Planning does not authorize implementation, experiment execution, tracker writes, deployment, installation, or changes to global agent instructions.
- Do not require this skill for small fixes or force a graphical interface onto a CLI or capability whose useful surface is elsewhere.

## Requirements

- A product or feature intent, relevant requirements/designs, and available evidence about existing behavior.
- The intended planning scope and destination, resolved from the request and repository conventions.
- Current acceptance decisions and technical uncertainties where known. Recover these from project/session context before asking for missing material choices.

## Workflow

1. **Recover the starting point.** Read applicable instructions, requirements, approved designs, and existing plans. Inspect only the code or configuration needed to distinguish implemented, simulated, and proposed capabilities. Record consequential assumptions without silently adopting them.
2. **Shape the experience.** Identify key journeys, important feedback and failure states, and the smallest interaction surface that makes the product intelligible. Include screen/command flow sketches only when they resolve ambiguity. Consult the research reference when explaining or adapting the approach.
3. **Choose simulation seams.** Identify service boundaries, inputs/outputs, state ownership, and which controlled implementations make early journeys interactive. Preserve production command/state paths where feasible. Keep assumptions visible and retain scenarios useful for later regression checks.
4. **Sequence demonstrable slices.** Adapt the slice-plan asset to the established plan. For each slice include entry/exit capability states, requirements, real/simulated scope, a demonstration, acceptance evidence, and dependencies. Start with a usable shell and journeys where appropriate, then select small real integrations. Include refinement work, not only feature additions.
5. **Place uncertainty and feedback.** Put small feasibility investigations before the expensive work that depends on their conclusions. Name the questions, required evidence, and affected slices; do not prescribe an entire benchmark or block unrelated UI progress. Use the user's agreed feedback checkpoints and record how discoveries can change the remaining roadmap.
6. **Review and preserve the plan.** Check that each slice leaves the agreed surface runnable, capabilities progress coherently, and final requirements remain covered. Update only the authorized planning artifact, verify local links and available document checks, and report proposals versus accepted decisions. Hand off selected slice IDs and their contracts for task decomposition; stop at the requested planning scope.

## Gotchas

- If the plan completes every screen before testing any difficult integration, backend assumptions harden unnoticed. Keep early UI breadth modest and schedule a thin real path plus risk-focused probes.
- If simulation lives inside UI event handlers, swapping providers creates a second workflow and discards early feedback. Route controlled behavior through the same commands and service contracts.
- If every increment only adds a feature, confusing earlier behavior survives untouched. Include refinement prompted by demonstrations and retain the decisions that changed the sequence.
- If a realistic simulation is reported as implemented AI or reliable capture, apparent progress hides missing evidence. State which mechanism was simulated and what must be observed with the real provider.
- If technical layers become milestones, the user cannot operate the system until the end. Group enabling work under a journey that ends in an integrated demonstration.
- If an intermediate mic-only or simplified mode becomes the final requirement, staged development silently shrinks scope. Label developmental limitations and retain later slices for the full outcome.
- If a new roadmap duplicates an existing plan, agents follow conflicting versions. Integrate with the project's authoritative artifacts and retain stable identifiers.

## Deliverables

- A proportionate slice plan with source requirements, current capability state, named demonstrations, real/simulated transitions, dependencies, acceptance evidence, and feedback checkpoints.
- Explicit uncertain decisions and feasibility conditions, with their affected scope; no invented claims of approval, implementation, or readiness.
- A compact handoff identifying selected slices, accepted constraints, and the source of truth for later task creation.

## References

- [Approach and research](./references/approach-and-research.md). Read when: explaining the method, selecting a simulation strategy, or adapting it to a different interaction surface.
- [Scribe example](./references/scribe-example.md). Read when: planning Scribe or needing an example of UI breadth followed by progressively real audio capabilities.

Use [the slice-plan asset](./assets/slice-plan.md) when drafting; adapt its headings to the project's format.
