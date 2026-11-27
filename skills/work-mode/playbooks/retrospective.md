# Learn from completed work

## Entry conditions

Use to understand how actual development work was performed and identify improvements to its execution, coordination, tools, guidance, or feedback. Inputs can include conversation, task/session records, tool results, diffs, checks, handoffs, corrections, and user feedback. Source code alone cannot establish a process history.

This playbook selects `continuous-improvement`'s retrospective lens; that skill owns methodology, principle discovery/reading, cause analysis, prioritization, and the improvement report.

## Procedure

1. **Frame the work and evidence.** Recover intended result, scope/constraints, actual outcome, and available session artifacts. Distinguish a completed slice from unfinished work and inaccessible history. Bound the inquiry to consequential events rather than reconstructing every tool call.
2. **Load the methodology.** Locate and read `continuous-improvement` through [skill routing](../references/skill-routing.md). Select its retrospective playbook and follow its required principle/input discovery. Do not replace it with an invented process scorecard. Identify unavailable evidence and unread required resources.
3. **Investigate the process lens.** Follow its observation/cause distinction, recurring friction and effective-practice analysis, and durable-change guidance. Use recorded timings/counts if available; do not infer delays, motives, or measured velocity from source code. Inspect related code/tooling only to answer a cause question, not to launch a whole-codebase audit.
4. **Return one ranked result.** Use its improvement-report contract, adapting existing records. Tie proposals to actual events and likely causes, identify ownership and what should disappear or remain, and explain benefit, cost/risk/confidence, and how future work could show improvement. Retain practices that helped. Consolidate shared causes if codebase review was also requested.

## Completion criteria

Recommendations are grounded in the available work evidence, with observations separated from causal hypotheses and expected benefits. State coverage, missing history, useful practices, the recommended next improvement, and evidence needed to assess it. Sparse evidence supports a limited retrospective; it does not justify a fabricated account or a universal rule from one incident.

## Conditional transitions

- A requested structural inquiry adds [codebase review](codebase-review.md) to the same backlog; do not turn process analysis into an automatic audit.
- Investigate uncertain causes/remedies with a [bounded experiment](bounded-prototyping.md) when warranted and authorized.
- Implement improvements only within existing authorization. Shared skills, project guidance, code/tooling, or coordination practices may have different owners and permissions; recommendations do not authorize editing all of them. No automatic tickets, new acceptance gates, or policy changes follow a retrospective.
