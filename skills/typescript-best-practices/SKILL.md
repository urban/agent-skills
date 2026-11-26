---
name: typescript-best-practices
description: Apply personal TypeScript preferences for functional code, precise inference, domain modeling, and explicit failures. Use when writing, refactoring, or reviewing .ts or .tsx files.
---

## Rules

- Use project, framework, and library guidance for overlapping decisions; apply these defaults elsewhere.
- Prefer pure functions and expressions. Keep I/O, time, randomness, and other effects at boundaries; allow mutation only when encapsulated inside an otherwise pure function.
- Prefer `const fn = (...) => ...`, immutable data, and native collection methods. Curry manually only when partial application improves a call site; put data last.
- Infer initialized values and private helpers. Annotate public returns for intentional abstractions, API stability, or unclear diagnostics; preserve precise builder and factory inference.
- Model meaningful states with discriminated unions and domain identities with brands. Use generics to preserve relationships; keep type-level machinery simpler than the problem.
- Extract helpers that own a coherent transformation, boundary, invariant, or policy. Name them for that responsibility.
- Inline trivial factories; use lazy callbacks only when required by the API or evaluation semantics.
- Prefer names and types that explain intent; comments explain non-obvious rationale or constraints.

## Constraints

- Do not introduce `any` or non-null assertions; narrow `unknown`, branch on absence, or improve the generic constraint. Other than `as const`, assertions require a verified boundary invariant.
- Do not introduce domain `null`; use `undefined`, optional fields, or explicit variants. Adapt external `null` at boundaries.
- Return typed results for expected failures; adapt throwing APIs at boundaries rather than using exceptions for domain control flow.
- Use ordinary named parameters for fixed-arity APIs; reserve rest parameters for genuinely variadic calls.
- Do not add libraries, speculative abstractions, configuration changes, or testing workflows merely to enforce this style.

## Knowledge Boundaries

Applies to TypeScript implementation and domain types. Use the task's domain invariants and existing API contracts to choose representations. Project setup, application architecture, and testing strategy remain outside this skill.

## Patterns

| Decision | Default |
| --- | --- |
| Variants | Put each state's required fields in its own discriminated member; handle variants exhaustively. |
| Shape checks | Use `satisfies` to check compatibility while retaining useful inference. |
| External data | Validate `unknown` once into a domain type; establish invariants before branding. |
| Absence | Use optional fields for simple absence; use a union when the reason changes caller behavior. |

## Gotchas

- Wrapping every array method hides familiar operations behind indirection. Use native methods until a helper owns meaningful logic.
- Repeating inferred public types can widen literals, brands, or builder contracts. Annotate the intended abstraction, not a copy of implementation details.
- A cast or type predicate can claim validation without performing it. Verify every promised invariant before trusting the domain type.
- Forced currying, pointfree chains, and nested ternaries obscure intent. Use named intermediates, direct callbacks, or clear branches.
- Local mutation stops being pure when it changes caller-owned objects or aliases. Allocate owned state and keep mutation unobservable outside the function.
