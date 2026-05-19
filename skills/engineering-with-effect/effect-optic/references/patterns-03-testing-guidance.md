# Effect `Optic` patterns for agents — part 3

Covers:

- Testing guidance
- What to avoid

---

## Testing guidance

- Test the public behavior: `get`, `getResult`, `replaceResult`, `replace`, `modify`, or `modifyAll` outputs.
- Include absent-focus cases whenever using `.at`, `.tag`, `.check`, `.refine`, `.some`, `.success`, or `.failure`.
- Include optional deletion/preservation cases when using `.optionalKey` or optional `.key`.
- For important immutable-update behavior, assert changed branches and reused unrelated branches. Do not depend on no-op reference identity.
- For service tests, verify typed error mapping at the service boundary; do not test Effect internals or the Optic implementation itself.

## What to avoid

- Do not mutate source objects, arrays, maps, or class instances in a modifier.
- Do not inline long optic chains at every call site. Name them or wrap them in domain transition functions.
- Do not use `.key(...)` for dynamic record keys or array indexes that may be absent. Use `.at(...)` when absence matters.
- Do not call `.key(...)`, `.optionalKey(...)`, `.pick(...)`, `.omit(...)`, or `.at(...)` on unions. Narrow with `.tag(...)` or `.refine(...)` first.
- Do not rely on `replace` / `modify` to report failures. They intentionally return the original value on optional focus failure.
- Do not leak `Result.Failure<string>` messages as service error contracts. Map them to specific tagged errors.
- Do not use optics as service dependencies. Services expose capabilities; optics are pure implementation helpers.
- Do not use direct path optics on schema classes or other custom prototypes. Use `Schema.toIso`, `Newtype.makeIso`, or `Optic.makeIso`.
- Do not use `Optic.makeIso` unless the conversion is genuinely lossless in both directions.
- Do not use `Optic` for one-off shallow updates where a simple object spread is clearer.
