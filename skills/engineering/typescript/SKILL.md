---
name: typescript
description: Write TypeScript in a pragmatic functional style with expression-oriented code, strong inference, explicit domain types, immutable defaults, manual currying where useful, and no `any`, `null`, or exception-driven expected failures. Use when working on any TypeScript coding task.
---

## Rules

- Write TypeScript as functional, declarative code by default because readers should see the data transformation and domain intent without mentally executing step-by-step mutation.
- Keep the core pure and push effects, mutation, I/O, time, randomness, and framework boundaries to the edges.
- Prefer expressions over statements because expressions produce values, compose naturally, and make data flow easier to follow.
- Prefer `const fn = (...) => ...` for almost all functions, including exports, because it keeps function values consistent with partial application and composition.
- Annotate exported/public function return types as API contracts; let internal helper return types be inferred unless inference becomes unclear or recursive.
- Prefer compiler inference over redundant annotations for initialized variables and private helpers.
- Prefer immutable data and non-mutating updates; local mutation is allowed only when fully encapsulated inside an otherwise pure function.
- Prefer native TypeScript/JavaScript collection methods such as `.map`, `.filter`, `.reduce`, `.flatMap`, `.find`, `.some`, `.every`, `.toSorted`, and `.toReversed` before adding helper wrappers.
- Use manual currying and partial application when it creates reusable, readable functions; keep data arguments last for curried helpers.
- Model domain states, variants, absence, and expected failures explicitly with TypeScript types, especially discriminated unions, branded types, generics, and `satisfies`.
- Use advanced types pragmatically: make illegal states unrepresentable, but do not turn the type system into a puzzle.
- Prefer self-documenting names and types; comments should explain non-obvious rationale, constraints, or edge cases, not restate syntax.
- Short generic names such as `x` and `xs` are acceptable in small generic functions when context makes singular versus collection obvious.

## Constraints

- Do not introduce `any`; use `unknown`, generics, type guards, assertions at verified boundaries, or better domain types instead.
- Do not introduce `null`; use `undefined`, optional properties, or discriminated unions for absence.
- Do not introduce thrown exceptions for expected/domain/control-flow failures; return explicit typed results instead.
- Do not introduce external functional libraries, helper libraries, or library-specific conventions as part of this skill.
- Do not add speculative abstractions, reusable helpers, configuration, or wrappers that are not justified by the current task.
- Do not add validation commands or testing workflow requirements solely because this skill was used.
- Do not include classes or inheritance guidance in this skill; match the existing project when those constructs are already present.

## Gotchas

- If you wrap every native array operation in local FP helpers, the code starts serving a style guide instead of the problem. Use `.map`, `.filter`, `.reduce`, and friends directly until a curried helper removes real repetition or improves a call site.
- If you annotate every helper return type, refactors become noisy and brittle because implementation details are copied into signatures. Annotate public exports as contracts and let private helpers infer unless recursion or unclear unions require help.
- If you use `throw` for expected validation or domain failures, callers lose the failure mode in the type and agents later forget to handle it. Return a discriminated union that names the failure instead.
- If you reach for `any` to make TypeScript stop complaining, you erase the exact safety this style depends on and downstream code becomes untyped by infection. Use `unknown` plus narrowing or improve the generic constraint.
- If you introduce `null` for absence, every caller inherits a second absence vocabulary and must remember extra checks. Use optional fields, `undefined`, or an explicit union variant instead.
- If you force pointfree style, currying, or advanced conditional types past the point of readability, the next edit becomes slower and riskier. Prefer a named intermediate, pointed callback, or simpler type when it communicates intent better.
- If mutation leaks across a function boundary, readers must track temporal state and aliasing to understand correctness. Keep mutation local, hidden, and returned as an immutable result.
- If statement-heavy code grows around temporary variables and control flags, the real value being produced gets buried under sequencing. Prefer expressions and named transformations that return the value directly.
- If an exported `const` function relies on inferred return type, accidental implementation changes can silently change the public API. Add the return type at the boundary even when inference is obvious.

## References

- [`references/functional-style.md`](./references/functional-style.md): Read when: deciding how to structure expression-oriented transformations, immutability, native collection methods, local mutation, currying, or partial application.
- [`references/type-system.md`](./references/type-system.md): Read when: choosing inference versus annotations, designing generics, discriminated unions, branded types, `satisfies`, or avoiding unreadable type-level programming.
- [`references/failures-and-absence.md`](./references/failures-and-absence.md): Read when: modeling absence, validation, expected failures, boundary errors, or replacing `null`, `throw`, and `any`.
