# Local Project Skills CLI Ticket Planning

Break down the approved Local Project Skills CLI specification into Task Manager Tickets for implementation in the current `agent-skills` worktree.

Use the stable registered `task-manager` and `to-tickets` skills from `/Volumes/Code/personal/task-manager/skills/` and the repository's `.tasks` Store. Plan Tickets only; do not implement product code while performing this workflow. This document controls the planning process but is not a backlog: Task Manager Tickets remain the only durable implementation tracker.

## Authority and boundaries

- Treat `specs/local-project-skills-cli.md` as the normative product, CLI, filesystem, safety, test, and acceptance contract.
- Treat its **Terminology** section as the canonical product vocabulary.
- Treat its **Test strategy** section and numbered **Acceptance criteria** as the mandatory evidence contract.
- Follow `AGENTS.md` for repository conventions and the requirement to keep `README.md` concise.
- Treat current source, tests, generated help, installed Effect sources, and the referenced `task-manager-next` configuration as implementation evidence unless an authoritative project document says otherwise.
- Treat `/Volumes/Code/personal/task-manager-next/specs/lean-v1-ticket-planning.md` only as a planning-pattern reference. Do not import Lean V1 product requirements such as a two-package architecture, Actor Identity, libSQL, Store resolution, or one Task per `tm` command.
- Use the stable coordination CLI at `/Volumes/Code/personal/task-manager/packages/cli/src/bin.ts`, never a project command or implementation artifact created by this initiative.
- Use `/Volumes/Code/personal/agent-skills/.tasks` as the coordination Store. Pass it explicitly with `--storage-path` to every `tm` read or mutation.
- Stop if the stable skills, stable CLI, Store, specification, or repository instructions cannot be verified.

### Planning instruction precedence

For this workflow, this document supersedes conflicting generic planning instructions in the stable `to-tickets` skill only for project-specific hierarchy, decomposition, implementation progression, Description and Context content, Definition of ready, and approval questions.

The stable skills continue to govern coordination safety, CLI-only Store mutation, first-class Executor handling, draft-before-create approval, creation, dependency recording, validation, and stop-on-failure behavior.

In particular:

- the `add` command Task is an administrative capability container rather than the default Task-level tracer bullet described by the generic skill;
- `install` is a native alias of the same command value and handler, not a second command Task;
- behavioral implementation belongs in Subtasks, even when the generic skill would represent the same slice as a Task;
- dependency edges belong on the most specific blocking Subtasks rather than on the complete command Task;
- the Description and Context requirements in this document replace the generic creation templates;
- the product-specific progression, first-behavior ownership rules, Definition of ready, coverage requirements, and approval questions in this document control decomposition.

When the instructions are compatible, follow both. When they conflict, follow this document for planning content without weakening the stable skills' coordination and storage-safety rules.

## Hierarchy

1. Create one real root Epic for the complete Local Project Skills CLI initiative. The approved specification defines one initiative, not independent phases. Never create a fake umbrella Epic.
2. Create one Task for the public `agent-skills add [target]` capability. Include `agent-skills install [target]` as its required native alias; never create a duplicate `install` Task or handler.
3. One small cross-cutting Task may establish the required single-package Bun, Effect, TypeScript, lint, format, and test boundary before command behavior.
4. One late cross-cutting Task may own evidence that genuinely spans the accumulated command surface, such as process-level qualification, emitted-layout source resolution, concise README usage, and final acceptance coverage.
5. Do not create cross-cutting Tasks for internal layers such as schemas, catalog repositories, filesystem adapters, planners, renderers, transaction services, path utilities, or CLI infrastructure.
6. Put implementation work in behavioral Subtasks under the appropriate Task. Use multiple Subtasks only when the outcomes have independently meaningful acceptance boundaries and each fits one fresh LLM context.
7. Use only `epic -> task -> subtask`. Parent Epics and Tasks are administrative containers and complete only after their child work and aggregate final acceptance criteria are satisfied.
8. Parent containers and implementation Subtasks default to the `agent` Executor. Use `human` only for a genuine person-only decision, credential, private action, or approval gate. The product's interactive selector does not make implementation work human-executor work, and planning approval is not itself a Ticket.

## Command-led planning methodology

Plan implementation as an ordered sequence of safe, working `agent-skills add` tracer bullets. Reach observable command behavior quickly, then grow shared architecture from the first behavior that requires it.

### Minimal structural bootstrap

One bounded bootstrap Task may establish the product package before command work:

- create the one private ESM package required by the specification;
- pin Bun, Effect v4 RC, YAML, TypeScript, Vitest, OxLint, and OxFmt dependencies and commit `bun.lock`;
- establish strict project references, package exports, the Bun shebang and runtime edge, an importable command-runner seam, and only the smoke evidence needed to prove compilation and process entry;
- keep the branch green without predeclaring the complete domain model, building generic filesystem or transaction services, implementing catalog or registry behavior, or completing the final CLI framework;
- do not copy Lean V1's two-package bootstrap, workspace layout, or task-manager-specific configuration.

This bootstrap is the only permitted structural prerequisite. The actionable frontier after it must enter real `agent-skills add` behavior.

### First-behavior ownership

A shared capability belongs to the first behavioral Subtask that needs and publicly proves it. Recommended module names in the specification describe seams, not mandatory implementation Tasks.

- The first selector Subtask should introduce the minimal Effect command tree, native `install` alias, optional directory argument, target normalization, source-root capability, complete catalog validation, and terminal prompt composition needed to show a safe selector and make quit or zero-selection leave the target unchanged.
- Complete source discovery and validation must succeed before a prompt is shown. Do not defer metadata, duplicate-name, containment, included-symlink, or other whole-catalog safety checks until after selection.
- The first registry-aware selector Subtask should introduce the Effect Schema registry boundary, missing-registry behavior, malformed-state failures, and preselection by stable skill name. It must not silently treat malformed registry state as empty.
- The first planning Subtask should prove a complete desired-state plan and exact transformed bytes through pure transformations plus scoped target inspection. It should introduce routing, Git ignore, deterministic registry encoding, unmanaged-collision checks, path-kind checks, and destination expectations only as required by the planned outcome.
- Before ordinary synchronization is allowed to mutate a target, the command must already recover or finalize a pending transaction before registry decoding and unmanaged-collision checks. Startup recovery must use a Schema-validated, containment-checked journal and the same recovery operation used by cooperative rollback.
- The first ordinary mutating synchronization Subtask must stage complete replacement trees, write a durable validated journal before target replacement, preserve rollback evidence, roll back cooperative expected failures, commit the registry last, and clean up only when safe. Transaction and restart safety are not later hardening.
- If this exceeds one fresh context, first create a prerequisite behavioral Subtask that proves startup recovery and finalization through the command against hand-built interrupted disposable targets. Do not enable ordinary synchronization mutation until that prerequisite has landed.
- The mutating behavior must never merge generated trees file by file or mutate before complete planning and preflight.
- Managed refresh and no-op behavior should introduce full expected-versus-actual destination comparison. `sourceDigest` alone never proves that a generated destination is unchanged.
- Deselection and retired-source behavior should build on landed managed-skill classification and remove only names owned by the prior registry.
- Cross-surface qualification should prove accumulated CLI help, version, alias, target, output, exit, interruption, source-layout, emitted-layout, and real-process behavior rather than introduce a second command framework.

### Default implementation progression

Use this progression unless a source-backed blocker requires a different order:

1. minimal single-package bootstrap;
2. a fully validated deterministic catalog and safe `add`/`install` selector with no target mutation on quit;
3. versioned registry decoding and existing-selection preselection;
4. pure desired-state planning and exact routing, Git ignore, registry, and transformed-toolbox expectations;
5. startup rollback or committed-transaction finalization against interrupted disposable targets, unless it safely fits in the first ordinary mutation packet;
6. one fresh-target selected-skill synchronization through staged replacement, durable journal, cooperative rollback, registry-last commit, and safe cleanup, blocked by startup recovery when that behavior was split;
7. managed no-op detection, source refresh, destination-drift replacement, and source/category moves with stable identity;
8. deselection, retired sources, and name changes as removal plus separately selected new identity;
9. remaining malformed-state, symlink, path-kind, rollback-failure, and recovery-failure packets that are too substantial for earlier Subtasks;
10. process-level CLI qualification, concise README usage, and final acceptance coverage.

This progression is a planning heuristic, not new product authority. Change it when a Subtask cannot start or finish correctly without another landed behavior, and record that dependency at the Subtask level.

### Staged command completion

The `add` Task's Subtasks do not need to execute as one uninterrupted chain. Parallel work is allowed only when each branch can land green independently and does not conflict over the same command, synchronization, or transaction seam.

For example, pure registry decoding and pure text transformations may be independently plan-able after the first command seam exists, but two fresh agents should not concurrently reshape the same command handler. A recovery prerequisite may establish the validated journal and shared restore operation before the first ordinary mutating Subtask without blocking earlier non-mutating catalog work.

Do not add dependency edges merely to make catalog, registry, planner, filesystem, and CLI work appear in tidy architectural phases.

## Fresh-session contract

Each agent-executor Subtask is owned by exactly one fresh LLM session.

Every Subtask must:

- deliver one narrow, independently meaningful behavioral or specification-mandated safety outcome;
- fit in one fresh context window;
- leave the branch green and independently verifiable;
- be understandable from its own Description and Context plus cited authoritative sections;
- state in-scope and out-of-scope behavior explicitly;
- identify the narrowest public proof seam that establishes the outcome;
- identify prerequisite Tickets and the exact landed behavior assumed from each;
- distinguish existing files from files expected to be created by earlier work;
- exclude sibling work, speculative cleanup, architecture for its own sake, and unrelated future failure families.

Do not require an executor to read the parent Epic, parent Task, or sibling Tickets to discover its assignment. Parent Tickets may provide orientation, but every selected Subtask must be a self-contained execution packet.

Split a proposed Subtask when it contains multiple independently meaningful success paths, failure families, rollback matrices, recovery states, or acceptance boundaries. In particular, ordinary synchronization, injected rollback, interrupted-process recovery, malformed-journal rejection, and rollback-failure reporting should not be forced into one oversized packet.

## Description and Context ownership

Description defines **what the Ticket must accomplish**. Context defines **how a fresh executor should perform that work well**.

Do not duplicate the same material across both fields. Do not hide required scope or acceptance criteria only in Context.

### Epic and Task fields

For an Epic or administrative Task, use this Description shape:

```markdown
## Capability

The complete initiative or public capability represented by this container.

## Final acceptance criteria

- [ ] Observable aggregate criterion.
- [ ] All required child outcomes are complete.

## Source

- `specs/local-project-skills-cli.md`, exact sections and acceptance criteria.
```

Its Context contains only shared product vocabulary, command and architecture constraints, integration relationships, and the child Subtask map needed to coordinate the capability. It must not masquerade as a fresh-session implementation assignment.

### Subtask Description

Use this shape:

```markdown
## Outcome

One sentence stating the independently useful behavior to implement.

## In scope

- Specific success behavior included in this Ticket.
- Specific boundary, invariant, or failure behavior included in this Ticket.
- Specific pure, filesystem, or CLI behavior required for this outcome.

## Out of scope

- Related behavior owned by another Ticket.
- Later drift, rollback, recovery, or process behavior.
- Cleanup or abstraction work not required for this outcome.

## Acceptance criteria

- [ ] Observable behavior through the named proof seam.
- [ ] Required safety, ordering, or failure-precedence behavior.
- [ ] Focused verification and `bun run check` pass.

## Source

- `specs/local-project-skills-cli.md`, exact section.
- `specs/local-project-skills-cli.md`, exact test-strategy bullet or numbered acceptance criterion.
```

Keep the Outcome to one sentence. Prefer two to six precise bullets in each remaining section. Every acceptance criterion must belong to this Subtask alone. Do not use “implement the specification” or cite only the file without exact sections or criteria.

### Subtask Context

Use this shape:

```markdown
## Execution approach

Use repeated red -> green cycles through the named seam: add one failing behavioral test, confirm the expected failure, implement only enough to pass, and repeat.

## Proof seam

- Primary: named pure transform, application service with scoped real filesystem, exported Effect CLI runner, or real Bun process.
- Integration: any additional seam required for this outcome, or “None.”

## Prerequisites

- Ticket <id or approved draft subject> provides <specific landed behavior>.
- None, when the Subtask has no prerequisite.

## Relevant project context

- `path/to/file` — why this existing or expected file matters.
- Ticket-specific contract, safety ordering, typed-failure, or deterministic encoding constraint.
- Disposable filesystem, terminal, fault-injection, or permission control needed to prove behavior.

## Verification

- Focused: `<exact focused command>`
- Full: `bun run check`

## Result evidence

Record implemented behaviors, tests added, exact verification commands and outcomes, and any authoritative conflict discovered.
```

Context must contain only information that changes how this Subtask is executed. Do not include narrative history, complete spec summaries, sibling scope, generic Effect advice, or unrelated files and invariants.

## Behavioral tracer bullets and proof seams

Decompose command work into vertical behavior rather than internal layers.

The specification defines three principal proof seams:

1. **Pure transformation seam** for metadata and registry codecs, desired-state planning, frontmatter transformation, managed routing, Git ignore, deterministic encoding, and other byte-level behavior.
2. **Scoped filesystem integration seam** using real Effect FileSystem and Path composition with disposable source and target roots for discovery, copying, permissions, staging, replacement, rollback, and recovery.
3. **CLI seam** using the exported Effect CLI command or runner, adding a real Bun process when parsing, terminal interaction, stdout, stderr, exit status, executable composition, current working directory, or module-relative source resolution is under test.

Use the narrowest public seam that proves the Ticket. Do not require every Subtask to exercise all three seams. A filesystem-focused Subtask must still prove observable application behavior through a real scoped composition rather than private helpers. A CLI adapter rejection must prove that no target mutation occurred and, where relevant, that prompting or application services were not invoked.

Additional rules:

- Add shared abstractions only while delivering the behavior that first requires them. The Ticket outcome remains public behavior or required safety, not creation of the abstraction.
- Do not create “add schemas,” “build SkillCatalog,” “implement SyncPlanner,” “create filesystem adapter,” “implement transaction service,” or “wire CLI framework” Subtasks.
- A complete, conflict-checked synchronization plan is an acceptable behavioral safety outcome; a file that merely defines plan types is not.
- Preserve full decoded descriptions, entrypoint body bytes, nested toolbox structure, hidden-entry exclusion, executable state, and symlink distinctions in the Tickets that first require them.
- Do not treat a mocked filesystem as evidence where the specification requires real scoped temporary directories.
- Never test by modifying the developer's real skills checkout or a real target project.
- Use expand-migrate-contract only if a later wide mechanical change cannot land green as vertical slices; this new implementation should not begin with migration Tasks.

## Test-first execution contract

Every implementation Subtask must require:

1. Repeated red -> green cycles, one specified behavior at a time.
2. Testing through the appropriate public proof seam: a pure exported behavior, a scoped application service with real temporary filesystems, the exported Effect CLI runner, or the real Bun process.
3. No bulk-written speculative tests, private-helper tests, or mocked internal collaborators when the public seam can prove the behavior.
4. Deterministic test control for terminal input, injected filesystem failures, executable permissions, interruption, or recovery state when those concerns are in scope.
5. Focused verification during development and `bun run check` before completion.
6. Concrete behavior, test, and command evidence in the Ticket Result.

## Dependencies

- Record every true blocker as a first-class Ticket edge with `--blocked-by` or `tm block`.
- Put edges at the most specific Subtask level possible.
- Add an edge only when the blocked Subtask cannot start or finish correctly without the prerequisite's landed behavior.
- Parent-child hierarchy is not itself a blocker edge.
- Do not block the complete `add` Task merely because one advanced Subtask needs a journal, managed destination, or recovery behavior.
- Prefer a sequential chain when fresh agents must evolve the same command, synchronization, or transaction seam.
- Permit parallel Subtasks only when they can land green independently without conflicting file or seam ownership.
- Final process qualification may depend on all behavioral packets it proves. README work should depend on the stable command and help contract it documents.
- In Context, explain only the exact behavior assumed from each prerequisite. Do not use dependency prose instead of a CLI-recorded edge.
- Ensure the graph is acyclic, has an actionable bootstrap, and reaches real command behavior immediately after that bootstrap.

## Coverage contract

Before requesting approval, build a coverage matrix that maps:

- all 20 numbered product acceptance criteria;
- every material pure transformation, filesystem integration, and CLI test-strategy bullet;
- every required typed-failure family;
- every synchronization phase and startup-recovery ordering requirement;

to one or more proposed Subtasks or an explicit aggregate criterion on the final qualification Task.

The matrix is a planning check, not a reason to create one Ticket per bullet. Group evidence when one fresh-session behavioral outcome naturally proves several related bullets. Split it when a proposed Ticket crosses independent success, failure, rollback, or recovery boundaries.

Do not approve a draft with uncovered criteria, vague “covered globally” claims, or duplicated ownership that leaves agents unsure which Ticket must supply the evidence.

## Definition of ready

Do not propose or create a Subtask unless all answers are yes:

- Does it have exactly one independently meaningful outcome?
- Can one fresh LLM session complete it?
- Are in-scope and out-of-scope behaviors explicit in Description?
- Does every acceptance criterion belong to this Subtask?
- Can it land green without unfinished sibling work?
- Is the correct pure, filesystem, CLI-runner, or real-process proof seam named?
- Are exact specification sections, test bullets, and acceptance criteria cited?
- Are prerequisite behaviors explicit and represented by Ticket edges?
- Can the executor understand the assignment without reading parent or sibling Tickets?
- Is the outcome observable behavior or a specification-mandated safety property rather than only an internal layer?
- If it introduces shared machinery, is that machinery required and publicly proved by this exact outcome?
- Before ordinary synchronization mutation is enabled, are startup recovery ordering, complete planning, preflight, staging, cooperative rollback, durable journal, and registry-last ownership semantics preserved?
- Are source validation and unsafe-entry checks complete before any selector is shown?
- Are substantial drift, rollback, interruption recovery, malformed journal, and rollback-failure matrices split when needed?
- Are exact focused and full verification commands supplied?
- Are expected new files not misrepresented as existing implementation evidence?
- Are unrelated history, generic guidance, speculative cleanup, and future behavior absent?
- Does the initial actionable frontier reach real `agent-skills add` behavior immediately after the minimal bootstrap?
- Are `add` and `install` treated as one implementation capability?
- Does the complete draft cover every product acceptance criterion and required evidence family?

## Planning workflow

### 1. Verify and inspect

Before drafting:

- verify the stable registered `task-manager` and `to-tickets` skills resolve from `/Volumes/Code/personal/task-manager/skills/`;
- verify `realpath "$(command -v tm)"` resolves to `/Volumes/Code/personal/task-manager/packages/cli/src/bin.ts`;
- run the Executor-support checks required by the stable `to-tickets` skill;
- validate `/Volumes/Code/personal/agent-skills/.tasks` and list existing Tickets with `--all-executors` before drafting, so the plan does not duplicate or conflict with existing work;
- read the complete `specs/local-project-skills-cli.md`, this document, and `AGENTS.md`;
- inspect the current repository shape, verification commands, and only the referenced `task-manager-next` package/tooling patterns needed to size Tickets;
- distinguish current files from the expected repository changes listed in the specification;
- identify the minimal single-package bootstrap and the first safe end-to-end selector behavior;
- identify which Subtask first needs each shared command, catalog, registry, planning, filesystem, transaction, and output behavior;
- build the acceptance and test coverage matrix while drafting.

Stop exploring when enough evidence exists to draft bounded Tickets. Do not begin implementation. Ask focused clarification questions only when missing information changes hierarchy, acceptance boundaries, dependencies, Executor, or an authoritative product decision.

### 2. Draft the hierarchy

Present the Epic, narrowly justified Tasks, behavioral Subtasks, implementation progression, dependency edges, and coverage matrix before running `tm create`.

Before detailing the complete hierarchy, show the proposed initial development path through at least:

1. minimal single-package bootstrap;
2. fully validated catalog and working `add`/`install` selector;
3. registry-aware preselection;
4. complete fresh-target synchronization planning;
5. the first transactionally safe selected-skill installation.

Reject and revise a draft if those outcomes are hidden behind separate schema, service, filesystem, path, transaction, or CLI framework rails.

For every proposed Ticket include:

- Subject;
- Level;
- Executor;
- Parent;
- Blocked by;
- complete Description;
- concise Context;
- proof seam for every implementation Subtask;
- exact source traceability.

State the total number of Epics, Tasks, Subtasks, and Tickets. Confirm that every agent Subtask passes the Definition of ready. Identify:

- the first actionable product tracer bullet;
- every later behavior intentionally staged behind another prerequisite;
- the first Subtask that owns each shared command, catalog, registry, planning, routing, ignore, filesystem, transaction, recovery, and process behavior;
- every proposed parallel branch and why it can land green without conflicting ownership;
- coverage of all acceptance criteria, test families, and typed failures.

### 3. Request approval

Ask:

- Does every Subtask fit one fresh LLM context?
- Are all in-scope and out-of-scope boundaries clear?
- Does any Subtask still contain multiple independently meaningful success, failure, drift, rollback, or recovery families?
- Does the plan deliver working command behavior early instead of building horizontal framework rails?
- Are `add` and `install` correctly represented as one capability and implementation?
- Does complete catalog validation occur before the selector is shown?
- Before the first ordinary mutating slice, has startup recovery landed, and does that slice preserve complete preflight, staged replacement, cooperative rollback, durable journal, and registry-last safety?
- Are all dependencies true blockers at the most specific Subtask level?
- Are the proof seams and Executors correct?
- Does the coverage matrix account for every acceptance criterion and required test family?
- Should this exact hierarchy now be created?

Wait for explicit approval unless the user supplied an already-approved concrete hierarchy and explicitly requested immediate creation.

### 4. Create and validate

After approval:

1. Rerun the stable skill's state-changing preflight against `/Volumes/Code/personal/agent-skills/.tasks`, including validation and a fresh all-Executor listing to detect drift since approval. If Store drift conflicts with the approved hierarchy, stop, revise the affected draft, and obtain renewed approval before creating anything.
2. Create parents before children and capture exact IDs from `tm create --json`.
3. Pass `--storage-path /Volumes/Code/personal/agent-skills/.tasks` and an explicit `--executor agent` or `--executor human` to every create.
4. Write substantial approved Markdown through `--description-file` and `--context-file`.
5. Add every approved dependency edge using captured IDs and the same explicit Store.
6. Stop on the first create or dependency failure instead of changing approved intent.
7. Run `tm validate` and `tm list --all-executors` against the explicit Store.

Report the created hierarchy, IDs, Executors, dependency edges, validation result, coverage status, and actionable frontier.

## Gotchas

- Separate `add` and `install` Tasks duplicate one native Effect CLI command and invite divergent handlers.
- Multiple phase Epics or a fake umbrella Epic obscure that this specification defines one product initiative.
- Lean V1's two-package, Actor, Store, or libSQL design does not apply to this single-package CLI.
- Horizontal schema, catalog, planner, filesystem, transaction, parser, or renderer Tickets create framework rails without a usable command outcome.
- A giant “implement synchronization” Subtask cannot fit a fresh session and hides independent no-op, drift, removal, rollback, and recovery boundaries.
- Deferring startup recovery, complete preflight, staging, cooperative rollback, journaling, or registry-last ownership to later hardening makes the first ordinary mutating slice unsafe by design.
- Validating only selected skills can show an incomplete catalog and silently deselect previously managed skills; validate the whole source catalog before prompting.
- Treating `sourceDigest` as proof of destination equality misses local drift, hidden files, symlinks, wrong entry kinds, executable changes, and extra entries.
- Ordinary registry decoding or unmanaged-collision checks before startup recovery can misclassify an interrupted new install.
- Merging generated directories file by file leaves retired and drifted entries; replace managed trees from complete staged trees.
- Flattening copied skills or stripping frontmatter from nested Markdown breaks relative references and violates byte-preservation rules.
- Following symlinks during discovery, comparison, replacement, rollback, or recovery can escape owned paths. Preserve the specification's distinct source, ancestor, managed-leaf, and internal-drift rules.
- Combining ordinary synchronization, injected rollback, interrupted recovery, malformed journal, and rollback failure into one Ticket overloads a fresh executor.
- Recommended module names are not mandatory classes or independent deliverables.
- Mock-only filesystem tests do not satisfy the required scoped real-composition evidence.
- Tests must never use the developer's real checkout or target project as writable state.
- Interactive product behavior is not a reason to assign implementation to the human Executor.
- Planning approval is a workflow gate, not a human-executor Ticket.
- Vague source citations, duplicated Description and Context, or reliance on parent Tickets make fresh-session assignments unsafe.
- A verbose catalog or architecture manual in `README.md` violates the repository instruction to keep it human-facing and concise.
- Ticket creation before explicit approval bypasses the stable `to-tickets` workflow and locks in an unreviewed hierarchy.
