# Decisions and evidence

## Batch decisions, not trivia

Recover already answered questions from the session and source documents. Group the remaining commitments by shared consequences rather than asking serially or presenting an unrelated questionnaire.

A useful batch:

| Decision | Recommendation | Alternative / tradeoff | Execution impact |
| --- | --- | --- | --- |
| What does a failed import leave behind? | No visible partial import | Partial results allow recovery but complicate user expectations | Blocks import behavior and acceptance |
| How can the user recover? | Retry the same request safely | Manual cleanup reduces initial work but adds user burden | Depends on the failure choice |

Give the user a way to accept the recommendations together or override individual answers. Do not assume accepting one answer accepts the whole batch. Restate ambiguous responses and propagate changes to dependent choices.

Leave ordinary naming, private module layout, and reversible implementation decisions to the executor unless they affect a real constraint. A batch is not an excuse to request approval for everything.

## Choose evidence by uncertainty

- Repository evidence establishes current behavior and constraints; it does not prove the proposed behavior is desirable.
- Prior art can reveal viable approaches and real tradeoffs. Inspect the implementation or primary explanation when practical rather than relying on popularity or a summary.
- Research can compare options and limitations without building anything.
- A prototype is appropriate when feasibility, architecture interactions, UX, or another assumption needs direct observation.

Prefer the least costly credible evidence. Do not mandate research or prototyping when the decision is already supported.

For a prior-art conclusion, retain the source/version, relevant approach, constraints behind its choice, and differences from this project. Separate observed facts, the source author's explanation, and your inference. A copied snippet may have its own license; a source link is not permission to reuse it.

## Evidence request and return

When more work is needed, identify:

- the question and why existing evidence is insufficient
- the commitments and execution scope depending on the answer
- the proposed research question or bounded experiment, plus authorization needed
- what findings would make the decision actionable

Consume findings as reusable artifacts, not a transcript dump. Reference their location, result, limitations, and impact on the proposed contract. Distinguish measured results from interpretation, simulated UX from implemented UX, and untested assumptions from demonstrated behavior.

If findings change the recommendation, return that decision to the user. Do not turn evidence into acceptance, a prototype into production code, or a research source's architecture into a mandatory design.

## Engineering decision records

Read existing ADRs before making conflicting commitments. The spec names the constraints and links their rationale; ADRs own the durable engineering choice, alternatives, and consequences.

Identify ADR work for significant tradeoffs, lasting boundaries, or costly-to-reverse choices. An ordinary implementation detail does not require an ADR. A proposed ADR is not accepted architecture, and a changed choice should explicitly supersede the relevant record rather than silently overwriting it.

ADR authoring and evidence production are separate tasks. This workflow can use existing artifacts without any particular authoring tool or skill.
