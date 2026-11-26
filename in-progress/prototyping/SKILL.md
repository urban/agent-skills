---
name: prototyping
description: Run a bounded experiment to investigate architecture, UX, feasibility, or another uncertain idea and preserve reusable findings. Use when a prototype or technical/interaction spike can inform a specification, ADR, design document, or engineering decision.
---

## Rules

- Start from a decision-relevant question rather than a feature backlog, because the prototype's product is evidence, not production capability.
- Choose the smallest credible experiment that could change the decision; reuse adequate prior art or research instead of building by reflex.
- Agree on what observations would support, reject, or leave the idea unresolved before interpreting the result.
- Make fidelity explicit: a simulated interface, local fixture, or mocked capability can answer some questions but not others.
- Preserve observations, interpretation, limitations, and reproducible artifacts separately so findings can inform multiple documents.
- Treat prototype code as disposable unless its promotion is separately reviewed and authorized.

## Constraints

- Do not start experiment execution without authorization for its scope, environment, side effects, and relevant cost.
- Do not access production data, spend on services, deploy, or conduct external user research without specific authorization.
- Do not silently expand a spike into implementation, a new framework, an exhaustive benchmark, or production infrastructure.
- Do not claim a demonstration proves correctness, scalability, usability, security, or reliability outside the conditions actually examined.
- Do not present agent-generated feedback as human usability research or a mocked interaction as an implemented capability.
- Do not mark a spec decision or ADR accepted based solely on prototype success.
- Do not delete unrelated work or let cleanup destroy the evidence needed to interpret the result.

## Requirements

- A question, hypothesis, or set of tightly related assumptions that could affect a decision.
- Context and existing evidence, including research/prior art where available.
- Authorization, an agreed effort/time boundary, a safe experiment location, and any required access. Confirm unresolved high-impact limits before running.
- An intended findings destination and relevant consumer documents, if known. A prototype need not serve a specification specifically.

In scope: architectural feasibility, integration behavior, UX/interaction exploration, technical constraints, and other bounded idea validation.

Out of scope: production implementation, unbounded research, automatic adoption of prototype code, and approval of downstream decisions.

## Workflow

1. **Frame the uncertainty.** Identify the question, decisions it informs, current evidence, and why more observation is needed. Check whether repository inspection or prior-art research can already answer it. Narrow unrelated questions into separate experiments rather than building one large demo.
2. **Agree on the experiment.** Present a compact proposal: question/hypothesis, method, fidelity and important shortcuts, observations/evaluation criteria, effort limit, environment/side effects, and artifacts to retain. Confirm authorization or reuse an explicit request that covers these boundaries. An inconclusive result is valid; do not choose criteria merely to guarantee success.
3. **Build or arrange only what answers it.** Use an isolated scratch location or agreed experiment directory. Keep the mechanism minimal; document versions, fixtures, configuration, and assumptions that materially affect interpretation. Existing project tooling is preferable to a new harness unless the harness is itself under investigation.
4. **Run and observe.** Record the conditions, actual results, unexpected behavior, and failed or incomplete attempts. Compare against the agreed criteria. Stop at the agreed effort boundary or ask before expanding scope; do not keep polishing until the preferred approach looks convincing.
5. **Produce reusable findings.** Start from [`assets/findings-template.md`](./assets/findings-template.md) and scale it to the experiment. Separate observations from interpretation, state what remains untested, and identify implications for each dependent decision. Retain enough artifacts or reproduction steps to make the result inspectable; a UX prototype may need screenshots or interaction notes rather than a code-heavy report.
6. **Return evidence, not authority.** Link findings from authorized consumer documents, or report the links for their authors to incorporate. Suggest possible spec/ADR changes as proposals, not accepted commitments. Report retained/discarded artifacts and clean up only owned temporary resources. Production adoption, further experiments, or changed decisions require their own authorization.

## Gotchas

- If a prototype starts from a feature list, the agent ships a partial product without resolving the actual uncertainty. Tie each activity to the question and stop when enough evidence exists.
- If acceptance criteria are chosen after observing results, a weak approach can always look successful. State evaluation criteria first and report inconclusive outcomes honestly.
- If an architecture experiment replaces the disputed boundary with a mock, it demonstrates the assumption instead of testing it. Preserve the mechanism whose behavior is uncertain.
- If a polished screen is called validated UX, visual plausibility becomes evidence of user success. Distinguish interaction demonstration, expert judgment, and observed human behavior.
- If a happy-path run becomes a reliability claim, unexamined failures disappear from the decision. Bound the conclusion to the actual conditions and record missing evidence.
- If a prototype is automatically promoted, shortcuts become production constraints. Require a separate review of correctness, security, maintainability, and delivery before reuse.
- If cleanup deletes scripts, fixtures, or result context, future agents cannot audit the conclusion. Retain the minimum reproducible evidence and remove only owned disposable artifacts.
- If findings are buried in one spec's prose, other decisions cannot reuse them. Preserve a standalone findings record and link consumers to it.

## Deliverables

- A bounded experiment with recorded authorization/scope, evaluation criteria, actual observations, and remaining uncertainty.
- A proportionate findings artifact with source/environment context, interpretation, limitations, decision implications, and inspectable supporting artifacts or reproduction steps.
- A clear report of affected spec/ADR/design questions and suggested next actions, without claiming decision approval or production readiness.
