# Match evidence to the claimed contract

**Apply when:** selecting test boundaries, substitutes, or evidence for an Effect-specific guarantee.

Exercise the closest public composition that can expose a meaningful mistake in the claim. Replace external uncertainty while preserving relevant boundary semantics. Increase fidelity when the claim is about behavior owned beyond the substitute.

**Example:** a domain fake can demonstrate payment-decline handling. It cannot establish provider deduplication, transport cancellation, or recovery after a process restart.

**Tradeoff:** a larger environment can introduce noise without improving evidence; an oversimplified fake can remove the very invariant under test. Choose the boundary by the guarantee and state what remains unproven.
