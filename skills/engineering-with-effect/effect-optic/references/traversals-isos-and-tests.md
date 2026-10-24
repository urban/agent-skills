# Traversals, isos, and tests

## Selection is not collection resizing

A Traversal focuses a `ReadonlyArray` of selected values. `.forEach` applies an inner optic to each source element and skips elements whose inner read fails. This is useful for intentional filtering; it can hide data errors if every element was required to match.

```ts
import { Optic, Schema } from "effect"

type Cart = { readonly quantities: ReadonlyArray<number> }
const positiveQuantities = Optic.id<Cart>()
  .key("quantities")
  .forEach((quantity) => quantity.check(Schema.isGreaterThan(0)))

const increment = positiveQuantities.modifyAll((n) => n + 1)
increment({ quantities: [1, 0, 3] }) // { quantities: [2, 0, 4] }
```

`.modifyAll` transforms each selected element; `.modify` transforms the collected array as one value. For a `.forEach` traversal, replacement must contain exactly as many values as the source currently selects, and writes them back to those positions in order. Filtering the collected array to delete elements fails with a replacement-count issue; resizing belongs on the underlying collection instead. For records, `Optic.entries<A>().forEach(...)` exposes entries for selection and value updates.

An inner setter failure aborts the traversal replacement and is wrapped with a `SchemaIssue.Pointer` at the source element index. `replaceResult` exposes this; `.replace`, `.modify`, and `.modifyAll` return the original source on reported failure rather than a partially updated result. This relies on pure inner setters, not mutation rollback.

`Optic.getAll` collapses outer focus failure to `[]`; `getResult` distinguishes a failed outer focus from a successful empty selection. Decide whether “no matching entries” and “the collection is unavailable” mean the same thing before choosing the read operation.

## Representation-aware updates

Plain path optics shallow-copy arrays and ordinary objects along the focused path and retain unrelated branches. This is not deep cloning or universal reconstruction: a class instance on the copied path throws, and an accepted null-prototype record becomes an ordinary object. A custom instance used only as a leaf can be replaced wholesale without cloning its internals.

For schema classes and supported custom representations, use `Schema.toIso(schema)` to expose the schema's `Iso` shape and rebuild the source after modification. That shape is not necessarily the schema's ordinary encoded/wire form.

```ts
import { Schema } from "effect"

class Counter extends Schema.Class<Counter>("Counter")({ value: Schema.Number }) {}

const count = Schema.toIso(Counter).key("value")
const updated = count.modify((n) => n + 1)(Counter.make({ value: 1 }))
// Counter instance with value 2, not a plain object
```

`Schema.toIso` uses synchronous encoding/decoding. Invalid reconstructed values, asynchronous transformations, or service requirements can throw; `getResult`/`replaceResult` do not turn these exceptions into optic failures. Use an effectful parser over `Schema.toCodecIso(schema)` at a fallible or effectful boundary instead of hiding decoding in a modifier. `Schema.toIsoSource` and `Schema.toIsoFocus` are identity optics on their respective sides, not conversions that reconstruct class instances.

For a custom representation, define `Optic.makeIso(get, set)` only when both directions preserve the represented information. Restrict the focus domain if reconstruction would otherwise be lossy (for example, duplicate map entries or normalized text). If rebuilding needs the old whole to preserve unrelated data, use a Lens rather than pretending it is an Iso.

## Laws and domain tests

Optic constructors accept functions; they do not prove laws. For a claimed lossless Iso, test both `set(get(source)) ≈ source` and `get(set(focus)) ≈ focus` over the supported domain. Use domain equality, including meaningful representation invariants, rather than requiring object identity. For a custom Lens, test reading after replacement, replacing with the current focus, and successive replacements (the last write wins) while preserving unrelated data.

Use focused behavioral cases rather than snapshots of formatted issues:

- **Presence policy:** absent key, own undefined key, and present value; verify insertion, explicit undefined, deletion, and array index shifting where relevant.
- **Conditional transition:** wrong variant, failed refinement/check, and accepted source; verify both old-focus selection and whether the proposed value preserves the domain invariant.
- **Traversal:** mixed matching/nonmatching elements, zero matches, failed outer focus, wrong replacement count, and inner setter failure. Assert unchanged skipped values and no partially published update on failure.
- **Representation:** round trips, reconstruction of the expected class/custom type, preservation of domain information, and invalid reconstructed values at schema boundaries.
- **Error boundary:** map structured optic issues to the stable domain error expected by the caller; do not make library formatter text the contract.

Assert the original state remains unchanged. Assert structural sharing when it is a deliberate performance contract for a plain path, but do not infer that every equal-value update must return the same reference: path replacement can allocate even when the value is unchanged.
