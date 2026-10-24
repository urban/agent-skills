# Representation and decoding

## Type and Encoded

Design both sides:

- `Type`: canonical value domain code consumes.
- `Encoded`: value accepted from or emitted to the boundary; not necessarily a JSON string.

Examples include string timestamps decoded to date values, nullable legacy fields decoded to one absence representation, snake-case wire keys decoded to domain names, and strings decoded to branded identifiers.

Derive representations from the schema so the contract owns both shapes:

```ts
import { Schema } from "effect"

export const DocumentMetadata = Schema.Struct({
  documentId: Schema.String,
}).pipe(Schema.encodeKeys({ documentId: "document_id" }))

export type DocumentMetadata = typeof DocumentMetadata.Type
export type EncodedDocumentMetadata = typeof DocumentMetadata.Encoded

Schema.decodeUnknownSync(DocumentMetadata)({ document_id: "doc-1" })
// { documentId: "doc-1" }
Schema.encodeSync(DocumentMetadata)({ documentId: "doc-1" })
// { document_id: "doc-1" }
```

`encodeKeys` maps domain keys to encoded keys; it is not an alias policy that accepts both spellings. A rename's compatibility policy still needs a deliberate decision.

## Boundary validation

Unknown external input needs runtime validation before the domain trusts it. `decodeUnknownEffect` exposes that boundary; `decodeEffect` accepts statically typed encoded input but still performs validation and transformation. Typed input can violate checks, so typed decoding can still fail. Encoding also validates; it is not an unchecked serializer.

Give raw database rows and provider payloads separate schemas when names, optionality, or primitive representations differ from the domain. Accept multiple driver representations only when the supported client contract requires them; otherwise reject the extra representation instead of spreading normalization through the application.

## Absence

| Meaning | Boundary design |
| --- | --- |
| A key may be absent, but a present value must be valid | `Schema.optionalKey(S)`; explicit undefined is rejected unless `S` accepts it |
| Missing and explicit undefined are both permitted | `Schema.optional(S)`; equivalent to `optionalKey(UndefinedOr(S))` |
| A required key may contain undefined | `Schema.UndefinedOr(S)` without optional-key wrapping |
| A peer requires a nullable key, domain uses explicit absence | `Schema.OptionFromNullOr(S)`; `None` encodes as null |
| Legacy missing, undefined, and null all mean absence | `Schema.OptionFromOptionalNullOr(S)`; choose how `None` encodes |
| Omission and clear have different meanings | Preserve presence separately from the nullable value, or use tagged commands |

For a replacement payload where all legacy absence spellings mean the same thing:

```ts
import { Option, Schema } from "effect"

const Profile = Schema.Struct({
  nickname: Schema.OptionFromOptionalNullOr(Schema.String, {
    onNoneEncoding: null,
  }),
})

Schema.decodeUnknownSync(Profile)({}) // { nickname: Option.none() }
Schema.decodeUnknownSync(Profile)({ nickname: null }) // same domain value
Schema.encodeSync(Profile)({ nickname: Option.none() }) // { nickname: null }
```

Without options, `OptionFromOptionalNullOr` encodes `None` by omitting the key. This collapses input distinctions permanently; it is inappropriate for a patch where omission means “leave unchanged” and null means “clear”.

## Defaults

A default is a policy for absent data, not recovery from invalid data:

- `withConstructorDefault` applies only during `make*`, not decoding or encoding.
- `withDecodingDefaultKey` fills a missing key with an **encoded** value before the field's decoding transformations. It does not default a present undefined value.
- `withDecodingDefault` also fills explicit undefined. Null and malformed present values are not default triggers.
- Use the `Type` variants when the default is already a decoded value rather than an encoded value. For example, a numeric domain default for `FiniteFromString` is a number, not its string encoding.

```ts
import { Effect, Schema } from "effect"

const Settings = Schema.Struct({
  retryLimit: Schema.FiniteFromString.pipe(
    Schema.withDecodingDefaultKey(Effect.succeed("3")),
  ),
})

Schema.decodeUnknownSync(Settings)({}) // { retryLimit: 3 }
Schema.decodeUnknownSync(Settings)({ retryLimit: "5" }) // { retryLimit: 5 }
Schema.encodeSync(Settings)({ retryLimit: 5 }) // { retryLimit: "5" }
// { retryLimit: undefined }, { retryLimit: null }, and malformed strings fail decoding.
```

Decoding defaults encode with `"passthrough"` by default. The alternative `encodingStrategy: "omit"` always omits the field, not just values equal to the default. This can destroy edits during read-modify-write.

Use a default for an evolving payload only if absence has a defensible historical meaning. If “not recorded” differs from a real zero, false, or current timestamp, preserve an unknown/absent state instead.

## Classes, brands, and JSON

Use brands for structurally identical values that must not mix. Branding does not add a runtime validity rule: compose checks for syntax/range and keep database existence checks or authorization in the application layer.

Use classes for ordinary data only when runtime identity or methods matter. Plain wire DTOs normally remain structures. Schema-backed failures may intentionally need Error identity and yieldability; those are different from ordinary DTOs.

Use `Schema.fromJsonString(DomainSchema)` for a JSON-text boundary. It parses JSON into the domain schema's encoded representation, then decodes it; encoding runs the reverse path before serialization. Do not confuse a schema's `Encoded` object with serialized JSON text.

## Source anchors

Effect v4: `packages/effect/src/Schema.ts` (`encodeKeys`, optionality, decoding defaults, Option codecs, `fromJsonString`); `packages/effect/test/schema/Schema.test.ts` (matching suites for omission, null, transformed fields, and defaults).
