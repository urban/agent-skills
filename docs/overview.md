# Overview

Organize by responsibility and scope. A skill owns a capability, a playbook sequences work, and a principle guides a decision. These are authoring roles, not separate platform file types.

## How the pieces fit

```mermaid
flowchart TD
    Goal[User goal]
    subgraph Coordinator[Optional coordinating skill folder]
        Mode[Mode SKILL.md]
        Playbook[playbooks/task.md]
        Mode -->|selects| Playbook
    end
    subgraph Capability[Capability skill folder]
        Skill[SKILL.md]
        Local[principles/rule.md]
        Detail[references/ or topics/]
        Tools[scripts/ and assets/]
        Skill -.->|applies| Local
        Skill -.->|reads as needed| Detail
        Skill -.->|executes or uses| Tools
    end
    Other[Another capability skill]
    Shared[Shared principle skill]
    Goal --> Mode
    Goal -->|direct use| Skill
    Playbook -->|references at the relevant step| Skill
    Playbook -->|references at the relevant step| Other
    Mode -.->|applies| Shared
    Skill -.->|applies| Shared
    Other -.->|applies| Shared
```

Boxes group files by owner. Solid arrows route work; dotted arrows select guidance or resources. Local principles stay with their owner; shared principles serve several skills. Supporting files are optional and loaded only when needed.

## Repository layout

```text
docs/                           Human-facing library guides
skills/
  <skill>/
    SKILL.md                    Discovery, scope, core guidance, routing
    playbooks/<task>.md          Optional task procedures
    principles/<rule>.md        Optional local decision rules
    references/<detail>.md      Conditional contracts, rubrics, examples
    topics/<subject>.md         Optional subject-based knowledge leaves
    scripts/                    Executable helpers and checks
    assets/                     Templates and files used in output
  principle-<name>/SKILL.md      Shared decision rule
in-progress/                    Drafts awaiting promotion into skills/
```

Create only the directories a skill needs. A short skill can be one `SKILL.md`. Keep generated work and project-specific records in the consuming project.

## Taxonomy

| Role | Use when | Home |
| --- | --- | --- |
| Workflow skill | A reusable job requires a procedure or produces a defined result. | `skills/<name>/SKILL.md` |
| Knowledge/capability skill | Standards and judgment apply within many possible tasks. | `skills/<name>/SKILL.md` |
| Mode skill | Working conventions and routing coordinate several capabilities. | A normal skill, optionally owning playbooks |
| Playbook | One task variant needs a particular sequence within its owning workflow. | `<skill>/playbooks/<task>.md` |
| Local principle | A durable decision rule depends on one skill's domain or contract. | Inline if short; otherwise `<skill>/principles/<name>.md` |
| Shared principle skill | The same durable judgment applies across capabilities and deserves a stable name. | `skills/principle-<name>/SKILL.md` |
| Reference or topic | Supporting detail needs conditional reading, without independent invocation. | The owning skill's `references/` or `topics/` |

## Rules

- Keep each skill focused on one coherent responsibility. Multiple steps alone do not justify a separate playbook or skill.
- Put discovery triggers in the frontmatter `description`; put scope, core guidance, and conditional reading links in `SKILL.md`.
- Separate **Rules** from **Constraints**. Use **Gotchas** for consequential failure patterns. Knowledge skills teach decisions without inventing workflows or deliverables.
- Keep workflow-wide invariants in the owning entrypoint. Keep task-specific sequencing in its playbook and domain-specific judgment in its local principles.
- Give each contract one owner. Reference it instead of maintaining competing copies. A specialized skill adds domain-specific guidance to a shared principle.
- Prefer architecture, types, lint, tests, or scripts when they can enforce a recurring correction. More prose is not the default fix.

## Promote or keep local

Promote a local rule into a shared principle when it expresses the **same durable judgment across several capabilities and deserves a stable name**. It should change a concrete decision, remain useful outside its original workflow, and have clear applicability and tradeoffs. Repeated wording alone is insufficient; there is no fixed reuse count.

On promotion, move the general rule to `skills/principle-<name>/SKILL.md`, give it a precise description, and replace local copies with references. Keep specialized examples and exceptions with their owning skill.

Keep a rule local when its meaning relies on that skill's vocabulary, evidence contract, or procedure. For example, general boundary validation can be shared; how one app's verification harness resets its fixtures stays local.

## Playbook contract

A playbook contains its entry conditions, required inputs or reading, ordered steps with meaningful branches, completion evidence, and the result or handoff. Include stopping conditions where partial failure matters. Keep shared invariants in the owner rather than repeating them in every playbook.

The owning `SKILL.md` links each playbook with a selection condition. A playbook references another skill at the step that needs it, naming the capability, why it applies, and the expected result. Leave that skill's internal procedure to its owner.

Use relative links for bundled files. Resolve separate skills by name through host discovery; a tightly bundled stack can use explicit relative links. Make required dependencies clear and handle unavailable capabilities explicitly. Naming a file or skill does not load it: instruct the agent to read the applicable entrypoint or leaf.

## Constraints and gotchas

- Do not load every playbook, principle, or reference by default; select by the current decision.
- Do not promote project facts, temporary incidents, or personal preferences into universal principles.
- Do not assume folder placement propagates instructions to delegates; pass the relevant entrypoint and file paths.
- Extract an independently useful job into its own skill; keep a workflow-specific branch as a playbook.
- Validate frontmatter, local links, and executable helpers when they change. Behavioral checks should test useful outcomes, not prescribed wording.

This convention draws on [pstack's routing](https://github.com/cursor/plugins/blob/main/pstack/docs/guide/02-poteto-mode.md) and [principles](https://github.com/cursor/plugins/blob/main/pstack/docs/guide/08-principles.md), with local examples in [interface-first](../skills/interface-first/SKILL.md) and [effect-best-practices](../skills/effect-best-practices/SKILL.md).
