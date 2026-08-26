# Instrumentation semantics

Instrument service operations, handlers, commands, durable steps, stream lifetimes, startup phases, and resource acquisition when they answer an operator question.

Keep wrappers transparent: record timing/outcome, then return the original value or re-fail with the original cause. For streams, attach observation to consumption exit rather than construction.

## Naming and attributes

Use stable domain-first names such as `billing.invoice.create` or `workflow.assessment.start`. Keep metrics labels bounded: operation, outcome, provider class, phase, or transport. Review identifiers and all free text for privacy and retention even on spans.

Avoid duplicate error logs when span status/cause and attributes already provide the evidence. Log when there is an operator action, audit event, or contextual event not represented by the span.
