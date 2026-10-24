# Transformations and errors

## Transformation law

A codec needs a defined decode input, canonical output, encode input, emitted output, and failure policy for each direction. For lossless codecs, decoding an encoded domain value should recover that value; encoding decoded input should recover the original representation. For normalization, the latter law instead produces a documented canonical representation, not the original bytes.

`From.pipe(Schema.decodeTo(To, transformation))` composes stages:

- Decode: `From.Encoded` → `From.Type` → custom decode → `To.Encoded` → `To.Type`.
- Encode: `To.Type` → `To.Encoded` → custom encode → `From.Type` → `From.Encoded`.

The custom getters bridge the **intermediate** representations, not necessarily the public endpoints. Without custom getters, the intermediate value passes through; both schemas still validate/transform it.

```ts
import { Schema, SchemaGetter } from "effect"

const EnabledFromStatus = Schema.Literals(["enabled", "disabled"]).pipe(
  Schema.decodeTo(Schema.Boolean, {
    decode: SchemaGetter.transform((status) => status === "enabled"),
    encode: SchemaGetter.transform((enabled) => enabled ? "enabled" : "disabled"),
  }),
)

Schema.decodeUnknownSync(EnabledFromStatus)("enabled") // true
Schema.encodeSync(EnabledFromStatus)(false) // "disabled"
```

This finite mapping is bidirectional. If a new status such as `"pending"` has distinct meaning, do not casually extend the input and collapse it to false: change the domain representation or define an explicit compatibility policy.

Use `SchemaGetter.transformEffect` for fallible/effectful conversion and return a `SchemaIssue` for an expected conversion failure. Throwing from a pure getter is not a schema validation failure. Prefer an existing codec when its semantics fit: `FiniteFromString` rejects non-finite results but uses JavaScript number coercion, so empty/whitespace strings become zero. Add a lexical check if the protocol requires stricter numeric text.

Service-backed checks or transformations make decode/encode depend on runtime services and may fail in either direction. Keep the caller responsible for execution and service provision; use pure representation conversion when repeatability and replay matter, and leave business side effects outside the codec.

## Error information and mapping

`Schema.decodeUnknownEffect` fails on validation with `Schema.SchemaError`. Its `issue` is a structured `SchemaIssue.Issue` tree containing paths and failure details; `message` renders that tree. Lower-level `SchemaParser` adapters expose issues directly.

Keep issues intact inside boundary code. Map to a domain error when callers need a stable category or public-safe message, and retain safe diagnostic context rather than replacing everything with “invalid input”. Use `errors: "all"` when callers benefit from multiple field errors rather than the default first failure.

`reportInput` defaults to false. Setting it to true retains rejected values by reference in enumerable issue fields, and built-in formatting can disclose them. Custom messages, annotations, and custom issues can expose sensitive values even without this option. Redact or exclude input at the presentation/logging boundary; `SchemaError.message` is not automatically a safe public response.

Recover only a named semantic failure. Missing optional data may have a fallback; malformed content, access failures, and defects should not all become that same fallback.

## Checks and tagged errors

Prefer built-in checks and composition before a custom predicate. Attach a stable domain message only where it clarifies a caller-facing invariant; do not discard field paths or replace all failures with one generic message.

When a domain-facing failure needs both schema behavior and Error identity/yieldability:

```ts
import { Schema } from "effect"

export class RecordDecodeError extends Schema.TaggedError<RecordDecodeError>()(
  "RecordDecodeError",
  { recordId: Schema.String },
) {}
```

The class is the schema and instance type. Choose diagnostic fields intentionally; do not automatically serialize raw rejected payloads or the entire internal issue tree into a public error.

## Schema evolution

Separate reader compatibility from writer compatibility:

- A new reader may accept historical encodings while returning one current domain shape. Use explicit version/variant schemas when meanings differ, not just permissive predicates.
- A current writer must deliberately choose an emitted representation. Accepting both old and new forms does not decide which one old consumers can read.
- Adding a required field rejects historical payloads unless absence has a valid migration/default meaning. Tightening a check can likewise invalidate stored data.
- Default object parsing strips unknown keys. This supports readers that tolerate additions, but loses those additions during re-encoding. Use `onExcessProperty: "error"` when unknown fields should indicate a contract error; explicitly model extension data when it must survive.
- Overlapping union members can both accept the same payload. Prefer explicit version tags or otherwise unambiguous alternatives instead of letting branch order decide migration meaning.

## Semantic tests

Test the contract, not merely whether sample values construct:

- Representative decode and encode, including rejection at important invariant boundaries.
- A presence matrix for relevant fields: missing, undefined, null, valid, malformed. Check emitted absence/default behavior as well as decoded values.
- Historical fixtures decoded to current domain meaning, plus current output readable by required consumers.
- Unknown-field acceptance/rejection and whether accepted fields must survive read-modify-write.
- Round-trip laws in each promised direction. For canonicalizing codecs, assert canonical output and normalization idempotence rather than raw equality with legacy input.
- Useful issue paths/categories and public-message safety. Assert exact rendered text only when that text itself is a contract.
- Custom generator validity when the schema supplies arbitrary generation; generated valid values alone do not prove rejection policy.

## Source anchors

Effect v4: `packages/effect/src/Schema.ts` (`decodeTo`, `SchemaError`, `TaggedError`), `SchemaGetter.ts` (`transform`, `transformEffect`), `SchemaAST.ts` (`ParseOptions`), and `SchemaParser.ts`; `packages/effect/test/schema/Schema.test.ts` (`decodeTo`, `onExcessProperty`, default and error-adapter suites) and `SchemaGetter.test.ts` (issue reporting).
