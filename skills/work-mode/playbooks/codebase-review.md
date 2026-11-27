# Review an existing codebase

## Entry conditions

Use for source/contracts/tests/configuration quality, maintainability, simplification, or ease of future changes in a selected subsystem or whole project. The object is the existing codebase, not just a patch. If the request concerns a PR/diff, use patch-review guidance instead; a related architectural question does not authorize a broader audit.

This playbook selects `continuous-improvement`'s codebase-review lens; that skill owns the review methodology, principle discovery/reading, standards, investigation, and improvement report.

## Procedure

1. **Recover review scope.** Establish project/subsystem, goals or reported pain, relevant revision, accepted decisions, and requested output. Ground the scope in the current code. Change history is a lead, not proof of poor design. Review alone grants no implementation/deletion/tracker authority; retain any implementation authorization the user already gave.
2. **Load the methodology.** Locate and read `continuous-improvement` through [skill routing](../references/skill-routing.md). Select its codebase-review playbook and follow its required principle/input discovery. Do not substitute a remembered summary or a generic checklist. Name unread/inaccessible requirements as coverage gaps.
3. **Execute the selected lens.** Follow its broad mapping, selective tracing of real behavior and callers, and evidence-backed simplification guidance within the requested scope. Keep source absence, observed failure, missing access, and inferred benefit distinct. Do not run retrospective unless process analysis is also requested.
4. **Return one ranked result.** Use its improvement-report contract, adapting existing project records. Include concrete evidence, the simpler target, migration/removal or justified retention, benefits versus effort/risk/confidence, focused verification, and useful code to preserve. Merge shared causes if both lenses were requested. State actual coverage and relevant gaps.

## Completion criteria

A prioritized, evidence-backed result addresses the requested codebase scope and recommends the next useful change. Whole-codebase coverage includes an initial broad map, with deeper inspected areas and uninspected areas disclosed. Expected benefits are not reported as measured gains. Recommendations remain distinct from executed changes.

## Conditional transitions

- A requested process inquiry adds [retrospective](retrospective.md) evidence to the same backlog; do not initiate it merely because history exists.
- If the user already authorized fixes, continue with the covered changes and focused verification; a ranked backlog alone does not fulfill that request. Otherwise report proposed next work without creating tickets or implementing it.
- An uncertain remedy may warrant a [bounded experiment](bounded-prototyping.md). Consequential spec/architecture changes route to `to-spec`/`write-adr` as relevant, preserving accepted choices and authority.
