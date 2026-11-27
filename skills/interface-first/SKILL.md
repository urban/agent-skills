---
name: interface-first
description: Prepare, plan, design, ticket, and implement demonstrable UI slices using the project's actual interface, matched before-and-after review, and scoped feedback. Use for interface-first setup, feature shaping, interaction or visual refinement, reviewed task creation, and authorized slice execution.
---

# Work interface first

Choose the current decision, make it operable, and carry its accepted direction into the running product. This is one workflow with selectable playbooks, not a mandatory sequence.

## Invariants

- Preserve the running application, unrelated work, accepted behavior outside the requested change, and existing authorization. Ask only about material unresolved choices; recording or handing off an approved decision does not require another approval.
- Inspect and operate the existing interface before creating a variant or separate component. Try its supported states, styles, configuration and compositions first; name the unmet requirement that justifies an addition. Use actual application components and styles for proposals. Supply controlled dependencies through existing seams; label simulations. Simulated operation does not establish provider feasibility, persistence, device behavior, or production acceptance.
- Follow the [workflow contract](references/workflow-contract.md) for named units, semantic interfaces, ownership and review coverage. Apply project-specific filenames, package boundaries and tooling without inventing public exports or machines for every state.
- Maintain the owning design and decision records under the [design-record convention](references/design-records.md). Preserve exact approval scope and revision. Design approval, implemented behavior, verification, and human acceptance are separate facts.
- Use the [review contract](references/review-contract.md) for comparisons and feedback. Evidence supports a decision; passing automated checks alone does not establish fidelity.

## Select principles

Before choosing a new variant, component, wrapper or review tool, locate and read `principle-reuse-before-reinventing` when available through host discovery or the library inventory. Resolve its actual `SKILL.md` rather than assuming a sibling installation path. The invariant above remains applicable when this skill is installed alone.

Read each applicable leaf before applying it. Use principles together with project guidance and contextual tradeoffs. Explain a consequential choice they changed, rather than listing names or assigning binary principle scores.

- **[Operable outcomes](principles/operable-outcomes.md)**: Product scope or effort is pulling attention away from what the user can evaluate.
- **[Compare equivalent states](principles/compare-equivalent-states.md)**: A comparison could misattribute differences in content, state or timing.
- **[Preserve settled decisions](principles/preserve-settled-decisions.md)**: A revision risks reopening approved choices or changing adjacent consumers.
- **[Explore before committing](principles/explore-before-committing.md)**: A new interaction has consequential unresolved alternatives.
- **[Proportionate evidence](principles/proportionate-evidence.md)**: Evidence or documentation is growing beyond the decision it serves.
- **[Semantic boundaries](principles/semantic-boundaries.md)**: Names, state ownership, reuse or package placement need a boundary decision.

Project-specific visual principles and composition grammar remain in the project's design reference and owning ADRs. These reusable leaves guide reasoning without replacing accepted product direction.

## Playbooks

Read the project's instructions and the overview and affected entries in its design reference, normally root `DESIGN.md`. Follow only the state, source, owner, accepted-design, and latest-feedback links needed for this request. Resolve project paths, tools, and execution policy through [project bindings](references/project-bindings.md). Expand reading only to answer a named question.

Open the matching playbook. If the request combines outcomes, compose its relevant steps within the existing authorization; do not run every playbook.

| Current user intent                                                   | Playbook                                  | Result                                                            |
| --------------------------------------------------------------------- | ----------------------------------------- | ----------------------------------------------------------------- |
| Prepare an existing UI for focused iteration                          | [Setup](playbooks/setup.md)               | Usable design map, named modules, reproducible review coverage    |
| Choose or revise a demonstrable slice                                 | [Planning](playbooks/planning.md)         | Compact reviewed scope and flow                                   |
| Explore/refine behavior or appearance; assess implementation fidelity | [Design](playbooks/design.md)             | Matched comparison, rationale, scoped feedback and current target |
| Turn reviewed scope into tickets                                      | [Create tasks](playbooks/create-tasks.md) | Verified tracker handoffs and real dependencies                   |
| Implement an authorized slice                                         | [Execute](playbooks/execute.md)           | Verified integrated result, ready for required human acceptance   |

A spacing revision enters design directly. Planning can use design to settle a flow. Missing preparation becomes focused prerequisite work, not an automatic project-wide setup rerun. Ticket creation alone starts no implementation.

## Delegate and deliver

Use [delegation](references/delegation.md) when focused workers improve the current loop. The coordinator owns routing, user feedback, integration and canonical updates. Give workers exact ownership and relevant file paths, not the whole library. Small work can stay with the coordinator. Project execution policy controls concurrency and worker reuse.

Templates in `assets/` support the selected playbook; adapt existing equivalent records instead of generating another document set. Generated work stays in the project, never in this skill. End with the result, artifact/task links, verification and its limits, and the unresolved decision or next action. Do not create a separate summary file when an existing record suffices.

Validate local links with `python3 <skill-dir>/scripts/check-links.py`; pass additional Markdown files or directories to inspect project references. This checks paths and Markdown heading fragments, not external URLs or runtime behavior. Run the helper's tests with `python3 -m unittest discover -s <skill-dir>/tests`.

Hosts load supporting files differently. In Noodle, `references/` may be eagerly bundled; explicitly read only the selected `playbooks/` and `principles/` files and any tool skill needed. Do not assume naming a resource loads it. Scheduling, host permissions and model selection remain outside this portable workflow.
