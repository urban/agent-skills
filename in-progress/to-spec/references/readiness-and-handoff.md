# Readiness and handoff

## Readiness belongs to a defined scope

Distinguish:

- **Draft:** the contract is being developed or awaiting approval.
- **Blocked:** named unresolved commitments, evidence, access, or prerequisites prevent the identified scope from executing.
- **Ready to execute:** the identified scope is approved, consequential unknowns are resolved, acceptance is actionable, and dependencies/delivery constraints are understood.

Do not create a status bureaucracy: use the project's vocabulary and explain the actual state. A broad product direction can be approved while only one slice is executable. Do not hide dependencies on blocked work to call a slice independent.

Readiness does not require specifying every module, prewriting tests, a full task breakdown, or another review round for unchanged commitments. Approval of an earlier revision can be reused only while its scope and material commitments still hold.

Check semantic readiness separately from mechanical document checks:

- Are scope and important behavior accepted rather than merely proposed?
- Are necessary evidence/ADR decisions resolved for this scope?
- Can an executor determine success and consequential failure behavior?
- Are access, dependencies, and delivery obligations known?
- Are remaining choices genuine implementation discretion rather than unspecified product behavior?

## Delivery conditions

Describe only applicable obligations: compatibility and migration, configuration and access, rollout boundaries, rollback/recovery, user documentation, and operational evidence. State who or what is expected to establish delivery when that is known; do not invent an owner.

Keep these outcomes separate:

1. The specification is approved and ready to execute.
2. Implementation satisfies acceptance criteria, with recorded verification evidence.
3. The change is delivered in the intended environment, with applicable rollout/operational evidence.

The specification defines future obligations. It must not claim that implementation or delivery occurred.

## Preserve one source of truth

Use the explicit destination or project convention; otherwise choose a concise file under the project root's `specs/`. Read an existing spec before updating it. Keep stable acceptance IDs across revisions; do not renumber unrelated criteria just for neatness.

Verify the saved document and relative links. If a project requires a different format, use its checks instead of forcing the bundled template. A link check cannot verify that the linked ADR is accepted or that research actually supports a claim.

Remote publication is optional and requires authorization plus a resolved destination. If requested, preserve the full contract, verify the resulting record, and report uncertain writes honestly rather than blindly creating duplicates. No tracker label is assigned by default.

## Compact execution handoff

Include:

- the spec and applicable ADR/evidence locations
- the approved executable scope and actual readiness
- acceptance IDs and an already-established verification approach or command, if available
- applicable delivery conditions and prerequisites
- unresolved nonblocking choices left to the executor
- the next authorized action, or the decision/evidence needed to unblock work

Reference the source of truth rather than copying the entire document into tickets or chat. The handoff prepares execution; it does not authorize implementation, deployment, or ticket creation.
