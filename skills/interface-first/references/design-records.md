# Design ownership and decision records

Use the project's existing accepted layout and numbering. Unless it establishes another convention, keep root `DESIGN.md` as the UI map, approved artifacts under the implementing owner’s `docs/design/`, scoped ADRs under that owner’s `docs/adr/`, and global decisions under root `docs/adr/`. The map links the authorities; it does not replace them. Resolve paths through [project bindings](project-bindings.md).

## Design ownership and decision records

- **Approved designs:** retain editable/operable targets, relevant captures, behavior contracts and exact approval provenance with their implementing owner, organized by named composition or flow. Cross-owner compositions have one primary owner and link participants. Keep proposals visibly distinct from accepted artifacts; do not copy a current authority into multiple owners.
- **Decision scope:** record consequential design rationale that cannot be discovered from code in the owning ADR. Global decisions belong at project scope. Cross-reference related records rather than copying the same decision locally and globally. Code-discoverable paths and implementation constants do not need an ADR per property.
- **Decision content:** follow existing style, or use a concise numbered record with title, status, date, owner/scope, context, decision, supported rationale/tradeoffs/consequences, and approval/evidence/design links. Record considered alternatives only when supported. Preserve known rationale without inventing historical motives.
- **Lifecycle:** distinguish proposed, accepted, rejected and superseded decisions; link the superseding record and preserve meaningful history. A written record does not itself grant approval. Approval remains valid within its actual scope without another ceremony. Design approval, implementation completion and product acceptance remain separate.
- **Migration:** when an authorized UI foundation must reconcile scattered authorities, move them to the implementing owners, preserve evidence/history, repair incoming links, relative assets, preview references and executable path consumers, then remove superseded indexes. No alternate inventory authority or redirect is required.
- **Discovery:** update the affected design-map names, ownership, source/review/state/target links and decision links. Plans, reviews and tasks point to those same records. Missing historical rationale does not prevent a complete usable map.

## Where outputs belong

The calling workflow keeps its plan, tasks and progress in their existing owners; UI checks link owning evidence receipts. Qualifying accepted rationale belongs in ADRs, never only in a ticket, chat or review log. A new review may use `<owner>/docs/design/<flow>/reviews/<review-id>/`, but an existing equivalent or one small file is sufficient. Preserve historical evidence without requiring a full archive rebuild.

Follow the [review contract](review-contract.md) to identify versions and feedback. In a design session, maintain the affected owning target, decision and map links as scoped approval is recorded. If the assignment cannot reconcile a stale record, return the exact gap and required ordering to the caller before dependent implementation; do not claim it is already updated. Preserving already accepted decisions needs no second approval. Keep proposed work, implementation gaps, simulations and final acceptance limits visible without turning the map into a run log.
