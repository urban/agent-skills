Use this contract when resolving the stable `<artifact-name>` for a design artifact.
Keep the name deterministic across discovery, approval, and later revisions.

## Resolution order

Resolve `<artifact-name>` in this order:

1. Explicit user-provided artifact name or slug.
2. Existing related artifact basename when continuing or revising prior work.
3. A concise title derived from the approved problem statement.

## Normalization rules

- Convert to lowercase kebab-case.
- Convert spaces and underscores to hyphens.
- Remove unsupported punctuation.
- Collapse consecutive hyphens to one.
- Trim leading and trailing hyphens.
- Preserve semantic tokens that disambiguate the artifact, such as `checkout-flow` or `api-rate-limits`.

## Design artifact filename

Compose the final filename as:

`docs/ideas/<artifact-name>-design.md`

- Reuse the same `<artifact-name>` for every revision of the same design artifact.
- Do not silently rename an existing artifact once it has been shared, linked, or reviewed.
- If the user changes the requested destination or suffix explicitly, preserve the normalized basename and only adjust the requested path or suffix.

## Gotchas

- If you derive a fresh name after discovery has already started, notes and follow-up work split across multiple filenames.
- If you ignore an existing artifact basename during a revision, linked docs drift and future edits target the wrong file.
- If you normalize too aggressively and remove meaningful words, nearby designs become hard to distinguish.
- If you preserve user wording without normalization, filenames become inconsistent and harder to reuse in later automation.
