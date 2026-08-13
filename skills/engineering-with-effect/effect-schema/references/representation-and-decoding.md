# Representation and decoding

## Type and Encoded

Design both sides:

- `Type`: canonical value domain code consumes.
- `Encoded`: value accepted from or emitted to the boundary.

Examples include string timestamps decoded to date values, nullable legacy fields decoded to one absence representation, snake-case wire keys decoded to domain names, and unbranded strings decoded to branded identifiers.

## Trust-aware decoding

- Unknown external input needs runtime validation before the domain trusts it.
- Preserve known static input types rather than unnecessarily erasing them at the boundary.
- Encoding from untrusted decoded input requires validation; encoding an existing domain value should preserve its static type.

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

Use brands for structurally identical values that must not mix. Use classes only when runtime identity or methods are required. Plain wire DTOs normally remain structures.

## JSON

Compose JSON string parsing with the domain schema. This keeps syntax, wire-shape, transformation, and domain validation in one typed boundary.
