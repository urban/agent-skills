# Run a bounded experiment

## Entry conditions

Use when a specific uncertainty about architecture, UX, integration, or feasibility could change a decision and existing evidence is insufficient. A feature backlog is not an experiment question. Recover the decision, relevant prior art, authorization, effort boundary, safe location, and any consumer artifacts.

Adapted from the standalone `prototyping` skill: evidence is the product; fidelity, evaluation criteria, observation, interpretation, and production adoption remain separate.

## Procedure

1. **Frame the uncertainty.** Name the question/hypothesis and which decisions it informs. Check whether inspection, prior findings, or targeted research can answer it without building. Separate unrelated questions instead of creating a large demo.
2. **Bound the experiment before execution.** Establish method, fidelity/shortcuts, observations that would support/reject/leave the idea unresolved, effort/time limit, environment, side effects/cost, and evidence to retain. Recover covered limits from the request and context; do not add confirmation for routine choices already authorized. Resolve missing high-impact limits before dependent execution. External user research, production data, service spending, or deployment need authorization covering those actions.
3. **Build only the mechanism needed.** Use an isolated scratch or agreed experiment location and existing tooling where adequate. Keep the disputed mechanism real: mocking away the boundary under investigation cannot test it. Record versions, fixtures, configuration, and assumptions that affect interpretation. Label simulations and agent-generated feedback.
4. **Observe against the stated criteria.** Record conditions, actual results, unexpected behavior, and failed/incomplete attempts. Stop when the question is answered or the effort boundary is reached. An inconclusive result is valid; do not polish indefinitely or choose criteria afterward to favor a result.
5. **Preserve reusable findings.** Use a proportionate standalone local record or existing experiment record: question/scope; method/fidelity/criteria; observations; interpretation/limits; decision implications; retained artifacts/reproduction. Separate measured results from hypotheses and untested claims. Retain the minimum inspectable code, fixtures, screenshots, interaction notes, or measurements needed. Clean up only owned disposable resources without destroying evidence.

## Completion criteria

The bounded question has an evidence-backed answer or an explicit inconclusive outcome. Findings identify authorization/scope, criteria, actual observations, limitations, dependent decisions, and inspectable/reproducible support. Mocked interaction is not implemented capability; a demonstration establishes no general correctness, scalability, usability, security, or reliability claim.

## Conditional transitions

- Return findings to the owning design, spec, or ADR; link or update consumer documents only within authorization. Evidence may change a recommendation without accepting that choice.
- Route unresolved design tradeoffs to [brainstorming](brainstorming.md), specs to `to-spec`, engineering decisions to `write-adr`, and UI refinement to `interface-first` when relevant. For that call, use [skill routing](../references/skill-routing.md), supply the experiment question/findings, actual UI sources and authorization, then consume its operable comparison, decision state and evidence/limits before resuming the experiment conclusion or owning decision.
- A further experiment must remain within the authorized question/effort boundary or receive the additional decision it needs.
- Production implementation or reuse of prototype code requires authorization and a separate assessment of correctness, security, maintainability, and delivery. Existing authorization may cover that next stage; prototype success alone does not.
