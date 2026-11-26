# Lifetime and isolation

Assign resources to the narrowest correct sharing domain: host infrastructure, configured tenant capability, invocation, subscription, or transaction. Choose acquisition identity separately from release ownership. Use the installed Layer and Scope semantics to implement that choice rather than assuming that a nested provision boundary creates isolation.

Capture stable dependencies where their identity belongs. Keep current user, transaction, or other invocation-specific authority explicit or deliberately invocation-local. A long-lived service must not freeze that authority into its constructor. Transaction-current views normally remain callback-scoped values unless the transaction protocol intentionally requires contextual propagation.

Activate infrastructure only on execution paths that need it. Handler-only resources generally belong around the selected invocation; parsing or dispatch resources may need an earlier owner. Help and parse-failure paths should not acquire unrelated infrastructure by accident.

Resolve configuration precedence deliberately. An explicit invocation override should not evaluate an unused fallback that can fail unless independent validation of that fallback is itself required.

For concurrent work, define both a lifetime owner and what failure means. Request work, subscription work, and a host worker have different shutdown obligations. Detachment requires an actual supervisor and observation policy, not merely an intent to finish later.

**Tradeoff:** rebuilding a graph per public call prevents useful sharing; sharing a graph across identity boundaries can retain the wrong authority. Configure reuse around the complete owning operation and isolate only state that must differ.
