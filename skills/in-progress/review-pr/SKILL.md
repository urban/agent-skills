---
name: review-pr
description: Review a pull request against source requirements and repository standards, then record actionable feedback in GitHub. Use when a user asks for a thorough PR review with inline comments and follow-up issues.
---

## Rules

- Ground every finding in repository evidence because vague review feedback is hard to act on and easy to dismiss.
- Review against the provided PRD, spec, or requirement source before judging implementation quality.
- Prioritize correctness, regressions, security, reliability, and maintainability over stylistic preference.
- Keep each finding actionable: state the problem, why it matters, and what should change.
- Distinguish blocking issues from non-blocking suggestions.
- Prefer inline PR comments for code-specific findings and GitHub issues for broader or deferred work.
- Create follow-up issues from [`assets/issue-template.md`](./assets/issue-template.md) and include the PRD by number in the body.
- Mark missing high-impact context as `TODO: Confirm` instead of inferring requirements.

## Constraints

- Do not merge, approve, or close the PR unless the user explicitly asks.
- Do not rewrite or reinterpret source requirements to fit the implementation.
- Do not create duplicate comments or duplicate follow-up issues for the same defect.
- Every follow-up issue created from review findings must include the `task` label.
- Every follow-up issue must reference the PRD by number in the issue body, for example `PRD #8`.
- If a finding fits a precise line-level comment, leave that comment before escalating it into an issue.

## Requirements

Inputs:

- PR URL or PR number
- requirement source such as PRD issue, spec doc, or approved design doc
- authenticated GitHub CLI access for the target repository

Outputs:

- inline PR comments for actionable code-specific findings
- follow-up GitHub issues for deferred or broader work
- explicit `TODO: Confirm` markers for unresolved high-impact unknowns

In scope:

- reviewing changed code, tests, and stated behavior
- comparing implementation against requirements and repo patterns
- posting comments and filing follow-up issues

Out of scope:

- implementing fixes
- redefining project goals or acceptance criteria
- release management actions unless explicitly requested

Failure modes to prevent:

- reviewing against assumptions instead of the stated source of truth
- leaving comments without evidence, impact, or expected correction
- losing deferred work because it stayed only in PR comments

## Workflow

1. Confirm the PR target, repository, and source requirements.
2. Read the PR title, body, linked issues, commits, changed files, and CI status.
3. Read the requirement source end to end and extract acceptance criteria, constraints, and non-goals into a working checklist.
4. Review the PR for requirement coverage, correctness, regressions, tests, and operational risk.
5. Leave inline PR comments for code-specific findings with the problem, impact, and expected correction.
6. Create follow-up GitHub issues for broader or deferred work from [`assets/issue-template.md`](./assets/issue-template.md), add the `task` label, and include the PRD by number in the body.
7. Summarize blocking findings, non-blocking suggestions, filed issues, and any remaining `TODO: Confirm` items.

## Gotchas

- If you review the diff before reading the requirement source, you start grading code quality against your own assumptions instead of the requested outcome. Build the checklist from the PRD or spec first.
- If a comment says something is “unclear” or “maybe wrong” without evidence, authors have to reverse-engineer your concern and the review loses credibility. Point to the exact file, behavior, or requirement mismatch.
- If you turn every finding into a GitHub issue, the PR loses the direct feedback needed for efficient fixes. Use inline comments for code-local defects and issues for work that truly needs follow-up tracking.
- If you leave broader deferred work only in PR comments, it disappears when the PR closes and the risk ships anyway. File a `task` issue whenever the work should survive beyond the review thread.
- If you forget the PRD number in a follow-up issue, the issue becomes disconnected from the original intent and later triage has to reconstruct why it exists. Include the PRD reference in every issue body.
- If you report style preferences as defects, important correctness findings get buried in noise and the author stops trusting severity. Reserve strong language for concrete product, system, or maintenance risk.

## Deliverables

- inline PR comments for actionable code-specific findings
- follow-up GitHub issues labeled `task` and drafted from [`assets/issue-template.md`](./assets/issue-template.md)
- a concise review summary covering blocking items, non-blocking items, filed issues, and `TODO: Confirm` gaps

## Validation Checklist

- PR target and source requirements were both confirmed
- review findings are grounded in repo evidence or requirement text
- inline comments include problem, impact, and expected correction
- follow-up issues use [`assets/issue-template.md`](./assets/issue-template.md)
- every follow-up issue includes the `task` label
- every follow-up issue references the PRD by number in the body
- deferred work is tracked outside the PR thread when needed
- unresolved high-impact details are marked `TODO: Confirm`
