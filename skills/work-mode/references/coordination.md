# Coordinate without losing ownership

Execution may stay with one agent. Use delegation only when permitted and when bounded ownership or an independent perspective improves the work. Host/project rules control availability, concurrency, models, and worker reuse; this skill grants no additional permission to spawn agents.

## Assign a bounded result

Give a worker the relevant [working contract](context-and-handoff.md), a concrete question or result, owned files/responsibilities, dependencies, permitted side effects, and completion evidence. State that others may be working in the same project; preserve their changes and accommodate their interfaces. Share the actual settled decisions and exceptions, not just the intended conclusion.

Avoid concurrent ownership of the same mutable artifact. Use independent read-only investigation or isolated edits where practical. Identify who owns integration, the canonical record, and user decisions. Do not delegate a decision the user must make, duplicate valid verification without a reason, or create another review gate merely because a worker was used.

## Integrate and continue

Treat worker reports as evidence to assess. Inspect their results, reconcile assumptions and conflicts against the recovered contract, and run the focused integration checks needed for the claim. The coordinator owns the original requested outcome, including work between assignments and final verification. A worker blocked on one dependency does not block independent work.

For lifecycle transitions, carry forward accepted choices, authorization, rationale, artifacts, and evidence limits. State the next question/result and why this stage is needed. Continue a covered transition without another approval round; ask only when scope, authority, or a consequential unresolved choice changes. A design-only request ends at design; an authorized implementation request continues past a useful design or prototype milestone.

Finish with the actual integrated state: completed result and verification, or a specific blocker/user decision with continuation context. Scheduling future work, opening a new chat, writing to a tracker, or publishing remains subject to the request and host policy.
