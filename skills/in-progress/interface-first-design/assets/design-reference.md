# {{Project or feature}} — interactive design reference

Working template: adapt to the project's existing artifacts and scale to the design scope. Replace drafting fields in completed output. Split sections into files only when useful; keep one authoritative reference.

## Brief and sources

- Users and intended outcomes: {{users and tasks}}
- Platform, scope, and exclusions: {{design boundary}}
- Requirements, existing behavior, and visual references: {{source paths or links}}
- Accepted constraints and consequential assumptions: {{decisions and assumptions}}

## Preview and artifact identity

- Editable source: {{path}}
- Runnable preview and instructions: {{entry point and command if needed}}
- Baseline identity: {{revision, version, or manifest; use hashes if exact bytes matter}}
- Preview-only controls: {{scenario controls excluded from product scope}}

## Journeys and behavior

| ID | Source requirement | Starting state and action | Observable transition/outcome | Alternate states and recovery |
| --- | --- | --- | --- | --- |
| {{ID}} | {{source}} | {{precondition and action}} | {{feedback and result}} | {{failure, cancellation, retry, retained work}} |

Include relevant exit/return behavior, state preservation, and dependencies between simultaneous views. Explain any product behavior that the preview only illustrates.

## Visual decisions

{{Accepted hierarchy, typography, color roles, spacing, geometry, layout, motion, and accessibility decisions. Reference the existing design system where applicable. Separate proposals and alternatives from accepted direction.}}

## Capability boundaries

| Interaction | Real mechanism or fixture | Simulated behavior | Remaining capability evidence |
| --- | --- | --- | --- |
| {{interaction}} | {{actual implementation or data provenance}} | {{controlled service or local state}} | {{proof needed beyond the prototype}} |

## Coverage and verification

- Requirement coverage and gaps: {{mapping or link; distinguish UI representation from product acceptance}}
- Checked revision and conditions: {{artifact identity, tool/surface, sizes, scenarios}}
- Actual results: {{observations, passed/failed checks, visual inspection, and captures}}
- Evidence paths: {{screenshots, results, or reproduction instructions}}
- Not checked and limitations: {{unavailable checks, untested mechanisms, and uncertainty}}

## Review and handoff

- Checkpoint and status: {{core journey / refined interface / complete design; proposed, in review, or approved}}
- What the user can evaluate: {{operable demonstration}}
- Feedback and resulting decisions: {{decision, source/date, affected behaviors, and unresolved questions}}
- Approval, only if explicit: {{who, evidence/date, scope, and approved baseline identity}}
- Planning/task handoff: {{source paths, accepted behavior IDs, simulated seams, open decisions, and remaining technical proof}}
- Proposed authoritative-document updates: {{requirements or plan changes requiring adoption; do not silently treat these as approved}}
