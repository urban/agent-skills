# Draw semantic boundaries

**Apply when:** naming UI units, assigning behavioral authority, extracting reuse, or choosing package placement.

Separate a coherent responsibility when semantic inputs, actions, outputs and lifetime ownership improve understanding or steering. Keep private protocols behind that boundary. Judge generic meaning and behavior against unrelated product data before promoting a control into foundational UI.

Use the [decomposition rubric](../references/decomposition-rubric.md) for the actual boundary and placement decision. A named renderable element's local module is distinct from its public package export; a state is not another component.

**Example:** generic focus and toggle semantics may belong in UI; a product assignment draft belongs in its product interaction, and authoritative acceptance remains with the domain/service owner.

**Tradeoff:** line count, visual depth and repeated appearance alone do not justify extraction. Keep coordinated behavior together when splitting would expose private event sequences or add more plumbing than clarity.
