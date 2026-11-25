---
name: vision
description: Draft and refine a project's vision from real evidence and the owner's answers to difficult hypothetical changes. Use when asked to create, update, or stress-test a project vision.
---

## Rules

- Treat the vision as an acceptance policy: a future contributor should be able to judge a proposed change without the original conversation.
- Ground principles in actual project decisions or the owner's stated reasoning; distinguish observed behavior from inferred intent.
- Express principles as durable, project-specific commitments with reasons and boundaries, because generic virtues do not resolve tradeoffs.
- Preserve an accepted vision as the baseline; propose focused revisions rather than starting a competing document.
- Keep the process concise: draft, challenge, incorporate reasoning, review.

## Constraints

- Never invent evidence, decisions, or approval. The owner decides the project's direction.
- Produce one vision, not a roadmap, feature specification, invariants framework, or permanent hypothetical-answer ledger.
- Edit only the selected document or section. Do not delete decision records, consolidate other documents, or change agent instructions without authorization for those changes.
- A vision guides judgment; it does not authorize implementation, publication, or accepting and closing contributions.

## Requirements

- A target project, its vision owner, and readable project evidence. Default to the current repository and the user; clarify only material ambiguity.
- Relevant documentation and real merged PRs or commit history. If neither history source is readable, report the gap and obtain source material or explicit owner intent before drafting.
- One destination: an explicitly requested location, otherwise an existing root `VISION.md`, otherwise the Vision section of root `STRATEGY.md`.

## Workflow

1. **Establish the baseline.** Read the existing vision and relevant project documentation. If several documents claim authority, resolve the conflict before editing. Preserve unrelated sections and local changes.
2. **Find the evidence.** Inspect merged PRs, falling back to default-branch commits. Read representative changes and their rationale, not just titles. Build a private mapping from candidate commitments to concrete sources; ask about important gaps or contradictions.
3. **Draft the vision.** Use [the vision template](./assets/vision-template.md). Aim for about a page: purpose and audience, a few principle sections, concrete scope boundaries, and closing accept/resist criteria. For an existing vision, show the proposed changes and their evidence. Keep source mapping available for review without filling the prose with a research log.
4. **Challenge the draft.** Follow [the review guidance](./references/review.md). Present a small batch of consequential hypothetical changes, explain the strongest case on each side, and ask for the owner's judgment and reasoning. Keep the latest draft available in chat or the owner's chosen review surface.
5. **Revise and finish.** Fold the reasoning and conditions into the vision; show how each answer changed the text. Continue where meaningful ambiguity remains, then present the revised draft for acceptance. Never infer acceptance from silence. Save the accepted text to the selected destination. In section mode, preserve every byte outside that section; create `STRATEGY.md` with a project title and Vision section if absent. Report the location and any unresolved questions.

## Gotchas

- If the agent treats the current implementation as intent, an incidental tool becomes a permanent commitment. Ask what outcome the tool serves and whether alternatives are welcome.
- If principles say only “simple” or “high quality,” opposing proposals both appear aligned. State the concrete tradeoff and what makes an exception justified.
- If hypotheticals have an obviously correct answer, agreeable verdicts create false confidence. Test tempting scope expansions or collisions between real commitments.
- If a conditional answer becomes an unconditional rule, the revision loses the owner's boundary. Preserve the condition and its reason in the prose.
- If the final vision depends on the review transcript, the next agent repeats the debate. Distill the reasoning into the vision itself, keeping the hypothetical scaffolding out.
- If an update rewrites the whole strategy document, unrelated accepted work disappears. Replace only the owned section and verify the surrounding text is unchanged.

## Deliverables

- One accepted vision document or section, sufficient to guide concrete accept/resist decisions, with no separate invariants or hypothetical-test document.
- During review, a proposed draft, focused hypotheticals, and concise explanations of revisions. If review ends early, identify the draft as unaccepted.

## References

- [Review guidance](./references/review.md) — Read when: constructing hypotheticals, interpreting verdicts, or deciding whether another review round is useful.
