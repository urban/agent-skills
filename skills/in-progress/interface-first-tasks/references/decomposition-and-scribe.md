# Decomposition contract and example

## From a slice to executable work

Start with the named journey, its source requirements, and entry/exit capability states. Allocate responsibilities only after those are clear. Typical responsibilities include contract/domain behavior, adapter implementation, presentation integration, recovery behavior, and integrated demonstration. These are prompts for judgment, not mandatory tasks or phases.

Use the project's existing task system. Preserve its IDs, status meanings, owners/executors, and actual dependency representation. When generating local Markdown, identifiers and explicit prerequisite lists are enough; do not invent tracker IDs, agent identities, or availability.

A task needs:

- A parent slice and source acceptance references.
- The concrete outcome and ownership boundary.
- Existing inputs/contracts and services to retain or replace.
- Prerequisites tied to actual required artifacts or behavior.
- Observable done criteria, appropriate verification, and limits on what the evidence establishes.
- A fresh-session handoff: source locations, relevant decisions, current state, next demonstration, and remaining simulations.

Keep requirements and workflow policy distinct. The user may want to review each slice; the product does not need a feature implementing that review process. Do not turn task prerequisites into new package dependencies merely to order builds.

## Scribe example: S03 — real WAV transcription

Illustrative task decomposition from the October 29, 2026 discussion. Read the current Scribe sources before adopting it. Existing implementations can eliminate tasks; open feasibility gates can block real provider integration. This is not acceptance evidence.

**Entry:** application commands, lifecycle, views, and controlled recognition/storage support an interactive import journey.

**Exit:** select a real local WAV and output destination, receive progressive real recognition, and publish matching companion/Markdown output. Unrelated capture remains simulated. Incomplete processing and save failures remain visible.

| Task    | Responsibility/outcome                                                                                                                 | Depends on                                   | Evidence                                                                                                                              |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| S03-T01 | Confirm/reuse input, result, revision, and failure contracts against the selected real adapter; document any proposed incompatibility. | Existing accepted slice contract             | The adapter can honor the contract, or affected work has an explicit decision/evidence blocker.                                       |
| S03-T02 | Connect native selection and validated local input/output capabilities; preserve source identity and ownership.                        | S03-T01                                      | Actual WAV selection, cancellation, invalid-input rejection, and protected destinations behave through the application path.          |
| S03-T03 | Supply the bounded real recognition adapter with scoped worker lifecycle and final-tail accounting.                                    | S03-T01; required provider-adoption evidence | Actual supplied audio yields accepted timed results; failed/stale worker outcomes do not claim completion.                            |
| S03-T04 | Supply canonical companion and matching Markdown publication through the existing save boundary.                                       | S03-T01                                      | Real files retain the accepted revision; publication failures remain truthfully unsaved/stale.                                        |
| S03-T05 | Wire real input, recognition, and save services at composition; exercise the import UI and demonstrate the integrated slice.           | S03-T02, S03-T03, S03-T04                    | A selected WAV produces progressive displayed text and saved artifacts; retained controlled scenarios reproduce delay/failure states. |

Recognition, storage, and UI tasks may overlap only after their contracts and ownership are usable. A task with an unmet provider gate is blocked even if an independent storage task can proceed.

### Example executor handoff

Implement S03-T04 within the current core/platform and desktop file ownership boundaries. Read the slice contract, current file contract, and relevant package instructions. Reuse the abstract storage/platform service; supply concrete filesystem behavior at the existing composition boundary. Preserve accepted recording/review state and never count companion publication alone as a matching Markdown save. Verify real filesystem outcomes and meaningful publication failures through the project's established tests. Report the observed revision/artifact outcomes and remaining simulations; do not start capture work.

## Review and follow-on work

The task set is ready when prerequisites are resolvable, task ownership is clear, criteria map to the selected outcome, and unresolved decisions identify their dependent tasks. A slice becomes demonstrated only after its integrated path is exercised. User acceptance is recorded only when given.

When a demonstration reveals a problem, append or revise refinement tasks under the affected slice, preserve their requirement/decision context, and reevaluate dependent slices. Do not silently rewrite completed evidence as if the revised behavior had already passed.
