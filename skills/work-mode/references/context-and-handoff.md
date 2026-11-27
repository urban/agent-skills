# Recover context and preserve continuity

Treat intake as reconstruction, not a new interview or a compulsory artifact. For a small task, the working context and final reply can carry the whole contract. For long work or a fresh executor, update the owning project record or create a compact local handoff only if needed.

## Recover the working contract

Use the current request, relevant conversation, linked artifacts, project instructions, and current execution evidence. Separate these facts:

| Context | Preserve enough to act |
| --- | --- |
| Outcome and completion | What the user wants to be true; scope/non-goals; observable completion conditions; requested destination/delivery |
| Settled choices | Actual decisions, rationale/tradeoffs, source and affected revision; what remains executor discretion |
| Authorization | Which actions, targets, environments, side effects, and costs are covered; additional actions still requiring a decision |
| Constraints | Project instructions, accepted behavior, access/tool limits, dependencies, and unrelated work to preserve |
| State and evidence | What exists now; exact files/symbols/artifact links, inspected revision, changes made, checks/results, incomplete attempts, and evidence limitations |
| Unresolved questions | Material ambiguity or uncertainty, affected work, recommendation/alternatives when useful, and what answer or evidence unblocks it |

Prefer the latest explicit user direction when earlier discussion conflicts. Do not promote tentative language, an agent's recommendation, or historical habits into a commitment. Verify mutable execution facts against the current project. If current code conflicts with an accepted decision, report the discrepancy; neither silently overrides the other.

Read available previous conversations through supported history tools or supplied records. If unavailable, identify the missing source and what depends on it. Inspect project artifacts that can recover the missing facts before asking the user to repeat themselves. Do not claim to have read inaccessible history or stop independent work because one fact is unavailable.

## Preserve rationale where it belongs

Follow project conventions for design notes, specifications, ADRs, and working records. Preserve consequential rationale and rejected tradeoffs when a future executor would otherwise reopen them; code alone often cannot explain these choices. Distinguish a proposed direction from an approved one. Link existing rationale instead of creating competing records or a decision log by default. Engineering ADR authoring belongs to `write-adr` when relevant; this contract does not introduce a decision-capture playbook or principle.

## Handoff actual context

Give the next executor the contract above, scaled to their assignment. Include exact relevant paths/links and enough decision content to understand why they matter; “read everything” and “see previous chat” are insufficient. Preserve user exceptions and the evidence for existing authorization. Do not convert limited authorization into blanket permission or require the user to approve unchanged work again.

Name the selected playbook/current stage, owned scope, completed work, remaining work, known failures, and next useful action. Separate actual verification results from checks merely planned. If blocked, name the specific missing access, evidence, dependency, or decision and the work it prevents. If one slice is ready, do not label the whole task complete.
