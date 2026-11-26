# Source notes and alpha drift

## Sources read

### XState v5 to v6 migration guide

- Local source: `.dotai/repos/xstate/migration.md`
- Checked repository commit: `ab75632`
- Checked package version: `xstate@6.0.0-alpha.25`

Key evidence used:

- transition handlers are inline functions and `enq` describes queued effects
- returned context is a shallow patch in the checked source
- schemas are Standard Schema-compatible but do not currently perform runtime validation
- state-specific context/input, typed `actor.trigger`, `createAsyncLogic`, executable effects, persistence versioning, logical timers, and custom runtime operations
- `initialTransition` and `transition` are pure and return executable effect objects
- `executeEffects` accepts a partial `ActorSystemRuntime`, while complete behavior depends on every operation used by the machine

The checked XState source and tests were used to resolve details not visible in prose, especially:

- `packages/core/src/transition.ts`
- `packages/core/src/system.ts`
- `packages/core/src/transitionActions.ts`
- `packages/core/test/custom-interpreter.test.ts`

### Sandro Maglione, “XState v6 alpha”

- URL: <https://www.sandromaglione.com/newsletter/xstate-v6-alpha>

Key evidence used:

- Effect Schema works through `Schema.toStandardSchemaV1`
- state-specific context narrows through `snapshot.matches`
- `createAsyncLogic` can bridge an Effect runtime into an XState-owned actor
- expected tagged failures can be returned as output and exhaustively handled in `onDone`
- `actor.trigger` removes event-object boilerplate

### David Khourshid, “Effective State Machines with XState”

- URL: <https://www.youtube.com/watch?v=m-dSS55VO3Y&t=819s>
- Relevant section begins near 12:32; Effect/XState comparison continues through the end.

Key evidence used:

- XState and Effect both wanted to own runtime, so the integration should separate runtime ownership deliberately
- `initialTransition` returns initial snapshot plus effects; `transition` maps current snapshot plus event to next snapshot plus effects
- XState can remain a pure description of behavior while Effect executes returned work
- the Effect prototype mapped actor state, mailbox, ongoing work, and children to Ref, Queue, Effects, and Fibers
- the same video-player machine worked with HTML5 and YouTube by swapping an Effect service Layer
- Effect is the execution engine/race car; the state machine is the behavioral map

The transcript also stresses that the talk's Effect implementation was exploratory. The skill therefore preserves the architecture but uses checked current v6 executable-effect and runtime contracts rather than treating talk code as a production library.

## Conflicts and stale alpha syntax

The blog captured an earlier v6 alpha and is conceptually useful, but some syntax differs from the checked migration guide/source:

- Use `actors`, not older `actorSources` wording.
- Current transition handlers return shallow context patches; do not spread the whole context solely because an earlier alpha article said full context was required.
- `setup` still accepts actions, actors, guards, and delays in the checked source.
- Verify current `createAsyncLogic`, invoke, and Effect result APIs in installed types before copying an alpha snippet.

When sources disagree, use this priority:

1. installed package types and tests
2. checked current XState v6 source/tests
3. migration document for the matching commit
4. article and talk for architecture and examples
5. prior XState v5 knowledge last

## Effect version boundary

The checked Effect repository was Effect v4-era source at commit `028bbb3`. Relevant current APIs included:

- `Context.Service`
- `ManagedRuntime.make`, `runPromise(..., { signal })`, and disposal
- `Queue`, `SubscriptionRef`, scoped fibers, and `TestClock`
- `Schema.toStandardSchemaV1`
- `effect/unstable/reactivity/Atom`, `Atom.runtime`, and `AtomRegistry`

Effect Atom and XState v6 are both moving surfaces. Agents should inspect package locks and installed declarations before finalizing imports or helper names while preserving the architectural invariants in this skill.
