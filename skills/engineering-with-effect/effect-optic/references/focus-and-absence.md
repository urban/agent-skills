# Focus and absence

Choose focus from shape:

- always-present field: required key focus
- optional field: decide whether undefined preserves or deletes the key
- record key/array index: absence-aware focus
- union variant: narrow by tag/refinement first
- validated subset: check/refine focus

Plain replace/modify intentionally returns the original source when an optional focus is absent. Use result-returning read/update when absence must become a domain decision or error.

Name the transition rather than exposing a long path. This centralizes path semantics and lets tests cover present, absent, wrong variant, and failed refinement behavior.
