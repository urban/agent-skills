# Mocking Boundaries in Effect

Mock only true boundaries outside your control, and do it with `Layer`.

## Good places to mock

- External APIs and third-party SaaS systems.
- Database, network, and filesystem boundaries.
- Time and randomness (use `TestClock`, deterministic services).

## Avoid mocking

- Internal domain behavior that can be tested through public Effect APIs.
- Private/internal helper functions and call choreography.
- Services owned by your module when real in-memory implementations are cheap.

## Design for easy boundary mocks

1. Model boundaries as focused `ServiceMap.Service` contracts.
2. Provide test implementations with `Layer.succeed` or `Layer.effect`.
3. Assert on public outcomes (`Success` / tagged `Error`), not collaborator call counts.

Example:

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Layer, ServiceMap } from "effect";

type Order = { readonly id: string; readonly totalCents: number };

class Payments extends ServiceMap.Service<
  Payments,
  {
    readonly charge: (amountCents: number) => Effect.Effect<{ readonly id: string }>;
  }
>()("dotai/tdd/Payments") {}

const placeOrder = Effect.fn("placeOrder")(function* (order: Order) {
  const payments = yield* Payments;
  const charge = yield* payments.charge(order.totalCents);
  return { orderId: order.id, chargeId: charge.id };
});

it.effect("returns confirmation for valid order", () =>
  Effect.gen(function* () {
    const result = yield* placeOrder({ id: "order-1", totalCents: 2500 }).pipe(
      Effect.provide(
        Layer.succeed(Payments, {
          charge: () => Effect.succeed({ id: "charge-123" }),
        }),
      ),
    );

    assert.deepStrictEqual(result, { orderId: "order-1", chargeId: "charge-123" });
  }),
);
```

This keeps tests stable across refactors because they assert behavior, not internals.
