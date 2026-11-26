---
name: write-adr
description: Create, revise, or supersede engineering architecture decision records grounded in project context and actual tradeoffs. Use when an engineering choice needs durable rationale, alternatives, consequences, or an explicit change to an accepted architecture decision.
---

## Rules

- Record consequential engineering choices, not every implementation detail, because ADRs preserve rationale that code and a feature spec cannot explain alone.
- Follow the project's existing ADR location, numbering, status vocabulary, and template before introducing a convention.
- Separate the evidence informing a choice from the decision and its approval; research or prototype success is not acceptance.
- Preserve the constraints behind rejected alternatives so future readers can judge whether changed circumstances justify reconsideration.
- Keep one coherent architectural decision per record and link related records rather than bundling unrelated choices.
- Preserve accepted history through explicit supersession, because silently rewriting the original rationale hides when the architecture changed.

## Constraints

- Do not use this workflow for non-engineering decision logs, product requirement lists, meeting notes, or implementation progress.
- Do not invent alternatives that were never considered, measured results, rationale, approval, dates, or owners.
- Do not mark a proposed choice accepted without explicit approval or equivalent authoritative project evidence.
- Do not override an existing accepted ADR without identifying the conflict and obtaining authority to change it.
- Do not turn ADR authoring into research, prototype execution, implementation, or a prerequisite to every reversible coding choice.
- Do not require another skill or tool-specific artifact format to interpret the evidence.

## Requirements

- An engineering choice with enough context to describe the problem and meaningful constraints.
- Existing ADRs, relevant specifications, and available research/prototype findings.
- A destination and approval basis, resolved from project convention or the user's request. With neither convention nor an explicit path, propose `docs/adr/`.
- Missing high-impact context or rationale is recorded as `TODO: Confirm`; the record remains proposed until the choice is accepted.

In scope: architectural boundaries, dependencies, persistence/consistency, protocols, security, operational choices, and consequential engineering tooling decisions.

Out of scope: general non-engineering decisions, full feature specifications, and executing the chosen architecture.

## Workflow

1. **Locate the decision context.** Read applicable ADRs and the relevant spec/evidence. Identify the choice, constraints, affected responsibilities, and whether it is new, an amendment, or a replacement. If no consequential tradeoff exists, explain why an ADR adds little rather than manufacturing one.
2. **Resolve the record contract.** Reuse the repository's location, identifier allocation, template, and statuses. If absent, use one file per decision under the agreed directory, a unique sequential identifier, and Proposed / Accepted / Rejected / Superseded statuses. Use [`assets/adr-template.md`](./assets/adr-template.md) as a starting point.
3. **Draft the rationale.** Describe the engineering problem and forces; list the actual options considered and their relevant tradeoffs. State the proposed or accepted choice, known consequences, and conditions that could justify revisiting it. Reference evidence and limitations rather than copying whole research or experiment logs.
4. **Resolve material gaps together.** Present related unanswered choices as a batch with recommendations and alternatives. If missing evidence prevents a defensible choice, identify what is needed and retain a proposed record. Do not imply unsupported performance, UX, or reliability claims are facts.
5. **Apply approval and history accurately.** Record acceptance only when supported. For a changed accepted choice, create a replacement record and minimally annotate the old record with its supersession link/status after approval; preserve its original context. Leave the old ADR accepted while a replacement is merely proposed. For corrections that do not change the choice, make a narrow documented amendment.
6. **Persist and report.** Verify the identifier, status, evidence links, and any reciprocal supersession links. Update authorized spec references without duplicating the rationale. Report the record location, actual status, affected prior records, and unresolved questions. Writing an accepted ADR does not implement its decision.

## Gotchas

- If every implementation preference gets an ADR, consequential choices disappear in paperwork. Record decisions whose tradeoffs or future constraints need durable explanation.
- If the preferred option is written as an accepted decision before review, later agents treat a recommendation as authority. Keep proposal and approval explicit.
- If plausible alternatives are invented to fill a template, the record falsifies the design history. State which options were actually considered and what evidence is missing.
- If a prototype result is generalized beyond its environment, an architecture inherits guarantees never tested. Carry the experiment's limits into the rationale.
- If an accepted ADR is overwritten, readers lose the conditions under which the original choice was reasonable. Supersede it and link both directions.
- If a proposed replacement immediately supersedes the current ADR, the project has no clear accepted architecture during review. Change the old record only after the replacement is accepted.
- If the ADR repeats every feature requirement, it competes with the spec and drifts. Link requirements and retain only the context needed to understand this engineering choice.

## Deliverables

- One self-contained ADR per coherent engineering decision, with context, actual alternatives, choice, consequences, evidence, and accurate status.
- Explicit unresolved markers rather than fabricated reasoning or approval.
- For supersession, preserved historical rationale and navigable links between accepted old and new records.
- A concise report of what was recorded and what remains proposed; no implied implementation or delivery.
