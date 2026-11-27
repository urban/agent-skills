# Bind the workflow to a project

Read project instructions first. Find its existing design entry point, normally root `DESIGN.md`, and use the overview plus affected entries. Reuse established locations and conventions. When absent, establish the affected design/review entries through [review readiness](review-readiness.md), proportional to the assignment. A broad foundation is conditional, not a prerequisite to every refinement.

Keep a concise **Workflow integration** section in that map, linking existing operational instructions rather than copying them. Record only observed commands, reachable entries and accepted policy:

| Binding          | Resolve from the project                                                                                                           |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Records          | Design map, implementing owners, accepted targets, ADR numbering, evidence locations and approval provenance            |
| UI modules       | Named-element convention, semantic entry filenames, supported imports, review colocation/discovery and runtime exclusions          |
| Review operation | Selected tooling skill, launch/readiness/health instructions, scenario IDs, fixtures, reset paths, isolation and cleanup ownership |
| Verification     | Exact required checks, their claims, stop/escalation conditions, and bounded live or human acceptance gaps                        |
| Execution        | Permitted source edits, writable ownership, commit policy and applicable human feedback checkpoints                                 |

If a binding is missing, inspect the relevant implementation, existing scripts and accepted decisions before asking. Report material gaps and continue independent work. Do not invent commands, model availability or past design intent. A focused revision does not require completing unrelated bindings.

Map foundational UI, product interaction, domain/capability and host responsibilities onto the actual architecture. Neither package names nor TypeScript, React, Storybook, a specific tracker or model roster are imposed by this skill. Use available tool-specific skills when relevant; otherwise use the project's existing mechanics and state any inspection limits.

For code-level decisions, use `principle-test-capabilities` for test boundaries and real versus simulated evidence, or `project-hygiene` for module ownership, initialization, and compiler or analyzer policy, when available through host skill discovery. These complement the project's bindings and the UI review contract; they do not add mandatory workflow steps.

For portable installation, keep this skill's internal files together and resolve their links relative to the file containing them. Project paths are resolved according to the project's records. No principle requires a sibling skill. A host that ignores invocation metadata or eagerly bundles references still needs explicit reads of the selected playbook and principle leaves.
