# Test Quality

Use these checks to keep Effect tests behavior-first and resilient to refactors.

## Strong behavior tests

A strong behavior test:

- Verifies user- or caller-visible outcomes from a public Effect API.
- Uses `it.effect` + `Effect.gen` (no `Effect.runSync` test wrappers).
- Mocks only external boundaries via `Layer`, not internal modules.
- Uses typed errors and `catchTag` assertions for failure paths.
- Survives internal refactors that preserve behavior.

Example:

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Layer } from "effect";

it.effect("checkout confirms a valid cart", () =>
  Effect.gen(function* () {
    const cart = createCart([product("sku-1", 2000)]);

    const result = yield* checkout(cart).pipe(
      Effect.provide(
        Layer.succeed(Payments, {
          charge: () => Effect.succeed({ id: "ch_123" }),
        }),
      ),
    );

    assert.strictEqual(result.status, "confirmed");
  }),
);
```

## Weak implementation-coupled tests

A weak implementation-coupled test usually:

- Verifies internal collaborator calls, ordering, or private helpers.
- Spies on module internals instead of asserting returned behavior.
- Breaks during harmless internal restructuring.

Example:

```ts
it("checkout calls authorizePayment once", async () => {
  const spy = vi.spyOn(orderWorkflow, "authorizePayment");

  await runCheckoutImperative(cart);

  expect(spy).toHaveBeenCalledTimes(1);
});
```

## Quick heuristic

Ask: "If internals change but behavior stays the same, should this test still pass?"

- If `yes`, test design is likely healthy.
- If `no`, move assertions to behavior at the public interface.
- If timing is involved, use `TestClock` to make the behavior deterministic.
