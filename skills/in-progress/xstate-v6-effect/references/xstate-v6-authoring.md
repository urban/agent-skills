# XState v6 authoring for Effect applications

This guidance follows the checked v6 migration document and v6 source at `6.0.0-alpha.25`. Inspect installed package types before using it because alpha APIs can change.

## v6 substitutions

| Do not use | Use in v6 |
| --- | --- |
| `assign(...)` | return `{ context: { ...patch } }` |
| `raise(...)` | `enq.raise(...)` |
| `sendTo` / `sendParent` / `forwardTo` | `enq.sendTo(ref, event)`; parent is in args |
| `emit(...)` | `enq.emit(...)` |
| `spawnChild(...)` / `stopChild(...)` | `enq.spawn(...)` / `enq.stop(...)` |
| `enqueueActions(...)` | the ordinary inline `(args, enq) => ...` handler |
| `and` / `or` / `not` | JavaScript boolean expressions |
| `stateIn(...)` | `checkStateIn(self.getSnapshot(), value)` |
| `interpret(machine)` | `createActor(machine)` when XState owns runtime |
| `fromPromise(...)` | `createAsyncLogic({ run })` |
| `types: {} as ...` | `schemas`, or `types<T>()` for type-only declarations |

Transition handlers may return `target`, a shallow `context` patch, `reenter`, or `meta`. Entry and exit handlers may return context/children updates but cannot target another state. Returning `undefined` from a transition handler means the event is unhandled at that state.

Do not carry an older alpha rule that context must always be returned in full. Current v6 migration docs and source apply shallow top-level patches. When targeting a state with narrower required context, include the fields required by that target.

## Effect Schema

XState accepts Standard Schema. Convert Effect schemas explicitly:

```ts
import { Schema } from "effect";
import { setup } from "xstate";

const standard = Schema.toStandardSchemaV1;

const SearchContext = Schema.Struct({
  query: Schema.String,
});

const Search = Schema.Struct({
  query: Schema.String,
});

const SearchSucceeded = Schema.Struct({
  results: Schema.Array(Schema.String),
});

const searchMachine = setup({
  schemas: {
    context: standard(SearchContext),
    events: {
      search: standard(Search),
      searchSucceeded: standard(SearchSucceeded),
    },
  },
}).createMachine({
  context: { query: "" },
  initial: "Idle",
  states: {
    Idle: {
      on: {
        search: ({ event }) => ({
          target: "Searching",
          context: { query: event.query },
        }),
      },
    },
    Searching: {},
  },
});
```

Important schema facts:

- `events` and `emitted` are maps keyed by the event type.
- Each map value describes the payload without the `type` field.
- Schemas currently provide inference and runtime-readable metadata; they do not reject malformed values at runtime.
- Decode HTTP, WebSocket, storage, browser, and message-bus values with the original Effect Schema before calling `send` or offering to a mailbox.
- Use `types<T>()` only when there is genuinely no runtime boundary to validate.

## State-specific context and input

Declare state schemas through `setup({ states })`. Use state context for data whose validity depends on the active state:

```ts
const flow = setup({
  states: {
    Failed: {
      schemas: {
        context: standard(Schema.Struct({ message: Schema.NonEmptyString })),
      },
    },
    Succeeded: {
      schemas: {
        context: standard(Schema.Struct({ receiptId: Schema.String })),
      },
    },
  },
  schemas: {
    events: {
      failed: standard(Schema.Struct({ message: Schema.NonEmptyString })),
      succeeded: standard(Schema.Struct({ receiptId: Schema.String })),
    },
  },
}).createMachine({
  initial: "Pending",
  states: {
    Pending: {
      on: {
        failed: ({ event }) => ({
          target: "Failed",
          context: { message: event.message },
        }),
        succeeded: ({ event }) => ({
          target: "Succeeded",
          context: { receiptId: event.receiptId },
        }),
      },
    },
    Failed: {},
    Succeeded: {},
  },
});
```

After `snapshot.matches("Failed")`, the context narrows to the failed-state shape. This avoids root fields such as `message?: string` or `message: string | null` that can become stale.

State `input` is different from context and action params. Declare `schemas.input` on a state in `setup`, then pass `input` when targeting it or with `initial: { target, input }`. Use it for data delivered at state entry.

## Commands from the machine

For an Effect-owned interpreter, model outgoing work as emitted commands:

```ts
const machine = setup({
  schemas: {
    events: {
      load: standard(Schema.Struct({ userId: Schema.String })),
    },
    emitted: {
      loadUser: standard(Schema.Struct({ userId: Schema.String })),
    },
  },
}).createMachine({
  on: {
    load: ({ event }, enq) => {
      enq.emit({ type: "loadUser", userId: event.userId });
      return { target: ".Loading" };
    },
  },
});
```

Why emitted commands are a strong boundary:

- the command has a stable discriminator and typed payload
- pure transitions return it as data in executable effects
- Effect can decode and interpret it without running arbitrary callbacks
- tests can assert the command without constructing services

Use `enq.raise` for machine-internal events. Use `enq.sendTo` only when actor addressing is part of the chosen runtime design.

Avoid `enq(() => performIo())` in Effect-owned mode. That captures an arbitrary callback in a custom executable action and bypasses Effect requirements and typed failures.

Pure transitions, executable effect kinds, `createAsyncLogic`, and XState-owned actor guidance are in [`xstate-runtime-boundaries.md`](./xstate-runtime-boundaries.md).
