---
name: continuous-improvement
description: Improve what a team produces and how it works through codebase review and development retrospectives. Use when asked for code simplifications, maintainability or agent-velocity improvements, or lessons from completed work; return one prioritized improvement backlog.
---

## Rules

- Investigate the cost of understanding, changing, coordinating, and verifying real work. Use standards to inform judgment, not as a compliance scorecard.
- Discover and read every available sibling `principle-*` skill in full before assessing the work. Follow the discovery procedure below; never filter these reads by perceived relevance.
- Make subtraction explicit: identify bad abstractions, obsolete implementations, and misleading examples agents could copy. Name the supported replacement, callers to migrate, and stale exports or guidance to remove. Preserve useful boundaries and required behavior.
- Distinguish observed friction from inferred causes and expected benefits. Static source evidence can support structural findings; measured speed claims require measurements.
- Combine both playbooks into one ranked backlog when both are selected. Merge shared root causes and preserve the evidence from each lens.

## Constraints

- A review request alone does not authorize implementation, deletion, tracker mutation, or shared-skill edits. Honor any implementation authorization already given without adding confirmation rounds.
- Do not equate unfamiliar code, high churn, file size, package count, or a passing checker with a design conclusion. Follow callers, obligations, and actual behavior.
- Keep investigation bounded to the selected scope. Reuse existing evidence and tools; run focused checks only to resolve a consequential question. Live models, broad suites, and new benchmark infrastructure are not routine review prerequisites.
- Do not copy standards into this skill or turn every correction into another instruction. Propose structural prevention for objective recurring mistakes and retain prose for judgment.

## Requirements

Use the requested project/code scope or completed-work evidence, its goals, project instructions, and accepted decisions. Infer routine scope from available context; ask only for a material unresolved choice. Missing session evidence limits retrospective conclusions, not codebase investigation.

Principles are required inputs; other standards are selected by the decision. These references are review guidance, not authorization to execute their implementation workflows.

| Standard | Read when |
| --- | --- |
| `architecture` | Module depth, state ownership, contracts, dependencies, or composition need examination. |
| `typescript-best-practices` | TypeScript readability, domain representations, inference, or failures matter. |
| `typescript-project-hygiene` | Imports, exports, module evaluation, compiler policy, or diagnostics matter. |
| `effect-best-practices` | Effect capability, lifetime, failure, replay, or evidence decisions matter. |
| `testing-strategy` | Coverage value, substitute fidelity, reproducibility, or verification cost matters. |

Resolve these skill names to their actual `SKILL.md` through host discovery or the available library inventory, rather than assuming a category or absolute path. Inspect directory entries and resolve symlinks before reporting a skill missing; a file search that skips symlinked directories is not an availability check. Read the selected entrypoints and only their applicable leaves. Use additional project-specific skills where relevant; verify API facts against installed guidance/source when those facts affect a recommendation.

## Workflow

1. **Establish scope and read principles.** Read project instructions. Discover all skill directories named `principle-*` and catalog entries whose skill name starts with `principle-`, across available sibling skill libraries and category folders. Include symlinked skill directories and resolve their actual files. Use host discovery and bounded filesystem inventory; do not stop at this skill's immediate parent or a hard-coded list. Read each complete `SKILL.md` and all its bundled instructional resources, following local instruction links. Metadata, excerpts, summaries, or a prior agent's account do not substitute for full reads. Deduplicate aliases, not distinct principles. If output is truncated, retrieve the remainder. Name inaccessible material as a gap; do not claim the required principle reading is complete while anything remains unread.
2. **Select the lens.** Open [codebase review](playbooks/codebase-review.md) for product/code quality, [retrospective](playbooks/retrospective.md) for how actual work was performed, or both when requested. Do not run the unselected playbook. Apply the principles in context; reading all principles does not require manufacturing a finding for each.
3. **Investigate and compare.** Follow the selected playbook and applicable standards. State missing evidence and coverage. Prefer a few grounded proposals over exhaustive speculative redesign. Fresh agents are the default for bounded independent assignments, with coordinator discretion and project policy; give exact scope, full-principle reading requirements, and a shared completion bar. Delegation does not add review rounds or duplicate valid verification.
4. **Prioritize and deliver.** Use the [improvement report](assets/improvement-report.md), adapting an existing project record rather than creating duplicate tracking. Rank recurring benefit and change relevance against effort, migration risk, ownership cost, and confidence. Recommend the best next change, retain useful current practices, and stop at the agreed scope. Implementation planning follows selection unless already requested.

## Gotchas

- If discovery checks only the current category, it misses principles elsewhere. Inventory available skill roots and read every matching skill and its instruction resources in full.
- If a review reports rule violations without a consequence, it becomes cosmetic migration work. Explain what understanding or change becomes easier.
- If a new abstraction leaves the obsolete path and examples behind, the next agent copies them. Include caller migration and explicit deletion in the same proposal.
- If subtraction removes a real ownership boundary, complexity spreads to callers. Show what disappears and what merely moves.
- If a retrospective infers delays or motives from code alone, it invents the process history. Cite session evidence or mark the explanation as a hypothesis.
- If each lens produces its own fix for the same cause, the backlog fragments. Consolidate into one action with both evidence trails.

## Deliverables

- One prioritized, evidence-backed improvement backlog with proposed changes, explicit deletions or justified retention, expected benefits, effort/risk, and focused validation.
- A concise scope/coverage statement identifying playbooks used, all principle skills and instructional resources read, selected standards, and any access or evidence gaps.
- Useful code/practices to preserve and a recommended next action, without implying recommendations have been implemented or expected gains measured.
