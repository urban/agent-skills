# Find and compose existing expertise

Resolve skill names through host discovery and the available project/library inventory. Inspect directory entries and resolve symlinked directories before declaring a skill unavailable. Categories and install paths differ; do not hard-code a machine's path or assume a category. Read the selected entrypoint and only the resources its instructions require.

Routing to another skill chooses its methodology; it does not authorize all of its possible outputs, tools, or side effects. Existing user choices override generic defaults. Preserve the Work Mode contract through the specialist workflow and return to the original outcome afterward.

## Call and return within a playbook

These are instructions at the step that needs expertise, not a required agent/chat protocol. The caller retains ownership of the original outcome.

1. Locate and read the specialist entrypoint. Supply the relevant recovered goal, current state, settled choices/rationale, authorization, source/target references, concrete question and expected result. Read only its applicable procedure/resources.
2. Follow the specialist's procedure within that assignment. Return the actual decision/approval state, source/revision/artifact references, evidence and simulations/limits, unresolved questions and next implications in proportion to the task. Reuse existing owning records; no universal schema or handoff file is required.
3. Resume the caller's playbook. Assess what the result establishes, incorporate it into the owned plan/task/change, resolve remaining dependencies and continue covered work. A blocked specialist may leave independent caller work possible. Specialist success does not expand authorization or replace overall integration/verification.

For example, planning asks Interface First to resolve one flow, consumes its proposed or accepted design and limits, then finishes scope/dependencies. Execution asks for fidelity against the accepted target, consumes findings or authorized repairs, then completes integration and verification. Direct use of Interface First ends at its requested UI result unless the user also authorized broader work.

## Specialist boundaries

| Decision / requested result | Route |
| --- | --- |
| Product/feature contract or specification | `to-spec`; consume existing design and experiment findings rather than restarting discovery |
| Consequential engineering rationale, alternatives, acceptance, supersession | `write-adr`; keep proposed and accepted records distinct |
| UI design iteration, matched comparison, scoped feedback, UI review readiness or fidelity assessment/repair | `interface-first`; return its result to the calling playbook. General setup, planning, task creation and execution stay in Work Mode |
| Codebase quality or development-process improvement | `continuous-improvement`; select the codebase-review or retrospective lens as directed by the Work Mode playbook |
| Patch/PR regressions and correctness | Project/host patch-review guidance; no automatic codebase-review transition |
| Creating or changing a skill | `build-a-skill` or host skill-authoring guidance directly; it remains a separate workflow |
| Reusing, extending, or introducing a variant, wrapper, component, service, adapter, or tool | `principle-reuse-before-reinventing` when available; read it before choosing a new implementation. Keep existing configuration and supported composition among the options |

Select technical knowledge by the actual question: ownership/contract decisions may need architecture, language modeling may need TypeScript, and Effect lifetime/failure/composition may need the relevant Effect skill. Resolve available names rather than assuming aliases. Do not load them all because the project happens to use those technologies. A selected methodology can require broader inputs: for example, `continuous-improvement` owns its full principle-discovery and reading contract. Follow that contract without turning it into Work Mode's default for unrelated work.

## Unavailable methodology

If a selected external skill cannot be located or read, name the missing methodology and its effect. Do not fabricate its instructions, copy an entire workflow into this gateway, or silently claim equivalent review coverage. Use an explicitly available project equivalent when it meets the requested lens and report the substitution. Otherwise recover context and gather safe, relevant evidence that remains useful; report the dependent stage as blocked and identify the source/access needed. Ask the user only for a material choice that cannot be resolved from available context.

Brainstorming and bounded prototyping are bundled here with adapted decision guidance from the existing standalone skills. Their source skills remain independent and unchanged. Review and retrospective intentionally reuse `continuous-improvement` rather than maintaining a second methodology. No external skill is declared as a metadata dependency or installed automatically.
