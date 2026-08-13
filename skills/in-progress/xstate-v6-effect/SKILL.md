---
name: xstate-v6-effect
description: Design TypeScript applications where XState v6 models legal behavior and decides when work occurs while Effect implements how work executes, with Effect Atom projections for frontend state. Use when building or reviewing backend actors, frontend state machines, Effect services, XState v6 machines, custom interpreters, or Effect Atom integrations.
---

## Rules

- Let XState own the behavioral map—states, legal events, transition timing, and emitted commands—while Effect owns execution—services, errors, resources, concurrency, interruption, retries, clocks, and telemetry.
- Choose one runtime owner per machine. Prefer an Effect-owned interpreter when the “when versus how” separation is the goal; use an XState actor with an Effect boundary only when XState runtime features or framework bindings are the deliberate choice.
- Treat `initialTransition(machine, input?)` and `transition(machine, snapshot, event)` as pure reducers returning `[snapshot, executableEffects]`; never assume they execute effects.
- Serialize events through one mailbox because concurrent calls against the same snapshot can lose transitions and violate actor semantics.
- Represent work requested by a pure machine as a typed outgoing command algebra, preferably through `schemas.emitted` and `enq.emit(...)`; have Effect execute commands and feed typed result events back to the machine.
- Define XState v6 schemas with `Schema.toStandardSchemaV1(...)`, but decode untrusted input with Effect Schema at the actual boundary because XState schemas currently drive inference and metadata, not runtime validation.
- Use state-specific context for data that exists only in one state, and narrow snapshots with `snapshot.matches(...)` before reading it.
- Scope every mailbox loop, child fiber, timer, subscription, listener, and managed runtime so stopping the machine interrupts work and releases resources.
- Keep Effect Atom as a reactive projection and dispatch surface over the machine service; do not create a second source of truth for machine state in atoms or components.
- Verify the installed XState v6 alpha types before authoring because the API is still moving; prefer local package source and tests over v5 memory or older alpha blog syntax.

## Constraints

- Do not use v5 APIs such as `assign`, `enqueueActions`, `fromPromise`, `sendParent`, `spawnChild`, `stateIn`, `interpret`, or transition arrays in v6 authoring APIs.
- Do not run both `createActor(machine)` and a custom Effect transition loop for the same machine instance.
- Do not place `Effect.runPromise`, raw I/O, DOM access, service acquisition, or long-running work inside transition functions in Effect-owned mode.
- Do not call `effect.exec()` blindly in an Effect-owned interpreter; custom actions can bypass typed Effect services, and built-in effects require an intentional `ActorSystemRuntime` implementation.
- Do not claim generic actor, timer, persistence, or invocation support from a partial custom interpreter. Either implement the complete required runtime semantics or constrain the adapter explicitly.
- Do not collapse expected Effect failures into XState `onError`. Return expected tagged outcomes as data/events; reserve rejection and `onError` for defects or explicitly chosen infrastructure failure policy.
- Do not duplicate machine-derived flags such as `isSubmitting` or `hasFailed` in Effect Atom or React state.
- Use current Effect v4 APIs and preserve precise typed errors, service requirements, and scoped cleanup.

## Knowledge Boundaries

Applies to:

- XState v6 machine authoring with Effect Schema
- Effect-hosted XState transition loops for backend or frontend applications
- XState-hosted async logic that delegates execution to an Effect runtime
- Effect service, Layer, Queue, SubscriptionRef, Fiber, clock, and persistence boundaries around machines
- Effect Atom and React projections over machine snapshots
- deterministic machine, interpreter, and Atom tests

Does not cover:

- automatic migration of a v5 codebase
- a production-ready universal replacement for XState's actor runtime
- distributed exactly-once execution without an outbox, workflow engine, or equivalent durability protocol
- broad UI architecture unrelated to the machine boundary

Decision inputs:

- installed `xstate`, `effect`, and Effect Atom versions
- whether XState or Effect must own clocks, fibers, cancellation, child actors, and supervision
- whether the machine uses `invoke`, spawn/listen APIs, delayed events, persistence, or rehydration
- whether commands are short, long-running, cancellable, durable, or correlated with replies
- whether the UI needs `@xstate/react`, Effect Atom, or both for distinct responsibilities

Failure modes this knowledge helps avoid:

- mixing v5 and v6 syntax
- two runtimes racing to execute the same behavior
- pure transitions that secretly perform I/O
- unvalidated events entering through schema-typed APIs
- blocked mailboxes, leaked fibers, stale snapshots, and duplicated frontend state
- typed Effect failures becoming rejected promises or unstructured XState errors

## Patterns

### Select the runtime boundary

| Need | Preferred pattern |
| --- | --- |
| Effect owns clock, services, fibers, cancellation, and tests | Pure XState machine + Effect-owned interpreter |
| Existing `@xstate/react` application; only invoked work is Effectful | XState actor + one scoped `ManagedRuntime` bridge |
| Pure decision table with no lifecycle or side effects | Call `initialTransition` / `transition` directly |
| Generic `invoke`, spawn, listeners, timers, and actor trees under Effect | Implement the full XState `ActorSystemRuntime`, or keep XState as runtime owner |

### Keep the boundary directional

```text
external input
  -> Effect Schema decode
  -> serialized machine event mailbox
  -> XState transition: snapshot + event -> next snapshot + commands
  -> publish next snapshot
  -> Effect command handlers
  -> typed success/failure event back to mailbox
```

XState determines which work is legal and when it is requested. Effect determines how the command runs and how its typed outcome is produced.

### Use outgoing commands, not hidden callbacks

In Effect-owned mode, prefer `schemas.emitted` plus `enq.emit(command)` for domain commands. The returned executable effect contains a stable typed event payload that the Effect adapter can decode and interpret. Reserve `enq.raise` for internal machine events. Avoid `enq(fn)` for domain I/O because it embeds executable JavaScript in the machine result.

### Treat frontend and backend as different projections of the same boundary

- Backend: expose an Effect service with `send`, `getSnapshot`, and `snapshots`; implement it with a mailbox, a snapshot reference, and scoped fibers.
- Frontend: expose the service layer through `Atom.runtime(...)`; build a stream-backed snapshot atom and an effectful dispatch atom.
- React: render from `AsyncResult` and `snapshot.matches(...)`; components dispatch typed events and do not own orchestration.

Read the references before implementing the matching branch.

## Gotchas

- If an agent sees `schemas` and assumes validation happens automatically, malformed browser, HTTP, or queue messages enter a supposedly typed machine. Decode with Effect Schema before enqueueing.
- If `createActor` and an Effect mailbox both process the machine, actions and timers can run twice while snapshots diverge. Pick one runtime owner and expose only that owner's dispatch API.
- If `Effect.runPromise` appears inside a transition function, the reducer is no longer pure and cancellation, service requirements, and test control escape the Effect runtime. Emit a command instead.
- If long-running commands are awaited inside the mailbox loop, one network request blocks every later event. Fork scoped work, correlate its result event, and model cancellation explicitly.
- If a partial adapter forwards only custom actions but the machine later gains `after`, `invoke`, or spawned actors, behavior silently becomes incomplete. Reject unsupported executable effect kinds or implement the full runtime contract before enabling those features.
- If expected Effect failures reject `createAsyncLogic`, XState receives an untyped `onError` path and exhaustive domain handling disappears. Encode expected failures in a tagged output and use `onDone` to branch.
- If state-specific data remains in root context as optional or nullable fields, impossible combinations return and UI narrowing loses its value. Put data on the state that owns it and supply required context when targeting that state.
- If an Effect Atom mirrors `snapshot.value`, context, and loading flags in separate writable atoms, writes drift and impossible UI combinations reappear. Keep one snapshot atom and derive selectors.
- If a managed runtime, registry, or machine fiber is created per render or invocation, layers rebuild, subscriptions leak, and service identity changes. Create it once at the application or feature lifetime and dispose it with that scope.

## References

- [`references/architecture.md`](./references/architecture.md): Read when: choosing runtime ownership, command boundaries, actor semantics, persistence, or backend service shape.
- [`references/xstate-v6-authoring.md`](./references/xstate-v6-authoring.md): Read when: authoring schemas, state-specific context, inline transitions, commands, or replacing v5 syntax.
- [`references/xstate-runtime-boundaries.md`](./references/xstate-runtime-boundaries.md): Read when: using pure transition APIs, executable effects, `createAsyncLogic`, or an XState-owned actor that runs Effect programs.
- [`references/effect-integration.md`](./references/effect-integration.md): Read when: implementing an Effect-owned interpreter, mailbox, command handler, timer, shutdown policy, or full `ActorSystemRuntime`.
- [`references/effect-atom-frontend.md`](./references/effect-atom-frontend.md): Read when: exposing machine snapshots and dispatch through Effect Atom and React.
- [`references/testing.md`](./references/testing.md): Read when: testing pure transitions, Effect interpreters, timers, failure feedback, cancellation, persistence, or Atom projections.
- [`references/source-notes.md`](./references/source-notes.md): Read when: checking which claims came from the v6 migration guide, Sandro Maglione's alpha article, or David Khourshid's talk, especially where alpha syntax conflicts.
