# Observability

Start from the operator question: which latency, failure, resource, or delivery boundary must be explained? Instrument the operation that owns that behavior rather than every helper. Name spans, metrics, and stable attributes as an operator-facing contract.

Choose causal relationships deliberately. Work completing for a request and independent work triggered by it need different trace relationships and completion owners. The instrumentation must cover execution and consumption of deferred work, not just its construction.

Keep instrumentation transparent to business outcomes unless observability administration is the feature. Decide whether telemetry is best-effort diagnostics or durable audit evidence. A tolerated exporter outage is reasonable for the former; the latter needs an explicit storage and failure contract.

Select attributes from bounded operational categories. Treat automatically recorded failures and provider metadata as potential disclosures too; configuration redaction alone does not determine what diagnostics may safely contain. Avoid duplicating one failure across logs and spans without adding an operator action or useful context.

**Tradeoff:** more detail can increase cost, exposure, and noise without improving diagnosis. Verify the relationships and business behavior the instrumentation claims to preserve; obtain exporter setup and propagation APIs from Effect's current sources.
