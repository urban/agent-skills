# Engines, proxies, and testing

## Runtime ownership

Keep definitions importable without starting workers or choosing storage. `Workflow.toLayer(handler)` registers a handler with the supplied engine; it does not choose persistence. Compose domain services, handler layers, durable queue workers, engine, and transport at the application boundary.

`WorkflowEngine.layerMemory` owns maps and fibers for local development and tests. Replays work within that engine lifetime, but rebuilding the layer loses execution, activity, deferred, and timer state. `ClusterWorkflowEngine.layer` from `effect/cluster` requires sharding and message storage; its durable messages support recovery only when that storage and the surrounding cluster configuration actually survive the failure being modeled. Queue workers separately require a `PersistedQueue` factory and backing store. A persistent engine with a memory queue is not end-to-end durable.

## Caller and lifecycle contracts

- `execute(payload)` joins the logical execution and waits for its success or failure. Outside a workflow, a completion wake plus a fallback suspended-retry schedule keeps the caller waiting; this schedule is not a business-operation retry policy.
- `execute(payload, { discard: true })` returns its deterministic execution ID without waiting for business completion. Inside another workflow the child remains linked for completion wakes and interruption.
- `discard: true, detached: true` deliberately removes that child linkage. Do not later await the detached child by executing the same payload: joining it does not restore a completion wake to the parent.
- `poll(id)` returns `Option<Result>`: `None` is unknown **or currently running**; `Some(Suspended)` is parked; `Some(Complete)` contains a success or failure `Exit`. Preserve that ambiguity unless a separate index supplies stronger existence information.
- `resume(id)` requests replay, not a reset of stored activity results. Replaying a terminally completed execution does not make a new run. `Workflow.SuspendOnFailure` keeps the execution's own failure parked until explicit resume or interrupt; ordinary child/deferred wakes do not clear that failure gate.
- `interrupt(id)` is a safe, deposited interruption, not an immediate kill of running activities. It is applied at a suspension boundary, allowing completed-step compensation to be reconstructed. Treat this as a cancellation request and observe terminal state if the caller needs confirmation.

A workflow body's ordinary scope can finalize when it suspends. Use `Workflow.addFinalizer` for terminal workflow work, including observing deposited interruption, rather than treating body-level `Effect.onExit` as a terminal hook. A cluster owner abandoning an attempt for replay skips these workflow finalizers and compensations; owner-local resources must still be released. Compensation itself must tolerate recovery and cannot replace a durable reconciliation policy.

## Proxy boundary

`WorkflowProxy.toRpcGroup` and `toHttpApiGroup` reuse workflow schemas, but generate only execute, discard, and resume operations. `WorkflowProxyServer` wires those operations to the engine on the server. Polling, interruption, detached execution, authentication, and authorization are not supplied by this generated surface. Add explicit operations and access policy at the transport boundary when required; do not duplicate workflow schemas just to expose start-and-wait.

## Behavioral tests worth preserving

Use public execute/poll/resume and durable completion APIs for orchestration contracts. Choose memory engines for local semantic tests and persistent-engine restart/handover tests for crash-recovery claims. A layer-memory test cannot prove process survival.

- **Logical identity:** execute the same logical payload twice and assert one external operation and the same execution ID; also distinguish tenant or operation keys that must not collide.
- **Replay:** finish a charge activity, park on a deferred, explicitly resume, then reject the deferred. Assert that the workflow body replays, the charge does not rerun, suspension does not refund, and terminal failure compensates the recorded charge once. This mirrors `WorkflowEngine.test.ts`'s “layerMemory compensates a completed activity only once after replay”.
- **Suspended activity:** put child waits inside an activity and count both body entries and external mutations. Assert replay is possible without interpreting repeated body entry as duplicate business work. Exercise bounded fan-out as well as unbounded concurrency when ordering affects progress.
- **Timers:** observe that the workflow has parked and its long timer is registered before advancing `TestClock`. Set `inMemoryThreshold: 0` when the test is meant to exercise durable scheduling; elapsed logical time alone does not prove that registration happened.
- **Ownership:** keep persistent storage shared across engine/runner reconstruction while replacing the owner. Assert recovery of queued work without premature compensation, and verify linked versus detached child cancellation behavior.
- **Queue outcome:** test both worker success and typed failure reaching the waiting workflow, separately from delivery redelivery/dead-letter behavior. `DurableQueue.test.ts` covers the former contract.

Use storage assertions only when persistence, deduplication, or lost-wake recovery is the subject. Prefer observed state transitions to fixed yield counts; execution-ID hashing and storage callbacks can involve real asynchronous boundaries even under a logical clock.

Source anchors (Effect v4): `packages/effect/src/workflow/Workflow.ts` (`execute`, `intoResult`, `addFinalizer`, failure annotations); `WorkflowEngine.ts` (`makeUnsafe`, `layerMemory`); `WorkflowProxy.ts` and `WorkflowProxyServer.ts`; `packages/effect/src/cluster/ClusterWorkflowEngine.ts`. Behavioral examples are in `packages/effect/test/workflow/WorkflowEngine.test.ts`, `DurableQueue.test.ts`, and `packages/effect/test/cluster/ClusterWorkflowEngine.test.ts`.
