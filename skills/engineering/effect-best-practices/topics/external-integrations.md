# External integrations

Let one adapter own a remote protocol or SDK boundary: configuration, authentication, response interpretation, cancellation obligations, and retry authority. Domain services expose the behavior callers need. Keep provider types out of that surface unless provider passthrough is itself the product.

Use the available Effect integration when it fits the required semantics. A custom wrapper should fill a named capability gap. Exposing a generic client callback can be reasonable for an impractically large surface, but treat the resulting coupling as an explicit contract, not a default service design.

For a first-party HTTP API, keep one shareable contract authoritative for peers. For an external protocol, preserve transport, status, and decoding distinctions only where they change caller action. Do not apply a fallback for absence to permission failures, malformed data, or other failures it does not actually resolve.

Choose one retry authority for each boundary and account for retries already performed by the SDK or transport. Bound repetition by the operation's safety and deadline. When a mutation has an uncertain outcome, reconcile or deduplicate; timeout and cancellation are not business rollback.

Resource release stays with the owner. An adapter borrowing an externally managed client must not close it. Portability is a supported behavior contract across chosen runtimes, not merely use of a portable interface.

**Tradeoff:** low-level platform helpers can intentionally expose capabilities; domain operations normally capture them. Keep protocol tests separate from domain tests when their claims require different substitutes.
