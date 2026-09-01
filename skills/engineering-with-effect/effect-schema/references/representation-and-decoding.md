# Representation and decoding

## Type and Encoded

Design both sides:

- `Type`: canonical value domain code consumes.
- `Encoded`: value accepted from or emitted to the boundary.

Examples include string timestamps decoded to date values, nullable legacy fields decoded to one absence representation, snake-case wire keys decoded to domain names, and unbranded strings decoded to branded identifiers.

Define the schema implementation first and derive its representations:

```ts
export const DocumentMetadata = Schema.Struct({
  documentId: Schema.String,
})
export type DocumentMetadata = typeof DocumentMetadata.Type
export type EncodedDocumentMetadata = typeof DocumentMetadata.Encoded
```

Do not repeat the decoded shape in a handwritten type or annotate the initialized schema with a broad `Schema.Codec`, `Schema.Class`, or field-map type. Those annotations can discard literal, brand, field-modifier, and encoded information. Keep an independent type when no schema represents it, such as an application result assembled from already-derived domain types.

Build schema unions from implementations and derive the union type:

```ts
export const RejectionReason = Schema.Union([
  InvalidDatabase,
  IncompatibleFormat,
])
export type RejectionReason = typeof RejectionReason.Type
```

Use `satisfies` for schema options or annotations that need checking without replacing the object's inferred type.

## Trust-aware decoding

- Unknown external input needs runtime validation before the domain trusts it.
- Preserve known static input types rather than unnecessarily erasing them at the boundary.
- Encoding from untrusted decoded input requires validation; encoding an existing domain value should preserve its static type.
- Give raw database rows, provider payloads, and other boundary-specific representations their own schemas when their names, optionality, or primitive representations differ from the domain.
- Decide driver compatibility at the boundary. Accept multiple primitive representations only when the supported client contract requires them; otherwise reject the extra representation instead of carrying normalization through the application.

## Absence

Choose one semantic:

| Wire/domain need | Representation decision |
| --- | --- |
| Field may be missing | Optional key |
| Field exists and may hold undefined | Required/optional value containing undefined |
| Peer sends null | Accept null on encoded side, normalize on decoded side |
| Absence is manipulated explicitly | Option |
| Variants have distinct data | Tagged union |

## Classes and brands

Use brands for structurally identical values that must not mix. Derive the brand type from its schema unless a verified compiler or tooling limitation requires a documented exception.

Use classes for ordinary data only when runtime identity or methods are required. Plain wire DTOs normally remain structures. Schema-backed failures are different: when they need Error identity and yieldable behavior, use Effect's self-typed `Schema.TaggedError<Self>()` class directly and do not add a parallel alias.

## JSON

Compose JSON string parsing with the domain schema. This keeps syntax, wire-shape, transformation, and domain validation in one typed boundary.
