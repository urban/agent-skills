# Effect Schema patterns for agents — part 1

Covers:

- Effect Schema patterns for agents
- First principles
- Common constructors and combinators
- Values and collections
- Optionality
- Literals and discriminated unions
- Filters
- Encoding and decoding examples

---

# Effect Schema patterns for agents

## First principles

- Define schemas at boundaries and reuse them for both runtime validation and TypeScript types.
- Treat `Schema.Type` as the decoded/domain representation and `Schema.Encoded` as the input/output representation.
- Decode untrusted data with `Schema.decodeUnknownEffect` or `Schema.decodeUnknownSync`; decode statically typed encoded data with `Schema.decodeEffect` or `Schema.decodeSync`.
- Hoist compiled decoders and encoders to module scope because compiler calls allocate.
- Prefer `Schema.Struct` / `Schema.TaggedStruct` plus `export type X = typeof X.Type` for plain data. Use `Schema.Class` only when runtime class instances, methods, or `instanceof` semantics are intentional.
- Use `Schema.TaggedErrorClass` for Effect errors that should be caught with `Effect.catchTag` / `Effect.catchTags`.
- Use `Schema.fromJsonString(...)` instead of `JSON.parse` at implementation boundaries.

```ts
import { Effect, Schema } from "effect";

export const User = Schema.Struct({
  id: Schema.String.pipe(Schema.brand("UserId")),
  name: Schema.String.check(Schema.isNonEmpty()),
});
export type User = typeof User.Type;

const decodeUser = Schema.decodeUnknownEffect(User);

export const parseUser = (input: unknown) =>
  decodeUser(input).pipe(Effect.mapError((error) => error.issue.toString()));
```

## Common constructors and combinators

### Values and collections

```ts
import { Schema } from "effect";

Schema.String;
Schema.Number;
Schema.Int;
Schema.Finite;
Schema.Boolean;
Schema.Unknown;
Schema.Defect;

Schema.Literal("openapi");
Schema.Literals(["remote", "local", "unsafe-no-auth"]);
Schema.Array(Schema.String);
Schema.Record(Schema.String, Schema.Unknown);
Schema.Tuple([Schema.String, Schema.Int]);
Schema.Union([Schema.String, Schema.Number]);
```

Use `Schema.Struct` for fixed object shapes:

```ts
export const PluginConfig = Schema.Struct({
  package: Schema.String,
  options: Schema.optional(Schema.Record(Schema.String, Schema.Unknown)),
});
export type PluginConfig = typeof PluginConfig.Type;
```

Example pattern:

### Optionality

Choose the optional constructor that matches the wire contract:

```ts
export const Example = Schema.Struct({
  // Key may be absent. Prefer this for exact optional wire fields.
  label: Schema.optionalKey(Schema.String),

  // Key may be absent or present as undefined.
  namespace: Schema.optional(Schema.String),

  // Only use null when the external protocol actually sends null.
  deletedAt: Schema.optionalKey(Schema.NullOr(Schema.DateTimeUtc)),
});
```

For project domain code, avoid introducing `null` as a new absence vocabulary. If a wire format can be `null`, decode it at the boundary into `Option`, an optional key, or a discriminated union.

### Literals and discriminated unions

Prefer literal tags over loose strings when variants have different required fields:

```ts
export const McpAuthConfig = Schema.Union([
  Schema.Struct({ kind: Schema.Literal("none") }),
  Schema.Struct({
    kind: Schema.Literal("header"),
    headerName: Schema.String,
    secret: Schema.String,
    prefix: Schema.optional(Schema.String),
  }),
  Schema.Struct({
    kind: Schema.Literal("oauth2"),
    connectionId: Schema.String,
  }),
]);
export type McpAuthConfig = typeof McpAuthConfig.Type;
```

Example pattern:

### Filters

Add constraints with `.check(...)`. Useful built-ins include:

```ts
Schema.String.check(
  Schema.isNonEmpty(),
  Schema.isMinLength(3),
  Schema.isMaxLength(64),
  Schema.isPattern(/^[a-z0-9-]+$/u),
  Schema.isTrimmed(),
);

Schema.Number.check(
  Schema.isInt(),
  Schema.isBetween({ minimum: 1, maximum: 65535 }),
  Schema.isGreaterThanOrEqualTo(0),
);
```

Use branded schemas for IDs that share the same runtime shape but must not mix:

```ts
const makeEntityId = <Brand extends string>(brand: Brand) =>
  Schema.String.check(Schema.isNonEmpty(), Schema.isTrimmed()).pipe(Schema.brand(brand));

export const ThreadId = makeEntityId("ThreadId");
export type ThreadId = typeof ThreadId.Type;
```

Example pattern:

## Encoding and decoding examples

### Decode unknown input at the boundary

Use this for HTTP payloads, config files, command output, local storage, and other untrusted inputs:

```ts
import { Effect, Schema } from "effect";

export const AppFileConfig = Schema.Struct({
  name: Schema.optional(Schema.String),
  plugins: Schema.optional(Schema.Array(PluginConfig)),
});
export type AppFileConfig = typeof AppFileConfig.Type;

const decodeAppFileConfig = Schema.decodeUnknownEffect(AppFileConfig);

export const normalizeConfig = (parsed: unknown) =>
  decodeAppFileConfig(parsed).pipe(Effect.mapError((error) => error.issue.toString()));
```

Example pattern:
