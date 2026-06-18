---
name: capture-decisions
description: Capture project decisions in a durable Markdown decision log with rationale, consequences, and risks. Use when a user asks to record, document, preserve, capture, or update decisions made during planning, design, implementation, reviews, or trade-off discussions.
---

## Rules

- Treat decisions as durable project memory because future agents and contributors need rationale, not just the final choice.
- Use the project root `DECISIONS.md` by default because the decision log should be easy to discover without knowing project-specific docs conventions.
- Keep each decision entry self-contained because readers may encounter it without the original conversation.
- Separate **Decision**, **Why**, **Consequences**, and **Risks** because these fields answer different future questions.
- Preserve the user's actual rationale and trade-offs because invented rationale is worse than no rationale.
- Append new decisions instead of rewriting history because decision timing and order are useful context.
- Mark uncertainty explicitly with `TODO: Confirm` because silent inference turns weak evidence into false project history.
- Follow the existing decision-log style when editing an existing file because consistency improves scanning and reduces churn.

## Constraints

- Default target path is `<project-root>/DECISIONS.md`.
- Resolve `<project-root>` as the nearest Git root when available; otherwise use the current working directory.
- Do not create one large catch-all decision when the conversation contains multiple independent choices.
- Do not invent alternatives, risks, consequences, dates, owners, or status values that are not supported by the conversation or repository evidence.
- Do not remove or materially rewrite existing decision entries unless the user explicitly asks to revise or supersede them.

## Requirements

Inputs:

- The decision or set of decisions to capture.
- The rationale or context that explains why each decision was made.
- Known consequences and risks, if available.
- Optional target path when the user does not want the default `DECISIONS.md`.

Outputs:

- A created or updated Markdown decision log.
- One entry per durable decision.
- A concise summary of what was recorded and where.
- `TODO: Confirm` markers for high-impact missing fields that could not be clarified.

In scope:

- product, architecture, domain, workflow, tooling, process, and implementation-scope decisions
- explicit rejections such as “do not add X in MVP” when the rejection prevents future re-litigation
- updates that supersede or amend earlier decisions

Out of scope:

- generic meeting notes, transient TODOs, or implementation progress logs
- glossary-only terminology unless the term choice is itself a durable decision
- replacing a full ADR process unless the user asks for ADR-style files

Decision field meanings:

- **Decision**: the choice that was made, stated directly.
- **Why**: the rationale, trade-off, constraint, or rejected alternative that explains the choice.
- **Consequences**: expected follow-on effects, obligations, user-visible behavior, or implementation implications.
- **Risks**: uncertain downsides, ways the choice could fail, unresolved concerns, or conditions that may force reconsideration.

## Workflow

1. **Find the decision log target**
   - Use the nearest Git root as the project root when available.
   - Use `<project-root>/DECISIONS.md` unless the user explicitly named a different target path.
   - If an existing target file is present, read it before editing.

2. **Extract decision candidates**
   - Identify each independent decision from the conversation, plan, spec, diff, or user instruction.
   - Keep separate choices separate, even when they were made in the same discussion.
   - Ignore transient implementation steps unless they create durable constraints or future-facing rationale.

3. **Check for missing high-impact fields**
   - If the decision, why, consequences, or risks are missing and the user is available, ask a focused clarification question.
   - If the user asked you to proceed without interruption, write the entry with `TODO: Confirm` under the missing field.
   - Prefer a clear `TODO: Confirm` over filling gaps with generic speculation.

4. **Choose the entry shape**
   - If the file already has a consistent numbering, date, status, or heading style, follow it.
   - If creating a new file, use this default structure:

   ```md
   # Decisions

   This file records durable project decisions, including the rationale, consequences, and risks that future contributors and AI agents need to preserve.

   ## 1. {Short decision title}

   Date: {YYYY-MM-DD}  
   Status: Accepted

   **Decision:** {What was decided.}

   **Why:** {Why this choice was made. Include important rejected alternatives or constraints.}

   **Consequences:**

   - {Expected effect or obligation.}

   **Risks:**

   - {Uncertain downside or reconsideration trigger.}
   ```

5. **Write or update the log**
   - Create `DECISIONS.md` if it does not exist.
   - Append new entries after existing decisions.
   - When a decision supersedes an older entry, append a new entry and add a minimal note to the older entry only if needed for navigation, such as `Status: Superseded by Decision N`.
   - Keep wording concise, but include enough context that the entry still makes sense without the original chat.

6. **Report completion**
   - State the file path.
   - List the decision titles added or updated.
   - Call out any remaining `TODO: Confirm` markers.

## Gotchas

- If you only record what was chosen and skip why, the next agent will re-open the same debate because the trade-off is invisible. Capture the rationale next to the decision.
- If you merge several choices into one broad entry, future readers cannot supersede or reference one choice without disturbing the others. Split independent choices into separate entries.
- If you invent plausible risks because every entry “should” have risks, you create false project memory. Use `TODO: Confirm` when risks were not discussed.
- If you bury decisions in `CONTEXT.md`, the glossary becomes a mixed spec and future agents cannot tell terminology from policy. Use `DECISIONS.md` unless the user explicitly requested another file.
- If you silently switch to `docs/decisions.md` because another project used it, the log becomes hard to discover in projects expecting the default. Use root `DECISIONS.md` unless directed otherwise.
- If you rewrite old entries while adding new ones, you erase decision history and make diffs noisy. Append by default and mark supersession explicitly.
- If consequences only repeat the decision, readers still do not know what changes downstream. Write consequences as effects, obligations, or behavior changes.
- If risks are written as generic “may be buggy” warnings, they do not help future reconsideration. Tie each risk to a concrete failure mode or uncertainty.
