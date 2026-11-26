---
name: to-spec
description: Converge on a reviewed product or feature specification from session context, project evidence, and batched decisions. Use when creating or revising a spec or PRD that will guide execution and delivery, including when research or prototype findings are needed first.
---

## Rules

- Recover settled intent from the session and project before proposing decisions; the user's current direction takes precedence over historical habits.
- Standardize the contract, not document length: establish outcome and scope, behavior, constraints and decisions, acceptance criteria, delivery conditions, and open decisions.
- Resolve related material decisions together, with recommendations and tradeoffs, because serial questioning slows convergence and hides interactions.
- Separate source evidence, proposed choices, and accepted commitments; neither prior art nor a successful experiment constitutes approval.
- Make the contract sufficient for another session to execute without reconstructing this conversation, while leaving ordinary implementation choices to the executor.
- Reuse the project's document and ADR conventions. Default to a local Markdown spec under `specs/` only when no destination convention or instruction exists.

## Constraints

- Do not invent product goals from instructions about authoring, testing, tooling, or agent behavior. Distinguish product responsibilities from actions the user performs outside the product.
- Do not repeat settled discovery, require a story grammar, or expand a small change into a mandatory document pack.
- Do not prescribe testing policy, test levels, seam counts, or suite size. Specify observable acceptance criteria, not a test inventory.
- Do not conduct an open-ended research project, build a prototype, implement the feature, create tickets, or publish remotely without authorization for that work.
- Do not replace engineering ADRs with a generic decision log or silently override an accepted ADR.
- Do not infer acceptance from silence, a saved file, or a mechanical check. Mark missing high-impact commitments `TODO: Confirm`.
- Do not require another skill to complete this workflow; consume research, ADRs, and findings as artifacts regardless of how they were produced.

## Requirements

- A product/change intent or source to interpret: session discussion, existing documents, a codebase, or a proposed revision. Ask for the missing starting point if none exists.
- Access to relevant project material when available; identify unavailable evidence rather than claiming it was inspected.
- The intended execution scope and document destination, resolved from the request and project conventions.

In scope: collaborative specification and revision, decision batches, evidence gaps, ADR references, acceptance criteria, execution readiness, and delivery conditions.

Out of scope: detailed testing strategy, ADR authoring, research/prototype execution, ticket decomposition, implementation, and deployment. Identify needed work and consume its results rather than embedding those workflows.

## Workflow

1. **Recover the starting contract.** Read the relevant session context, existing spec, project responsibilities, and applicable ADRs. Identify what is settled, what changes, the intended audience, and whether this is a whole product or an executable feature/slice. Inspect enough code, configuration, and existing behavior to ground consequential claims; do not survey the repository without a question.
2. **Draft proportionately.** Use [`assets/spec-template.md`](./assets/spec-template.md) as a compact starting point, not a required heading schema. Preserve the six content areas even when the project uses different headings or a document pack. Add signatures, schemas, diagrams, or source paths when they remove ambiguity; omit incidental implementation maps. For a broad product, distinguish overall direction from the first scope that could actually execute.
3. **Converge in decision batches.** Load [`references/decisions-and-evidence.md`](./references/decisions-and-evidence.md). Present related unresolved product/engineering commitments together: question, recommended answer, meaningful alternative/tradeoff, and execution impact. Avoid asking the user to design routine internals. Record the user's answers precisely and revisit dependent choices when an answer changes.
4. **Close evidence gaps when needed.** Reuse adequate evidence first. If a consequential uncertainty remains, identify the question, affected commitments, and the least costly credible next evidence: targeted research/prior art or a bounded prototype. Request authorization for work outside specification authoring. When findings arrive, capture their source, limitations, and effect on the draft; bring changed recommendations back for a decision. No research or prototype stage is mandatory. Block only the dependent scope.
5. **Connect decisions and acceptance.** Reference existing ADRs and identify proposed or amended ADRs needed for consequential architecture choices; do not label them accepted before approval. Write identifiable acceptance criteria for user-visible outcomes, important failures, and constraints. Several criteria may share an eventual verification scenario; choosing test architecture is separate work.
6. **Review the executable contract.** Load [`references/readiness-and-handoff.md`](./references/readiness-and-handoff.md). Review the scope, commitments, acceptance criteria, and delivery conditions as one coherent contract. Resolve blocking decisions/evidence gaps and distinguish retained executor discretion from missing requirements. Obtain explicit approval of the current scope or reuse approval that still covers it; material revisions invalidate affected approval.
7. **Preserve and hand off.** Update the established document rather than creating parallel sources of truth. Verify the saved content and links; run available project document checks or the optional bundled checks where applicable. Report the actual approval/readiness state and a compact execution handoff. Preserve a useful draft when blocked. Stop at the handoff unless further work is authorized; storage, implementation verification, and delivery are distinct outcomes.

## Gotchas

- If the agent treats a synthesis request as a fresh interview, the user repeats decisions already made. Recover session commitments first and batch only unresolved choices.
- If each template field becomes a compulsory document, specification overhead exceeds the change. Scale the artifact while retaining the contract's essential content.
- If process instructions become product requirements, executors build agent workflow into the product. Separate authoring instructions, human actions, product outcomes, and engineering constraints.
- If research recommendations or prototype success are recorded as accepted architecture, evidence silently gains decision authority. Preserve findings separately and record the actual approval.
- If every open question blocks the whole product, independently executable work stalls. Name the affected slice and its dependencies; do not declare the entire product ready because one slice is ready.
- If acceptance criteria become a prescribed test suite, the spec duplicates testing policy and constrains implementation unnecessarily. State observable evidence of success and leave test selection to testing work.
- If source paths or snippets reproduce a whole design, incidental details become mandatory. Include only decision-relevant detail and distinguish illustrative examples from normative contracts.
- If a file or validator pass implies approval or delivery, a polished draft becomes a false commitment. Report approval, execution readiness, implementation evidence, and delivery evidence separately.

## Deliverables

- A proportionate local specification, or an explicitly requested alternate destination, covering all six contract areas with source references and no unfilled drafting placeholders.
- Accepted choices distinguished from proposals; applicable ADRs linked and any missing ADR work identified. Unresolved evidence requests identify the question and dependent scope.
- Observable acceptance criteria with stable identifiers, without mandating a particular test suite or implementation structure.
- An accurate readiness statement and concise handoff: approved scope, spec/ADR/evidence locations, acceptance criteria, known verification approach if established, delivery conditions, and remaining executor discretion. Blocked drafts state what must happen next.

## References

- [`references/decisions-and-evidence.md`](./references/decisions-and-evidence.md): Read when: preparing a decision batch, resolving uncertainty, comparing prior art, or incorporating research/prototype findings.
- [`references/readiness-and-handoff.md`](./references/readiness-and-handoff.md): Read when: reviewing readiness, distinguishing whole-product scope from a slice, persisting the spec, or preparing the execution handoff.

## Deterministic Validation

Paths below are relative to this skill directory. These optional checks support ordinary ATX Markdown specs, not arbitrary project formats or semantic approval.

- `python3 scripts/validate-spec.py <spec-file>` — checks a title, nonempty sections, identifiable acceptance criteria with unique IDs and valid references, inline local-link targets, and unfilled drafting markers. No exact headings, order, or story grammar are required.
- `python3 scripts/validate-spec.py <spec-file> --check-blockers` — additionally reports `TODO: Confirm` and `BLOCKED:` markers anywhere in the document; it cannot judge whether a marker blocks the selected slice or establish readiness.
- `python3 scripts/test_validate_spec.py` — checks the validator's documented behavior, including its CLI. Use project-specific checks instead when the chosen format is incompatible.
