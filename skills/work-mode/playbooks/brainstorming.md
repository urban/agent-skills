# Brainstorm a design direction

## Entry conditions

Use for an unresolved idea, behavior, or design choice that needs collaborative discovery. Recover prior decisions first; implementation with settled scope enters execution directly. This playbook owns discovery and design, not code, scaffolds, or implementation planning.

Adapted from the standalone `brainstorming` skill: retain repository grounding, focused questioning, viable alternatives, concrete tradeoffs, and section-level convergence. Use project artifact conventions rather than imposing the source workflow's full document shape on every idea.

## Procedure

1. **Ground the problem.** Recover outcome, non-goals, constraints, and observable success. Inspect the relevant repository behavior, APIs, integrations, and existing design records before recommending a direction, unless inspection is prohibited or unavailable. State consequential evidence gaps.
2. **Discover only what is unsettled.** Ask one focused question at a time, preferably with meaningful choices and a recommendation when supported. Preserve answers and their implications. Do not re-interview the user about settled scope or ask them to choose routine implementation details.
3. **Compare viable approaches.** For the open decision, compare two or three credible paths with concrete tradeoffs in complexity, risk, flexibility, and delivery speed. Do not invent weak alternatives or reopen an already accepted choice merely to fill this comparison. Recommend a direction grounded in the actual constraints.
4. **Converge proportionately.** Review the affected solution, components/boundaries, data flow, failures/recovery, and observable validation decisions where relevant. A small idea may need one compact review; a larger design may need focused section-by-section feedback. Surface unresolved high-impact commitments explicitly, using the project's marker or `TODO: Confirm`.
5. **Preserve the result.** Update the existing owning design record; otherwise use a proportionate local artifact when durable design is part of the request. If no convention/destination exists, default to `docs/ideas/<artifact-name>-design.md`. Resolve the basename from an explicit name, existing related artifact, or concise problem title; normalize to lowercase kebab-case and keep it stable. Keep the selected solution clear; retain rationale/tradeoffs in the project's appropriate notes or ADR rather than leaving rejected options as half-approved scope. Mark a draft as proposed until approval is supported.

## Completion criteria

The direction addresses the recovered problem, alternatives/tradeoffs informed the unresolved choice, and accepted commitments are distinguishable from open questions. Preserve sufficient rationale and evidence for continuation, with a design artifact only to the degree the request/project needs it. A required user decision leaves dependent design pending; a saved draft is not approval.

## Conditional transitions

- A consequential factual uncertainty may call for [bounded prototyping](bounded-prototyping.md) or targeted research; reuse adequate evidence first and check authorization.
- A requested spec or engineering decision record routes to `to-spec` or `write-adr`. UI-specific design routes to `interface-first` using the existing context.
- Continue to implementation when it is already authorized and the relevant decisions are settled. Design-only work ends with its actual approval state and any proposed next action, not automatic execution.
