# Properties and arbitraries

## Choose the law and its space

Useful laws include idempotence, ordering, commutativity, monotonicity, invariant preservation, and error classification. Define the observation and equivalence relation before choosing inputs: sorting preserves a multiset, not element identity; normalization is idempotent, not necessarily reversible.

Effect v4 uses native `Arbitrary` from `effect`. `@effect/vitest` accepts schemas and native arbitraries directly; its property engine is not a fast-check adapter.

`Arbitrary.schema(codec)` generates the decoded `Type`, as does passing a schema directly to `it.prop` or `it.effect.prop`. This does not explore the original codec's accepted wire spellings.

`Arbitrary.schema(Schema.toEncoded(codec))` generates the encoded-side schema with the decoding transformation removed. That space can be broader than accepted decoder inputs: the encoded side of `Schema.FiniteFromString` is a string schema, not a guarantee that every generated string parses as a finite number. Choose deliberately between:

- domain values, for domain invariants and encode-then-decode laws;
- accepted wire values, including alternate spellings, for decoding and normalization;
- deliberate invalid classes, for rejection and error classification.

## Round trips are directional

- `decode(encode(domain)) ≈ domain` checks preservation under domain equivalence.
- `encode(decode(wire)) = canonical(wire)` permits normalization.
- Exact identity in both directions requires a genuinely lossless representation.

`TestSchema.Asserts.verifyRoundTripEffect` generates decoded values and checks the first law using `Schema.toEquivalence`, including custom equivalence annotations. It does not prove acceptance of alternate wire forms or rejection of malformed inputs. `arbitrary().verifyGeneration()` only checks that generated values satisfy the schema predicate; it is not a behavioral law for the application.

```ts
import { assert, it } from "@effect/vitest"
import { Arbitrary, Effect, Schema } from "effect"
import { TestSchema } from "effect/testing"

const Count = Schema.Int.check(
  Schema.isBetween({ minimum: 0, maximum: 999 })
)
const CountCodec = Schema.FiniteFromString.check(
  Schema.isInt(),
  Schema.isBetween({ minimum: 0, maximum: 999 })
)

it.effect("count codec preserves domain values", () =>
  new TestSchema.Asserts(CountCodec).verifyRoundTripEffect())

// Carry the expected value with its alternate wire spelling.
const PaddedCount = Arbitrary.map(Arbitrary.schema(Count), (value) => ({
  value,
  wire: String(value).padStart(4, "0")
}))

it.effect.prop(
  "padded counts normalize to canonical decimal",
  [PaddedCount],
  ([{ value, wire }]) => Effect.gen(function*() {
    const decoded = yield* Schema.decodeUnknownEffect(CountCodec)(wire)
    const canonical = yield* Schema.encodeEffect(CountCodec)(decoded)
    assert.strictEqual(canonical, String(value))
  })
)
```

The first property covers count values; the second covers noncanonical wire spellings such as `"0007"`. Neither checks rejection of fractional or out-of-range inputs; generate those classes separately.

## Construct relationships that survive shrinking

Prefer schema checks with constructive generation support over broad filters. For related values, transform one generated source into a valid tuple or use dependent generation with `Arbitrary.flatMap`; keep the relationship valid when either side shrinks. Do not select dependent values with ambient randomness or mutable counters.

Use custom generation when schema derivation is sparse or unavailable. Unsupported declarations can fail during derivation, and recursive schemas need a finite generation path. A declaration's `toCodecArbitrary` hook can supply a generation codec. A custom `Arbitrary.schema(schema, { shrink })` callback only replaces shrinking, not root generation; it cannot repair unsupported derivation.

A custom shrinker should describe semantic simplifications, remain deterministic and terminating, and preserve domain relationships. The runner validates its candidates against the decoded schema, but cannot infer application invariants absent from that schema. Rejected candidates still consume the shrink budget. A bounded shrink result is the best failure found, not proof of global minimality.

Source anchors (Effect v4): `packages/effect/src/Arbitrary.ts` (`schema`, `flatMap`, `SchemaOptions`), `packages/effect/src/Schema.ts` (`toEncoded`), and `packages/effect/src/testing/TestSchema.ts` (`verifyRoundTripEffect`). Derivation, custom shrink, and exhaustion cases are exercised in `packages/effect/test/arbitrary/Arbitrary.test.ts`; equivalence-aware round trips are exercised in `packages/effect/test/testing/TestSchema.test.ts`.
