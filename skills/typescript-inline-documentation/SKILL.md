---
name: typescript-inline-documentation
description: Create and review high-value inline documentation for TypeScript codebases using JSDoc-first patterns and optional TypeDoc output. Use when a user asks for code documentation, JSDoc updates, API docs, documentation standards, or inline doc quality improvements.
---

## Rules

- Document caller-facing behavior, rationale, and constraints instead of narrating obvious implementation.
- Prioritize exported APIs unless the user explicitly requests internal coverage.
- Keep JSDoc synchronized with code changes in the same edit.
- Use `@remarks` for non-obvious design constraints, caveats, and integration details.
- Keep parameter and return descriptions specific when code alone does not communicate defaults, nullability, side effects, or ordering.
- Add `@example` only when usage is non-trivial and the example improves adoption.
- Use links such as `@see` and `{@link ...}` when they reduce repetition and help navigation.
- Mark missing behavior details as `TODO: Confirm` instead of inventing guarantees.

## Constraints

- Do not duplicate TypeScript type information that is already clear from the signature.
- Do not add comments that only restate names such as “Gets user” or “Returns result.”
- Do not invent defaults, error behavior, lifecycle guarantees, or performance claims not supported by code or tests.
- Do not change runtime behavior just to make documentation easier.
- Do not turn source comments into long tutorials; keep inline docs concise and reference-oriented.
- Do not report the task as complete if significant requested symbols were intentionally deferred without saying so.

## Requirements

Inputs:

- target files, modules, or symbols
- expected documentation scope such as public-only or broader coverage
- repository validation commands, at minimum lint and typecheck
- tests when doc changes accompany behavior edits

Outputs:

- updated TypeScript source with inline JSDoc aligned to repo standards
- explicit list of deferred symbols and `TODO: Confirm` items

In scope:

- JSDoc authoring and cleanup
- documentation consistency across TypeScript sources
- optional TypeDoc-oriented improvements when requested

Out of scope:

- prose-only documentation sites with no inline source updates
- speculative API documentation for behavior not present in code
- large tutorial content embedded in source files

Failure modes to prevent:

- hallucinated guarantees or error semantics
- comments that duplicate type signatures or symbol names
- bulk doc edits that drift from repo lint or doc conventions
- incomplete reporting of updated versus deferred coverage

TODO: Confirm

- expected coverage threshold for this task
- whether legacy undocumented areas block completion or should be tracked separately
- whether TypeDoc output is required now or deferred

## Workflow

1. Confirm the request is for inline TypeScript documentation and capture the scope boundary.
2. Inspect repository conventions such as existing JSDoc style, lint rules, and TypeDoc config when relevant.
3. Prioritize documentation targets by external impact: exports first, then requested internals.
4. Update inline docs with behavior-focused descriptions, useful tags, and explicit uncertainty where needed.
5. Validate with lint first, then typecheck, and run tests when the documentation changed alongside behavior.
6. If TypeDoc is in scope, generate or verify output and check for navigation or rendering issues.
7. Hand off a concise summary of updated symbols, deferred symbols, validation results, and remaining `TODO: Confirm` items.

## Gotchas

- If you document every line instead of the contract, the file gets louder while the real behavior stays unclear. Spend words on what callers need to know, not what the syntax already shows.
- If you copy type information into prose, signatures and comments drift separately and future edits make one of them false. Let TypeScript carry the type shape unless the prose adds behavior or constraint.
- If you invent a default, guarantee, or thrown error because it seems likely, downstream users treat the comment as API truth and code against behavior that does not exist. Only document what the code, tests, or explicit requirements support.
- If you skip repo convention review, otherwise good JSDoc changes fail lint or clash with existing patterns and create cleanup work for maintainers. Inspect local style before large doc edits.
- If `@example` blocks are unrealistic or stale, readers cargo-cult broken usage and trust the docs less. Add examples only when they are short, representative, and worth keeping current.
- If you do broad documentation cleanup without tracking deferred symbols, the handoff sounds complete while important gaps remain invisible. Report what changed and what was intentionally left out.

## Deliverables

- updated TypeScript source with inline JSDoc aligned to repository standards
- a concise handoff listing updated symbols, deferred symbols, validation results, and `TODO: Confirm` items

## References

- [`references/why-over-what.md`](./references/why-over-what.md): Read when: a draft comment explains mechanics but still misses caller-facing value or constraints.
- [`references/file-preamble.md`](./references/file-preamble.md): Read when: deciding whether a file or module needs a top-level explanatory block.
- [`references/function-documentation.md`](./references/function-documentation.md): Read when: documenting functions, overloads, generics, async behavior, or return contracts.
- [`references/type-shape-documentation.md`](./references/type-shape-documentation.md): Read when: documenting interfaces, type aliases, or object-shape contracts.
- [`references/class-documentation.md`](./references/class-documentation.md): Read when: documenting classes, constructors, methods, or lifecycle expectations.
- [`references/react-component-documentation.md`](./references/react-component-documentation.md): Read when: documenting React components and props contracts.
- [`references/remarks-patterns.md`](./references/remarks-patterns.md): Read when: deciding whether extra nuance belongs in `@remarks`.
- [`references/decorator-escaping.md`](./references/decorator-escaping.md): Read when: mentioning decorators safely in prose or examples.
- [`references/anti-pattern-examples.md`](./references/anti-pattern-examples.md): Read when: reviewing weak documentation and needing concrete examples of what to avoid.

## Validation Checklist

- scope boundary is explicit
- public API is prioritized unless the user requested otherwise
- comments focus on behavior, rationale, and constraints
- duplicated type noise was avoided
- invented guarantees or defaults were not introduced
- deferred symbols and high-impact unknowns are reported explicitly
- references include explicit `Read when:` triggers
