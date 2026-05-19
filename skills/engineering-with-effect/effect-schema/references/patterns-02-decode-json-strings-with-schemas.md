# Effect Schema patterns for agents — part 2

Covers:

- Decode JSON strings with schemas
- Encode typed values
- Hoist compilers
- Transformation patterns
- Simple string normalization
- Domain conversion with decodeTo
- Transformations that can fail
- Optional transformations

---

### Decode JSON strings with schemas

```ts
import { Effect, Schema } from "effect";

const TailscaleStatusSelf = Schema.Struct({
  DNSName: Schema.optional(Schema.Unknown),
  TailscaleIPs: Schema.optional(Schema.Unknown),
});

const TailscaleStatusJson = Schema.Struct({
  Self: Schema.optional(TailscaleStatusSelf),
});

type TailscaleStatusJson = typeof TailscaleStatusJson.Type;

const decodeTailscaleStatusJson = Schema.decodeEffect(Schema.fromJsonString(TailscaleStatusJson));

export const parseStatus = (raw: string): Effect.Effect<TailscaleStatusJson, Schema.SchemaError> =>
  decodeTailscaleStatusJson(raw);
```

Example pattern:

### Encode typed values

```ts
const AuthSession = Schema.Struct({
  sessionId: Schema.String.pipe(Schema.brand("AuthSessionId")),
  expiresAt: Schema.DateTimeUtc,
});

type AuthSession = typeof AuthSession.Type;

const encodeAuthSession = Schema.encodeEffect(AuthSession);

export const writeSession = (session: AuthSession) => encodeAuthSession(session);
```

Use `Schema.encodeUnknownEffect` only when the input is also untrusted and must be checked against the decoded `Type` before encoding.

### Hoist compilers

Good:

```ts
const decodeRemoteLaunchResult = Schema.decodeEffect(Schema.fromJsonString(RemoteLaunchResult));

export const decodeRemoteLaunchOutput = (stdout: string) => decodeRemoteLaunchResult(stdout);
```

Avoid:

```ts
export const decodeRemoteLaunchOutput = (stdout: string) =>
  Schema.decodeEffect(Schema.fromJsonString(RemoteLaunchResult))(stdout);
```

The second form rebuilds the compiled decoder on every call.

## Transformation patterns

### Simple string normalization

Use `SchemaTransformation` when the encoded and decoded value need normalization.

```ts
import { Schema, SchemaTransformation } from "effect";

export const TrimmedString = Schema.String.pipe(Schema.decode(SchemaTransformation.trim()));

export const TrimmedNonEmptyString = TrimmedString.check(Schema.isNonEmpty());
```

`Schema.decode(transformation)` is shorthand for `Schema.decodeTo(theSameSchema, transformation)`.

### Domain conversion with `decodeTo`

```ts
import { Schema, SchemaTransformation } from "effect";

export const PortFromString = Schema.String.pipe(
  Schema.decodeTo(
    Schema.Int.check(Schema.isBetween({ minimum: 1, maximum: 65535 })),
    SchemaTransformation.numberFromString,
  ),
);
```

Use `decodeTo` when the source and target schemas differ. Encoding runs the transformation in reverse.

### Transformations that can fail

Use `SchemaTransformation.transformOrFail` when conversion can fail and you need a schema error rather than a thrown exception.

```ts
import { Effect, Option, Schema, SchemaIssue, SchemaTransformation } from "effect";

export const URLFromString = Schema.String.pipe(
  Schema.decodeTo(
    Schema.instanceOf(URL),
    SchemaTransformation.transformOrFail({
      decode: (value) =>
        Effect.try({
          try: () => new URL(value),
          catch: () =>
            new SchemaIssue.InvalidValue(Option.some(value), {
              message: `Invalid URL: ${value}`,
            }),
        }),
      encode: (url) => Effect.succeed(url.href),
    }),
  ),
);
```

### Optional transformations

When optional wire fields need domain-level absence, use `transformOptional` or the built-in `OptionFromOptional*` helpers.

```ts
import { Option, Schema, SchemaTransformation } from "effect";

export const OptionFromNonEmptyString = Schema.optionalKey(Schema.String).pipe(
  Schema.decodeTo(
    Schema.Option(Schema.NonEmptyString),
    SchemaTransformation.transformOptional({
      decode: (input) =>
        Option.isSome(input) && input.value !== ""
          ? Option.some(Option.some(input.value))
          : Option.some(Option.none()),
      encode: Option.flatten,
    }),
  ),
);
```

This mirrors the optional-field pattern in `.dotai/repos/effect/packages/effect/SCHEMA.md`.

### Key transformations

For dynamic record keys, transform the key schema:

```ts
import { Schema, SchemaTransformation } from "effect";

const SnakeToCamel = Schema.String.pipe(Schema.decode(SchemaTransformation.snakeToCamel()));

export const Env = Schema.Record(SnakeToCamel, Schema.String);
```

For fixed struct keys, prefer `Schema.encodeKeys` so decoded code uses camelCase while encoded wire data can remain snake_case:

```ts
export const Account = Schema.Struct({
  userId: Schema.String,
  accountName: Schema.String,
}).pipe(
  Schema.encodeKeys({
    userId: "user_id",
    accountName: "account_name",
  }),
);
```

## Error handling patterns
