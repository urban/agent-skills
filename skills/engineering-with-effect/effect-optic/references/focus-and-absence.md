# Focus and absence

## Presence is a domain choice

A missing property, an own property containing `undefined`, and a failed focus are different states:

- `.key(key)` reads the property directly. For an optional field, absence can be a successful read of `undefined`; writing `undefined` creates/preserves an own property.
- `.optionalKey(key)` also reads absence as `undefined`, but writing `undefined` deletes the property or splices an array index. Writing a defined value can insert it.
- `.at(key)` requires an own property for both read and replacement. It cannot insert a missing key. An own property containing `undefined` still counts as present.
- `.notUndefined()` rejects an undefined focus on read; it does not distinguish a missing property from an explicit undefined value.

Choose based on the domain operation, not just on whether the field's declaration contains `?`.

```ts
import { Optic, Result } from "effect"

type Preferences = { readonly nickname?: string | undefined }
const storedNickname = Optic.id<Preferences>().key("nickname")
const removableNickname = Optic.id<Preferences>().optionalKey("nickname")
const existingNickname = Optic.id<Preferences>().at("nickname")

storedNickname.replace(undefined, {}) // { nickname: undefined }
removableNickname.replace(undefined, { nickname: "Ada" }) // {}
removableNickname.replace("Ada", {}) // { nickname: "Ada" }
Result.isFailure(existingNickname.replaceResult("Ada", {})) // true
Result.isSuccess(existingNickname.getResult({ nickname: undefined })) // true
```

Name the domain transition rather than exporting a long path with unspecified failure semantics. For update-only-if-present, `.at` makes missing data actionable through `replaceResult`; plain `.replace` returns the original source on that reported failure. Failed reads or writes in `.modify` also leave the source unchanged. Modifier exceptions and unsupported representation errors are not caught by this fallback.

## Conditional update versus construction

A Prism has a fallible read but a source-free setter. `.set` and `.replace` construct a whole value from the new focus; they need not read or match the old source. `.modify` reads first, so it is conditional.

```ts
import { Optic, Option } from "effect"

const present = Optic.some<number>()
present.replace(2, Option.none()) // Option.some(2)
present.modify((n) => n + 1)(Option.none()) // Option.none()

type Job =
  | { readonly _tag: "Queued"; readonly attempts: number }
  | { readonly _tag: "Done"; readonly receipt: string }

const queuedAttempts = Optic.id<Job>().tag("Queued").key("attempts")
// Composing variant selection with a field lens needs the source to rebuild it.
// A Done job cannot be focused by this Optional.
queuedAttempts.modify((n) => n + 1)({ _tag: "Done", receipt: "r1" })
// { _tag: "Done", receipt: "r1" }
```

Use a construction operation for changing variants intentionally, and a conditional focus for editing one variant in place. Do not assume every optic with a fallible read rejects replacement of a nonmatching source.

## Checks select the old focus

`.check`, `.refine`, and `.tag` select what can be read; they are not general validation of proposed writes. A check Prism's setter is identity. In a source-dependent composition, checks can reject the old focus before rebuilding it, but they do not recheck the new value:

```ts
import { Optic, Schema } from "effect"

const positiveBalance = Optic.id<{ readonly balance: number }>()
  .key("balance")
  .check(Schema.isGreaterThan(0))

positiveBalance.modify((n) => n - 2)({ balance: 1 }) // { balance: -1 }
positiveBalance.modify((n) => n + 2)({ balance: 0 }) // { balance: 0 }
```

If nonnegative balance is a domain invariant, validate the proposed transition explicitly rather than treating focus selection as an invariant-preserving write guard. Keep expected failures explicit outside the pure modifier, or use a custom Optional whose setter returns a structured issue.

`getResult` and `replaceResult` failures contain `SchemaIssue.Issue`, not strings. Missing `.at` keys produce a `Pointer` containing `MissingKey`. Interpret the operation in its domain context (for example, missing job versus invalid job state); format issues for diagnostics rather than matching formatter text to implement business logic.
