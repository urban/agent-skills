# Effect Schema patterns for agents

These notes summarize the patterns to follow when writing `Schema` code in this project. They are based on `repos/effect/packages/effect/SCHEMA.md`, `repos/effect/packages/effect/src/Schema.ts`, the Effect schema tests, and Schema usage in `repos/alchemy-effect`, `repos/executor`, and `repos/t3code`.

## First principles

- Define schemas at boundaries and reuse them for both runtime validation and TypeScript types.
- Treat `Schema.Type` as the decoded/domain representation and `Schema.Encoded` as the input/output representation.
- Decode untrusted data with `Schema.decodeUnknownEffect` or `Schema.decodeUnknownSync`; decode statically typed encoded data with `Schema.decodeEffect` or `Schema.decodeSync`.
- Hoist compiled decoders and encoders to module scope. `repos/t3code/oxlint-plugin-t3code/rules/no-inline-schema-compile.ts` exists because compiler calls allocate.
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

Adapted from `repos/executor/packages/core/config/src/schema.ts`.

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

Adapted from `repos/executor/packages/core/config/src/schema.ts`.

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

Adapted from `repos/t3code/packages/contracts/src/baseSchemas.ts`.

## Encoding and decoding examples

### Decode unknown input at the boundary

Use this for HTTP payloads, config files, command output, local storage, and other untrusted inputs:

```ts
import { Effect, Schema } from "effect";

export const ExecutorFileConfig = Schema.Struct({
  name: Schema.optional(Schema.String),
  plugins: Schema.optional(Schema.Array(PluginConfig)),
});
export type ExecutorFileConfig = typeof ExecutorFileConfig.Type;

const decodeExecutorFileConfig = Schema.decodeUnknownEffect(ExecutorFileConfig);

export const normalizeConfig = (parsed: unknown) =>
  decodeExecutorFileConfig(parsed).pipe(Effect.mapError((error) => error.issue.toString()));
```

Adapted from `repos/executor/packages/core/config/src/load.ts`.

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

Adapted from `repos/t3code/packages/tailscale/src/tailscale.ts`.

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

This mirrors the optional-field pattern in `repos/effect/packages/effect/SCHEMA.md`.

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

### Schema decode errors

`Schema.decodeUnknownEffect` fails with `Schema.SchemaError`. Convert it to your domain error at the boundary.

```ts
import { Effect, Schema } from "effect";

export class ConfigParseError extends Schema.TaggedErrorClass<ConfigParseError>()(
  "ConfigParseError",
  {
    path: Schema.String,
    message: Schema.String,
  },
) {}

const decodeConfig = Schema.decodeUnknownEffect(ExecutorFileConfig);

export const decodeConfigFile = (path: string, parsed: unknown) =>
  decodeConfig(parsed).pipe(
    Effect.mapError(
      (error) =>
        new ConfigParseError({
          path,
          message: error.issue.toString(),
        }),
    ),
  );
```

Adapted from `repos/executor/packages/core/config/src/load.ts`.

### Tagged errors for Effect programs

Use `Schema.TaggedErrorClass` when the error crosses Effect boundaries or HTTP API definitions.

```ts
import { Effect, Schema } from "effect";

export class InternalError extends Schema.TaggedErrorClass<InternalError>()(
  "InternalError",
  {
    traceId: Schema.String,
  },
  { httpApiStatus: 500 },
) {}

const program = Effect.gen(function* () {
  return yield* new InternalError({ traceId: "evt_123" });
}).pipe(Effect.catchTag("InternalError", (error) => Effect.succeed(error.traceId)));
```

Adapted from `repos/executor/packages/core/sdk/src/api-errors.ts`.

### Custom validation messages

Use `Schema.makeFilter` when built-in filters cannot describe the rule.

```ts
export const PasswordPair = Schema.Struct({
  password: Schema.String,
  confirmPassword: Schema.String,
}).check(
  Schema.makeFilter((value) =>
    value.password === value.confirmPassword
      ? undefined
      : { path: ["confirmPassword"], issue: "passwords must match" },
  ),
);
```

Return `undefined` or `true` for success, `false` for a generic failure, a `string` for a custom message, or `{ path, issue }` for nested-field failures.

## API and HTTP patterns

Schemas can be used directly in `HttpApi` endpoints:

```ts
import { Schema } from "effect";
import * as HttpApiEndpoint from "effect/unstable/httpapi/HttpApiEndpoint";

export const JobId = Schema.String.annotate({ description: "The ID of the job" });

export const Job = Schema.Struct({
  id: JobId,
  content: Schema.String,
});
export type Job = typeof Job.Type;

export const getJob = HttpApiEndpoint.get("getJob", "/", {
  success: Job,
  query: {
    jobId: JobId.pipe(Schema.optional),
  },
});
```

Adapted from `repos/alchemy-effect/examples/aws-lambda-httpapi/src/Job.ts` and `JobApi.ts`.

## Testing patterns

Effect’s own tests use `TestSchema.Asserts` for exhaustive schema behavior. In application tests, the most important checks are usually semantic:

```ts
import { Effect, Exit, Schema } from "effect";
import { expect, it } from "vitest";

const decode = Schema.decodeUnknownEffect(PortFromString);

it("rejects ports outside the TCP range", async () => {
  const exit = await Effect.runPromiseExit(decode("70000"));
  expect(Exit.isFailure(exit)).toBe(true);
});

it("decodes a valid port", async () => {
  await expect(Effect.runPromise(decode("443"))).resolves.toBe(443);
});
```

Use parse options when you need specific behavior:

```ts
const decodeStrictUser = Schema.decodeUnknownEffect(User, {
  onExcessProperty: "error",
  errors: "all",
});
```

## What to avoid

- Do not call `Schema.decode*` / `Schema.encode*` compiler functions inside hot functions. Hoist them.
- Do not use `JSON.parse` / `JSON.stringify` for typed boundary data. Use `Schema.fromJsonString`, `Schema.UnknownFromJsonString`, and schema encoders.
- Do not use `Schema.Any` or `Schema.Unknown` inside domain models unless the data is intentionally opaque. Keep unknown shapes at boundaries.
- Do not use `Schema.String` where a literal union, brand, or constrained string expresses the domain.
- Do not represent domain absence with `null`. Accept `Schema.NullOr(...)` only for external wire compatibility and normalize it.
- Do not throw for expected validation failures. Use `decodeUnknownEffect`, `decodeUnknownExit`, `decodeUnknownOption`, or map `Schema.SchemaError` into a tagged error.
- Do not use `Schema.Class` for plain DTOs unless runtime class identity is required. Prefer `Struct` / `TaggedStruct` for serializable shapes.
- Do not hide schema errors by catching them and returning broad fallbacks unless the fallback is part of the product contract.
- Do not add type assertions to force schema types. If inference is hard, introduce a named schema, `typeof Schema.Type`, `typeof Schema.Encoded`, or a narrower helper.
