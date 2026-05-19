# Effect Schema patterns for agents — part 3

Covers:

- Schema decode errors
- Tagged errors for Effect programs
- Custom validation messages
- API and HTTP patterns
- Testing patterns
- What to avoid

---

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

const decodeConfig = Schema.decodeUnknownEffect(AppFileConfig);

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

Example pattern:

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

Example pattern:

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

Example pattern:

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
