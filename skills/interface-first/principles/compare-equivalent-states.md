# Compare equivalent states

**Apply when:** choosing between proposals or checking changed UI against a baseline or accepted target.

Hold relevant content, fixture, viewport, starting state, scroll and timing constant so the intended delta is visible. Preserve a reconstructable source for each version. Present both in one review experience and make corresponding paths operable when behavior matters.

**Example:** compare a notification in the same populated reader with the same scroll anchor, then reset both versions before checking dismissal and focus return.

**Tradeoff:** exact equivalence may be impossible when the new behavior changes a state. Explain the mismatch and show the closest meaningful comparison. Static captures can resolve a visual choice; they cannot establish timing or recovery behavior.
