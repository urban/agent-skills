# Local Project Skills CLI

## Status

Approved product direction. This specification defines the first implementation of project-local skill installation for the `agent-skills` repository.

## Purpose

Add a Bun-native Effect v4 RC CLI that lets a user select skills from this repository and install them into another project as local, progressively disclosed agent instructions.

The CLI owns two levels of routing:

1. The user selects the complete set of skills relevant to a target project.
2. The target project's `AGENTS.md` tells an agent which local `SKILL.md` entrypoint to read when a selected skill's complete source description matches the task.

The copied skill bodies are generated local state. The target registry and routing section are project state that may be committed.

## Product decisions

- Runtime: Bun.
- Effect version: `4.0.0-rc.108`, matching `task-manager-next` at the time this specification was written.
- CLI framework: the Effect v4 RC CLI exported by `effect/unstable/cli`. Do not add or use the legacy `@effect/cli` package and do not implement a second argument parser, prompt framework, help generator, or command router.
- Command: `agent-skills add [target]`.
- Command alias: `agent-skills install [target]`, implemented with Effect CLI command aliasing rather than a duplicate command handler.
- Package manager: Bun `1.3.13`.
- Repository shape: one non-monorepo package with production code in `src/` and tests in `test/`.
- Discovery includes stable skill categories and `skills/in-progress/`. In-progress skills are visibly labeled as drafts in the selector.
- Selection is desired-state synchronization. Selected skills are installed or refreshed. Previously managed skills that are deselected are removed.
- The target is an optional positional directory. It defaults to the current working directory. The CLI does not search upward for a Git root.
- The target registry is `.context/agent-skills.json` and may be committed.
- Generated skill copies are stored under `.context/skills/` and ignored by Git.
- Existing managed copies are refreshed from their source. An unmanaged destination collision is an error.
- The full decoded source `description` is copied into `AGENTS.md` without shortening, clause extraction, rewriting, or paraphrasing.
- A skill is copied as a complete directory toolbox. Only the copied entrypoint loses YAML frontmatter.
- Hidden files and directories whose basename starts with `.` are not copied.
- Symlinks in the included source tree are rejected.
- Included regular files are copied as bytes. Executable permission is preserved.

## Goals

1. Discover and validate every installable skill in this repository.
2. Present a deterministic interactive multiselect with existing target selections preselected.
3. Preserve each selected skill's complete non-hidden directory structure and relative references.
4. Strip YAML frontmatter only from the copied `<skill>/SKILL.md` entrypoint.
5. Maintain an idempotent routing section in target `AGENTS.md`.
6. Maintain an idempotent Git ignore entry for generated skill copies.
7. Maintain a versioned, deterministic registry that records desired selection and CLI ownership.
8. Refresh and remove managed copies without leaving stale generated files. A category or source-path move with an unchanged skill name is preserved as the same identity. A frontmatter `name` change is a removal plus a separately selected new skill, not an automatic rename.
9. Fail before mutation on invalid source metadata, duplicate identities, unsafe source entries, malformed registry data, malformed managed markers, or unmanaged collisions.
10. Make filesystem behavior testable through Effect services and verify the real composition with scoped temporary projects.

## Non-goals

- Installing skills into provider-global skill directories.
- Supporting a Node runtime or a second runtime adapter.
- Publishing to npm in the first implementation.
- Making `.context/skills/` committable.
- Modifying source skills while installing them.
- Rewriting links inside copied Markdown.
- Copying hidden skill files, hidden skill directories, symlinks, ownership, timestamps, ACLs, or extended attributes.
- Parsing the human-facing root `README.md` as a catalog.
- Automatically selecting skills from a target project's dependencies or source code.
- Supporting noninteractive skill-selection flags in the first implementation.
- Adding update, remove, list, or repair commands. Re-running `add` or `install` owns synchronization and removal.
- Implementing a general-purpose Git ignore engine.

## Terminology

### Source repository

The `agent-skills` package containing this CLI and the canonical `skills/` tree.

### Source skill

A directory below `skills/` containing an uppercase `SKILL.md` entrypoint with valid Agent Skills YAML frontmatter.

### Stable skill

A source skill not below `skills/in-progress/`.

### Draft skill

A source skill below `skills/in-progress/`.

### Target project

The existing directory supplied to `agent-skills add`, or the current working directory when the positional target is omitted.

### Managed skill

A target skill whose name is present in `.context/agent-skills.json`. The registry is the ownership authority.

### Unmanaged collision

An existing `.context/skills/<name>` path for a newly selected skill whose name is not owned by the current registry.

### Included source entry

A regular file or directory inside a selected source skill for which no relative path segment starts with `.`.

## CLI contract

### Commands

```text
agent-skills add [target]
agent-skills install [target]
```

`install` is the native Effect CLI alias of `add`. Help output shows the alias and both invocations execute the same command value and handler.

The root and subcommand use Effect CLI's command tree, help, version, unknown-command handling, argument parsing, path primitives where their exact semantics fit, and terminal prompt support.

### Target argument

- `[target]` is an optional Effect CLI directory argument.
- Omitted target resolves to `process.cwd()` at the executable edge.
- A supplied target must already exist and be a directory.
- Resolution produces one normalized absolute path before project services are constructed.
- The target does not need to contain `.git/`.
- Missing `AGENTS.md`, `.gitignore`, `.context/`, and `.context/agent-skills.json` are valid initial states and are created when required.

### Interactive selection

The command uses `Prompt.multiSelect` from `effect/unstable/cli/Prompt`.

Each choice contains:

- title: source frontmatter `name`, category, and `[draft]` for an in-progress skill;
- value: stable source skill identity;
- description: the complete decoded source frontmatter `description`;
- selected: `true` when the current registry contains the same skill name.

Recommended title forms:

```text
effect-core — engineering-with-effect
xstate-v6-effect — in-progress [draft]
```

Selection rules:

- Stable skills sort before draft skills.
- Within each group, sort by category and then skill name using deterministic code-point ordering.
- Zero selections are allowed so the command can remove all previously managed skills.
- On the first run, no skills are preselected.
- A terminal quit or interruption makes no target changes.
- Registry entries whose source name no longer exists are not choices and therefore become deselected. They are removed during a successful synchronization.
- Source discovery and validation must complete successfully before the prompt begins. A malformed catalog must never appear as an incomplete selector that could silently remove skills.

### Success output

On success, write one concise receipt to stdout ending in one newline. It reports:

- normalized target path;
- installed or refreshed skill names;
- removed managed skill names;
- unchanged selected skill names when source digest proves no copy was needed;
- paths of the registry, routing file, and generated skills directory.

A successful no-op exits `0` and says that the target is already synchronized.

### Failure output and exit status

- Success, help, version, and a confirmed no-op exit `0`.
- Expected validation, conflict, registry, marker, target, and filesystem failures exit `1`.
- Expected failures write to stderr and begin with `Error:`.
- Unexpected defects remain defects and are handled by the Bun Effect runtime.
- Do not call `process.exit` from application code.

## Source repository resolution

The source repository is resolved relative to the CLI module, not from the target working directory.

Both source execution from `src/` and emitted execution from `dist/` must resolve the package root containing `package.json`, `VERSION`, and `skills/`. The executable edge supplies this resolved root to the application as an explicit capability. Tests supply a temporary source root.

Failure to find the package root or `skills/` is a typed startup failure. Do not fall back to the target project, a home-directory convention, or an ambient global skills directory.

## Skill discovery and validation

### Discovery

- Recursively inspect `skills/` for files named exactly `SKILL.md`.
- Do not use the root README catalog as a source of truth.
- Do not descend into a directory whose basename starts with `.`.
- A `SKILL.md` directly or indirectly below `skills/in-progress/` is a draft. Every other discovered source skill is stable.
- Category is the first path segment below `skills/`.
- Source paths stored in the registry are slash-separated paths relative to the source repository root.

### Frontmatter

Parse the leading YAML document with a real YAML parser. The parser must not be a line-oriented `key: value` approximation.

A source entrypoint must:

- begin at byte zero with `---` followed by a supported line ending;
- contain a closing frontmatter fence;
- decode to a mapping;
- contain string `name` and string `description` fields;
- have a `name` matching `^[a-z0-9]+(-[a-z0-9]+)*$`;
- have a `name` no longer than 64 characters;
- have a `name` equal to the source skill directory basename;
- have a description no longer than 1024 characters;
- not contain either managed routing marker as a complete line.

The complete decoded description scalar is the routing description. Do not extract only `Use when` or `Use for` text. Rejecting marker lines prevents an otherwise valid description from creating a second apparent managed block without modifying the accepted description.

Unknown supported Agent Skills frontmatter fields do not affect installation. They remain in the canonical source and are absent from the transformed local entrypoint because the complete frontmatter document is removed.

### Catalog invariants

Discovery fails before prompting when:

- two source skills have the same decoded name, even when their categories differ;
- source metadata is malformed;
- a name does not match its directory;
- a discovered source skill is outside the canonical `skills/` tree after normalization;
- an included source entry is a symlink;
- an included source path would escape its selected skill root.

The whole source catalog is validated, not only the skills already selected in a target registry.

## Registry contract

### Location

```text
<context>/agent-skills.json
```

The concrete target path is:

```text
<target>/.context/agent-skills.json
```

The CLI never adds this file to `.gitignore`. It is intended to be committable. Existing broader target ignore rules are not rewritten or negated by this feature.

### Version 1 encoded form

```json
{
  "version": 1,
  "skills": [
    {
      "name": "effect-core",
      "source": "skills/engineering-with-effect/effect-core",
      "description": "Apply cross-cutting Effect v4 judgment. Use when those concerns are primary.",
      "draft": false,
      "sourceDigest": "sha256:<hex>"
    }
  ]
}
```

The production implementation uses Effect Schema for decoding and encoding this boundary.

Registry rules:

- Missing registry means version 1 with an empty skill list.
- Invalid JSON, unsupported version, wrong field type, duplicate name, invalid name, invalid relative source path, or invalid digest is a typed failure. It does not fall back to an empty or all-selected registry.
- Entries sort by skill name.
- Encoding uses two-space indentation and exactly one trailing newline.
- No timestamps are stored. Identical source and selection produce identical registry bytes.
- Destination is derived as `.context/skills/<name>` and is not duplicated in the registry.
- The registry description is refreshed from canonical source on every successful synchronization.
- The registry draft flag and source path are refreshed from discovery, allowing category moves without changing target identity.

### Source digest

`sourceDigest` is deterministic over all included source entries before destination frontmatter transformation. The digest includes, in sorted relative-path order:

- relative path;
- entry kind;
- executable versus non-executable mode for regular files;
- regular-file bytes.

It excludes hidden entries, symlinks, ownership, timestamps, ACLs, and extended attributes.

The source digest detects canonical source changes and is not a security signature. It does not by itself prove that the generated destination is unchanged.

For no-op detection, derive the complete expected destination tree from the current source, including the transformed entrypoint, and compare it with the actual destination tree. The comparison includes sorted relative paths, entry kinds, regular-file bytes, executable state, extra entries, hidden entries, and symlinks without following them. A managed destination is unchanged only when this full comparison matches. Any destination drift requires replacement.

## Copy and synchronization semantics

### Destination shape

A selected skill is installed as:

```text
<target>/.context/skills/<name>/
├── SKILL.md
├── references/
├── assets/
└── scripts/
```

Only directories and files present in the source are created. The displayed tree is illustrative, not a requirement that every support directory exist.

### Included and excluded entries

- Recursively copy every included regular file and directory.
- Exclude any file or directory when any relative path segment begins with `.`.
- Reject a symlink anywhere in the included tree, whether its target is internal or external.
- Preserve regular-file bytes.
- Preserve whether a regular file is executable. Other permission bits are not part of the contract.
- Do not copy empty hidden directories.
- Empty included directories may be preserved.

### Entrypoint transformation

For the copied `<name>/SKILL.md` only:

1. Parse and validate the canonical leading YAML frontmatter.
2. Remove exactly the opening fence, YAML document, closing fence, and at most one immediately following line break that separates frontmatter from the body.
3. Preserve the remaining body text, line endings, Markdown, links, and final newline exactly.

Do not:

- modify the source `SKILL.md`;
- strip frontmatter-like blocks from any nested Markdown file;
- rewrite relative links;
- flatten the skill directory;
- generate a replacement title or description inside the copied entrypoint.

Because the internal directory layout is preserved, references such as `./references/foo.md` and links between sibling reference files continue to resolve.

### Managed replacement

For each selected skill:

- If no destination exists, install it.
- If the registry owns the same name and the actual tree exactly matches the expected transformed tree, leave it untouched and report it unchanged.
- If the registry owns the same name and the actual tree differs, replace the entire generated path from source. This overwrites local edits and removes hidden, extra, wrong-kind, symlink, and upstream-retired entries.
- If the registry owns the same name but the leaf path is a regular file or another non-symlink kind, replace that owned leaf with the generated directory.
- If the managed leaf itself is a symlink, fail without following or replacing it.

For each previously managed but now deselected skill:

- Remove `.context/skills/<name>` recursively without following links.
- Remove its registry and routing entry.

For paths not named in the previous registry:

- Leave unrelated `.context/skills/*` entries untouched.
- If a newly selected name already exists with any path kind, fail with an unmanaged collision before changing anything.

The target, `.context`, and `.context/skills` ancestor paths must be real directories rather than symlinks. An internal symlink below a real managed skill directory is destination drift: do not follow it, and replace the owned skill directory from its parent.

## Target `.gitignore`

When at least one skill is selected, ensure the target root `.gitignore` contains the canonical entry:

```gitignore
/.context/skills/
```

Rules:

- Create `.gitignore` when missing.
- Preserve all existing bytes and comments except the minimal newline needed to append the entry.
- Treat the active exact forms `/.context/skills/` and `.context/skills/`, with an optional trailing slash, as equivalent explicit entries.
- Commented lines do not count.
- Do not attempt to interpret arbitrary parent patterns, negations, escaped patterns, or the complete Git ignore language.
- Append the canonical root-anchored form when no equivalent explicit entry exists.
- Never add `.context/agent-skills.json` to `.gitignore`.
- Never remove an existing ignore entry when all skills are later deselected.
- Repeated synchronization produces no duplicate entry.

## Target `AGENTS.md` routing

### Location and ownership

The routing file is uppercase root `AGENTS.md`:

```text
<target>/AGENTS.md
```

The CLI owns only the content between these exact markers:

```md
<!-- agent-skills routing start -->
<!-- agent-skills routing end -->
```

### Rendered section

For selected skills, render:

```md
<!-- agent-skills routing start -->
## Local project skills

Read the matching local skill before working on a task covered by its description.

### `effect-core`

Apply cross-cutting Effect v4 judgment about direct computations and failures. Use when those are the primary concern.

Read `./.context/skills/effect-core/SKILL.md`.
<!-- agent-skills routing end -->
```

For every selected skill:

- render the decoded name as the heading value;
- render the complete decoded description as its own Markdown block without shortening, clause extraction, rewriting, or paraphrasing;
- render the relative entrypoint path `.context/skills/<name>/SKILL.md`;
- sort sections by skill name;
- do not add a draft label to the name or description in routing. Draft status is selection and registry metadata.

### Update behavior

- If no managed block exists and at least one skill is selected, append the block after existing content with one blank line of separation.
- If exactly one valid managed block exists, replace it in place.
- Preserve all content before and after the managed block.
- Preserve the existing file's LF or CRLF convention where one is consistently detectable. New files use LF.
- Ensure exactly one final newline.
- If no skills remain selected, remove the managed block and its surrounding separator while preserving unrelated content.
- A missing start marker, missing end marker, reversed markers, nested marker, or multiple marker pair is a typed failure. Do not append a second block.
- Marker text outside the one managed block is considered malformed ownership state.

## Planning, staging, and failure safety

### Durable transaction area

The reserved transaction path is:

```text
<target>/.context/skills/.agent-skills-transaction/
```

It is inside the generated skills directory so the required Git ignore entry also covers an interrupted transaction. It is not a skill and is excluded from catalog, ownership, and unmanaged-skill checks.

The transaction area contains a versioned journal, complete staged replacements, and the backups needed to restore the prior target state. The journal records only normalized target-relative paths from a closed set owned by this feature. It includes hashes of the exact previous and next registry bytes and enough operation metadata to distinguish prior paths, newly created paths, and replacements. Journal decoding and path-containment validation use Effect Schema before any recovery mutation.

### Startup recovery

After resolving the target and before ordinary registry decoding or unmanaged-collision checks:

- If no transaction area exists, continue normally.
- If the transaction area exists without one valid journal, fail without touching it.
- If the current registry bytes match the journal's next-registry hash, the registry commit completed. Keep the new state and remove the transaction area.
- Otherwise, restore the previous managed directories, `AGENTS.md`, `.gitignore`, and registry from the journal backups; remove paths recorded as newly created; then remove the transaction area.
- Recovery never follows a symlink and never operates on a path outside the closed target-relative set in the journal.
- A recovery failure is reported as `TransactionRecoveryFailed` and ordinary synchronization does not begin.

This recovery runs before an interrupted newly installed directory can be classified as an unmanaged collision.

### Synchronization phases

The command has explicit phases:

1. Resolve source and target roots.
2. Recover or finalize a pending transaction.
3. Discover and validate the complete source catalog.
4. Decode and validate the current target registry.
5. Run the multiselect.
6. Build a complete synchronization plan in memory.
7. Validate managed markers, target path kinds, symlink safety, and unmanaged collisions.
8. Build complete staged replacements and backups in the transaction area.
9. Atomically write the durable journal before the first target replacement.
10. Apply the plan.
11. Write the registry last as the ownership commit record.
12. Remove the transaction area.
13. Print the receipt.

No ordinary target mutation occurs before the plan and preflight checks succeed. Creating the transaction area and durable journal begins the application phase.

Application requirements:

- Use atomic file replacement where the platform supports it.
- Replace managed skill directories from staged complete trees rather than merging file-by-file.
- Preserve prior managed directories and prior text files until their replacements are ready.
- On a cooperative expected failure during application, restore previous state through the same journal recovery operation and leave the previous registry authoritative.
- Scoped finalization removes an uncommitted transaction area only after successful rollback. It must leave a valid journal and backups intact when cleanup would destroy the evidence required for next-run recovery.
- Temporary names must not collide with user content and must not enter the registry.

Full cross-file transactional atomicity is not available from ordinary filesystem primitives. The durable journal, registry-last commit marker, staged replacement, rollback, and startup recovery are the required consistency model.

## Typed failures

Expected application failures are explicit tagged values. At minimum, distinguish:

- `SourceRepositoryNotFound`
- `SkillsDirectoryNotFound`
- `TargetNotFound`
- `TargetNotDirectory`
- `SourceSkillMalformed`
- `SourceSkillNameMismatch`
- `DuplicateSkillName`
- `UnsafeSourcePath`
- `SymlinkNotSupported`
- `RegistryMalformed`
- `RegistryVersionUnsupported`
- `ManagedRoutingMalformed`
- `UnmanagedSkillCollision`
- `DestinationPathConflict`
- `FileReadFailed`
- `FileWriteFailed`
- `FileCopyFailed`
- `PermissionUpdateFailed`
- `RollbackFailed`
- `TransactionJournalMalformed`
- `TransactionRecoveryFailed`

Failures carry the canonical path and skill name when those values are safe and useful. Platform errors retain enough reason information to distinguish not found, wrong path kind, permission denied, already exists, and other I/O failures.

A rollback failure must report both the original application failure and the rollback failure. It must not claim that the target is synchronized.

## Effect architecture

### Interfaces and seams

The implementation should expose a small application interface while keeping platform mechanics behind internal seams:

- `SkillCatalog`: discover and validate source skills.
- `ProjectRegistry`: decode and encode the target registry.
- `SyncPlanner`: pure desired-state comparison and conflict plan.
- `ProjectSkillInstaller`: execute one validated plan.
- `ManagedRouting`: pure `AGENTS.md` managed-block transformation.
- `GitIgnore`: pure idempotent ignore transformation.

These names are recommended module names, not a requirement to use classes. Public behavior and domain types are the required interfaces.

Filesystem, path, terminal, crypto, and stdio capabilities come from Effect services. Runtime-specific provision occurs only in `src/bin.ts` through `@effect/platform-bun`.

### CLI composition

- Use `Command.make`, `Command.withSubcommands`, `Command.withAlias`, `Command.run`, and `Command.runWith` from `effect/unstable/cli/Command`.
- Use Effect CLI `Argument.directory` and `Argument.optional` for the target argument when their pinned semantics satisfy the contract.
- Use `Prompt.multiSelect` for interactive selection.
- Export the command value or a `Command.runWith` runner from `src/main.ts` for tests.
- `src/bin.ts` owns the Bun shebang, `BunServices.layer`, CLI output layer, and `BunRuntime.runMain`.
- Application modules do not read argv directly and do not instantiate Bun filesystem APIs directly.

### Suggested source layout

```text
src/
├── bin.ts
├── main.ts
├── commands/
│   └── add.ts
├── domain/
│   ├── Errors.ts
│   ├── ProjectRegistry.ts
│   ├── SourceSkill.ts
│   └── SyncPlan.ts
├── services/
│   ├── ProjectSkillInstaller.ts
│   └── SkillCatalog.ts
└── text/
    ├── GitIgnore.ts
    └── ManagedRouting.ts
```

The exact split may change if a smaller interface produces a deeper module. Avoid one-file wrappers that only rename Effect FileSystem operations.

## Package and tooling setup

The repository becomes one private ESM package. It must not add Bun workspaces or `packages/` application code.

### Runtime dependencies

Pin:

- `effect`: `4.0.0-rc.108`
- `@effect/platform-bun`: `4.0.0-rc.108`
- a direct YAML parser dependency capable of standards-compliant YAML mapping and scalar decoding

Do not add `@effect/cli`. Effect v4 CLI is exported by `effect/unstable/cli`.

Do not add `@effect/platform-node` unless a later requirement introduces a genuine Node runtime adapter. Tests should replace Effect capabilities or use scoped temporary directories rather than introduce a second production platform.

### Development dependencies

Match `task-manager-next`:

- `@effect/tsgo`: `0.36.4`
- `@effect/vitest`: `4.0.0-rc.108`
- `@types/bun`: `^1.3.13`
- `oxfmt`: `0.49.0`
- `oxlint`: `1.77.0`
- `oxlint-tsgolint`: `7.0.2001`
- `typescript`: `7.0.2`
- `vite`: `7.3.3`
- `vitest`: `4.1.10`

Set `packageManager` to `bun@1.3.13` and commit `bun.lock`.

### Package entrypoints

The package defines:

```json
{
  "type": "module",
  "bin": {
    "agent-skills": "./src/bin.ts"
  },
  "exports": {
    ".": "./src/main.ts",
    "./package.json": "./package.json",
    "./bin": null
  }
}
```

`src/bin.ts` starts with:

```text
#!/usr/bin/env bun
```

The initial local distribution path is Bun source execution or `bun link`. TypeScript also emits `dist/` JavaScript, declarations, declaration maps, and source maps so a later publish mapping can be added without restructuring source.

### Scripts

Adapt the root scripts from `task-manager-next` without workspace indirection:

```json
{
  "check": "bun run format && bun run lint && bun run typecheck && bun run test",
  "format": "oxfmt -c ./oxfmt.config.ts",
  "lint": "oxlint --fix --tsconfig tsconfig.json -c ./oxlint.config.ts .",
  "prepare": "effect-tsgo patch --oxlint",
  "test": "vitest run",
  "typecheck": "tsc -b"
}
```

### TypeScript configuration

Adapt the strict `task-manager-next/tsconfig.base.json` rather than inventing a reduced configuration.

Use:

```text
tsconfig.base.json
tsconfig.json          # root solution
tsconfig.src.json      # src emission
tsconfig.test.json     # test no-emit
tsconfig.tools.json    # Vitest and Ox tool files
```

Requirements:

- Root solution references only source, test, and tools projects.
- Source includes `src/**/*.ts`, uses `rootDir: ./src`, `outDir: ./dist`, `composite: true`, `noEmit: false`, `noEmitOnError: true`, declaration maps, and source maps.
- Tests include `test/**/*.ts`, use `rootDir: .`, `noEmit: true`, `isolatedDeclarations: false`, and reference source.
- Tools include `vitest.config.ts`, `vitest.setup.ts`, `oxlint.config.ts`, and `oxfmt.config.ts` when required by typechecking.
- Preserve the Bun/ESNext, Bundler resolution, strictness, unchecked access, exact optional property, unused code, and Effect language-service diagnostics from the reference base configuration.
- Do not copy monorepo references, workspace catalog syntax, `packages/*` paths, or package-relative `../../` inheritance.

### OxLint and OxFmt

Copy and locally adapt the `task-manager-next` configurations:

- Effect `correctness`, `antipattern`, `effectNative`, and `style` presets.
- Type-aware linting.
- Warnings denied.
- The same strict plugin and rule set, including no `any`, no type assertions, no non-null assertions, no `null`, no async/await, no console, and no direct `process.exit`.
- Keep generated and tool-state ignores, including `dist`, `coverage`, `node_modules`, `.agents`, `.dotai`, and `.pi` as applicable.
- Keep `specs/**` excluded from OxFmt, matching the reference configuration.

Do not copy task-manager-specific self-hosting instructions or monorepo paths.

### Vitest

Adapt the reference Vitest setup:

- globals enabled;
- Node test environment;
- `test/**/*.test.ts` include pattern;
- `vitest.setup.ts` calling `@effect/vitest` `addEqualityTesters()`;
- V8 coverage configuration matching `task-manager-next` when coverage is run.

Tests must not depend on the developer's real `agent-skills` checkout as writable state or modify a real target project.

## Test strategy

### Pure transformation tests

Cover:

- valid YAML metadata decoding;
- quoted, folded, and literal YAML description scalars;
- malformed or missing frontmatter;
- name and directory mismatch;
- duplicate names across categories;
- stable versus draft classification and deterministic sort;
- removal of only entrypoint frontmatter;
- preservation of entrypoint body bytes and line endings;
- managed routing insertion, replacement, removal, and idempotency;
- malformed, reversed, nested, and duplicate routing markers;
- full unmodified decoded descriptions in routing;
- Git ignore creation, equivalent-entry recognition, append behavior, comments, final newline, and idempotency;
- registry schema, version rejection, deterministic ordering, deterministic encoding, and digest validation;
- desired-state planning for install, refresh, no-op, remove, unchanged-name source/category move, frontmatter-name change as remove plus unselected new identity, and retired source;
- source descriptions containing either routing marker as a complete line are rejected.

### Filesystem integration tests

Use scoped temporary source and target directories with the real Effect FileSystem and Path composition. Cover:

- full nested `references/`, `assets/`, and `scripts/` copy;
- links remaining valid because directory shape is preserved;
- nested Markdown content remaining byte-identical;
- hidden files and hidden directories excluded at every depth;
- included symlinks rejected before mutation;
- executable script permission preserved;
- source skill left unchanged;
- managed refresh removes files retired upstream;
- unmanaged collision rejects the whole plan;
- unrelated local skill directories remain untouched;
- missing target text files created;
- selected-all-to-selected-none removal;
- owned regular-file leaf replacement and owned symlink-leaf rejection;
- registry written last;
- staging and backups cleaned after success and successful rollback;
- injected expected failure rolls back prior managed state;
- an interrupted new install is recovered before unmanaged-collision checks;
- a journal with committed next-registry bytes is finalized rather than rolled back;
- malformed or unsafe journals fail without recovery mutation;
- rerun after an interrupted or partially applied replacement converges safely.

### CLI tests

Test the public command composition with Effect CLI's testable runner and test services:

- `add` and `install` invoke the same handler;
- omitted target uses supplied test cwd;
- explicit target uses Effect CLI directory parsing;
- help and version are owned by Effect CLI;
- unknown commands and invalid target arguments are handled by Effect CLI;
- multi-select shows stable and draft labels;
- registry selections are preselected;
- terminal quit makes no changes;
- success and expected-failure exit/output behavior is stable.

At least one process-level smoke test runs the Bun entrypoint against disposable source and target roots and asserts exit status, stdout, stderr, and generated artifacts.

## Acceptance criteria

The feature is complete when all of the following are true:

1. `bun install` creates a lockfile using the pinned Effect v4 RC and reference tool versions.
2. `bun run check` formats, lints, typechecks, and tests successfully.
3. `agent-skills add` is implemented with Effect v4 CLI and `agent-skills install` is its native alias.
4. Running from outside the source repository still discovers the source repository's skills.
5. The selector includes all stable skills and every skill under `skills/in-progress/`, with drafts visibly labeled.
6. Existing registry skills are preselected and the submitted selection is the complete desired state.
7. Selected skill directories are copied under `.context/skills/<name>/` with nested non-hidden resources preserved.
8. Hidden files and directories are absent from local copies.
9. Included symlinks fail preflight and produce no target changes.
10. Executable scripts remain executable.
11. Only the copied `SKILL.md` loses frontmatter; source and nested files remain unchanged.
12. Target `.gitignore` contains one explicit `.context/skills` ignore entry and does not ignore the registry.
13. Target `AGENTS.md` contains one managed section with every selected skill's exact decoded name, complete decoded description, and local entrypoint path.
14. Re-running with the same source and selection is a reported no-op with stable registry and routing bytes.
15. Refresh replaces managed trees and removes upstream-retired files.
16. Deselection removes only previously managed skills.
17. Unmanaged collisions, malformed registry data, malformed markers, invalid source metadata, and duplicate names fail before mutation.
18. The versioned registry is deterministic, committable, and written after the rest of a successful synchronization.
19. Tests prove durable-journal recovery, rollback, safe cleanup, idempotency, and convergence with scoped disposable projects.
20. The repository remains a single package with `src/` and `test/`, not a monorepo.

## Expected repository changes

```text
package.json
bun.lock
tsconfig.base.json
tsconfig.json
tsconfig.src.json
tsconfig.test.json
tsconfig.tools.json
oxlint.config.ts
oxfmt.config.ts
vitest.config.ts
vitest.setup.ts
src/**
test/**
specs/local-project-skills-cli.md
README.md                  # concise CLI usage only
.gitignore                 # generated build/test artifacts as needed
```

## Evidence used for this specification

- `AGENTS.md:1-8` defines this repository's skill authoring constraints.
- `README.md:5-16` defines categories and identifies `skills/in-progress/` as drafts.
- `skills/productivity/build-a-skill/references/frontmatter.md:4-43` defines source frontmatter, naming, and routing-description expectations.
- `skills/productivity/build-a-skill/references/structure.md:1-17` defines a skill as a complete directory toolbox rather than one Markdown file.
- `/Volumes/Code/personal/task-manager-next/package.json:10-40` provides the pinned Effect RC, Bun, Ox, TypeScript, Vite, and Vitest versions and root scripts.
- `/Volumes/Code/personal/task-manager-next/tsconfig.base.json:2-153` provides the strict compiler and Effect language-service configuration.
- `/Volumes/Code/personal/task-manager-next/oxlint.config.ts:1-109` provides the Effect presets and strict lint rules.
- `/Volumes/Code/personal/task-manager-next/vitest.config.ts:1-16` and `vitest.setup.ts:1-3` provide the Vitest baseline.
- Installed `effect@4.0.0-rc.108` exports `effect/unstable/cli`; its `Command.withAlias`, `Command.run`, `Command.runWith`, `Argument.directory`, `Argument.optional`, and `Prompt.multiSelect` sources establish the required command and prompt capabilities.
- Installed `@effect/platform-bun@4.0.0-rc.108` provides aggregate Bun filesystem, path, terminal, stdio, crypto, and process services through `BunServices.layer`, and process execution through `BunRuntime.runMain`.
