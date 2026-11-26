---
name: outline-documents
description: Develop and iteratively refine a substantial or client-facing document in its eventual Markdown source before drafting prose. Use when the user wants to review document hierarchy, information flow, canonical terminology, and visual opportunities through an outline-first writing process.
---

## Rules

- Treat the outline as the first reviewable iteration of the eventual Markdown document because structural decisions should survive into drafting instead of being discarded in a separate planning artifact.
- Organize the document through progressive disclosure because readers need orientation and decision-relevant meaning before process detail, operating mechanics, or exceptions.
- Use numbered items only for proposed sections and subsections in their intended reading order because numbering must reveal the document hierarchy rather than imply paragraph sequencing.
- Use bullets beneath each numbered section to describe the concepts that section must convey because the outline should define content intent without prematurely fixing paragraph count or prose shape.
- Preserve canonical names for services, processes, stages, and artifacts because the document should reinforce the vocabulary the author will use with readers. Simplify the explanation around those names instead of casually renaming them.
- Mark visual opportunities where sequence, responsibilities, handoffs, participation, or decisions are easier to understand spatially than verbally.
- Iterate on hierarchy, boundaries, terminology, and visual support before expanding the outline into finished prose.

## Constraints

- Do not draft finished prose or create finished illustrations during the outline stage unless the user explicitly asks to move beyond outline review.
- Do not assume one bullet will become one paragraph. A bullet represents a concept; drafting may combine, split, reorder, or express concepts in another suitable form within the approved section.
- Do not turn named vocabulary from one business or example into a universal requirement. Discover and preserve the canonical terms supplied by the current user or source material.
- Do not use numbering for notes, concepts, examples, illustration proposals, or drafting instructions.
- Format every Obsidian illustration callout flush-left, including each `>` line. Never place leading spaces before a callout to simulate nesting because indented callouts may not render reliably.
- Keep illustration proposals conceptual during outlining. Do not imply that their copy, layout, timing, or styling is final.
- Preserve source facts and approved claims. Flag material gaps or conflicts instead of resolving them through invented content.

## Requirements

Inputs:

- The intended audience and the outcome the document should support.
- Existing source material, if any, including the Markdown file that will become the final document.
- Known canonical vocabulary for named offerings, stages, processes, and deliverables.
- Relevant voice, brand, or reading-level guidance when available.
- Any editor-specific Markdown constraints, with flush-left Obsidian callouts as the default for illustration notes.

Outputs:

- A reviewable outline written into the eventual Markdown source file or another user-designated target.
- A numbered hierarchy whose items correspond only to proposed sections and subsections.
- Concept bullets under each section that state what the section will convey to the reader.
- Illustration callouts at selected locations, each stating placement, reader purpose, and a brief visual concept.
- Explicit questions or `TODO: Confirm` markers for high-impact missing terminology, audience assumptions, or information-boundary decisions that cannot be inferred safely.

## Workflow

1. **Establish the reader and document job**
   - Identify who will read the document, what they should understand, and what decision or next step it should support.
   - Separate client-relevant guidance from internal operations, contractual mechanics, or implementation detail that belongs in another artifact or a later disclosure layer.

2. **Inventory canonical vocabulary**
   - Extract the exact names of services, engagement types, stages, processes, assessments, deliverables, and other terms the author intends to use consistently.
   - Distinguish canonical names from surrounding technical language that can be translated into plain language.
   - Ask or mark `TODO: Confirm` when two sources use conflicting names and the choice would affect the whole outline.

3. **Design the disclosure layers**
   - Begin with orientation: what the relationship, offer, or process is and what the reader can expect.
   - Follow with the core journey, choices, or stages at the level needed to build a useful mental model.
   - Add collaboration details such as responsibilities, touchpoints, inputs, and decisions after the reader understands the whole.
   - Place operational detail, edge cases, and closeout mechanics later, or move them to a more appropriate document when they do not serve the overview.

4. **Write the structural outline in the eventual source file**
   - Number every actual section and subsection according to its reading order and nesting.
   - Under each numbered item, add concise bullets describing the concepts that section must convey.
   - Phrase concept bullets as reader outcomes or content intent, not draft sentences, micro-headings, or promised paragraph counts.
   - Keep sibling sections at comparable levels of abstraction and move content when it belongs under a different parent.

5. **Place illustration opportunities**
   - Add a visual only when it materially clarifies a relationship that prose would make harder to scan.
   - Place the callout immediately after the relevant section's concept bullets while keeping the callout itself flush-left.
   - State all three fields: **Placement**, **Reader purpose**, and **Visual concept**.
   - For process visuals, prefer a consistent grammar such as aligned lanes for provider work, client participation, joint touchpoints, and decision gates. Reuse shapes, labels, and direction consistently across the document.
   - Use this callout shape:

> [!example] Proposed illustration
> **Placement:** After the section this visual supports.
> **Reader purpose:** Explain what the reader should understand more quickly or confidently.
> **Visual concept:** Briefly describe the composition, such as a left-to-right timeline with aligned work lanes, touchpoints, and decision gates.

6. **Review the outline before drafting**
   - Verify that the opening gives the reader a useful whole-document orientation before detail appears.
   - Check that numbering maps only to sections, bullets map to concepts rather than paragraphs, and canonical vocabulary is unchanged.
   - Check that each visual earns its place and has a distinct explanatory purpose.
   - Present the outline for review and keep revising structure and information boundaries until the user approves progression to prose.

7. **Expand only after approval**
   - Use the approved outline as the drafting scaffold.
   - Preserve the approved hierarchy, vocabulary, and visual intent while choosing paragraph count and prose form according to the content.
   - Return to outline review if drafting exposes a structural gap rather than silently reshaping the document.

## Gotchas

- If bullets are treated as paragraph placeholders, the outline becomes artificially granular and reviewers debate prose before agreeing on structure. Keep bullets at the concept level and decide paragraph shape during drafting.
- If every idea is numbered, hierarchy becomes indistinguishable from notes and content. Reserve numbering for actual reader-facing sections and express section intent in bullets.
- If plain-language editing renames a branded service or artifact, the document stops matching sales conversations and later deliverables. Preserve the canonical term and explain it more clearly around the term.
- If operational mechanics appear before orientation, non-technical readers encounter caveats before understanding the value or journey. Lead with the whole and disclose mechanics after the mental model is established.
- If illustration notes say only “add diagram,” later authors cannot judge whether the visual is useful or redundant. State its placement, reader purpose, and visual concept.
- If an illustration callout is indented beneath its section, Obsidian may render it as list content or fail to render the callout. Keep every callout line flush-left and rely on placement and labels for association.
- If each process visual invents a new visual language, readers must relearn the roles and symbols on every page. Reuse lanes, gates, touchpoint markers, direction, and labels consistently.
- If drafting begins before the outline is approved, prose makes weak sections feel expensive to change and structural review becomes copyediting. Keep the first iteration outline-only.

## Deliverables

The outline-stage deliverable is the eventual Markdown source file containing:

- the proposed title and numbered section hierarchy in reading order
- concept-level bullets beneath each section
- preserved canonical vocabulary
- flush-left proposed-illustration callouts with placement, reader purpose, and visual concept
- explicit unresolved questions or `TODO: Confirm` markers only where a high-impact decision remains unknown
- no finished prose or finished illustrations unless separately authorized

The outline is complete for its current iteration when a reviewer can understand the document's hierarchy, progressive disclosure, intended message in each section, terminology, and planned visual support without mistaking the outline for a finished draft.
