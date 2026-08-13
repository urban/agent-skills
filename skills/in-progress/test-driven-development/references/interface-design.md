# Interface Design for Effect Testability

Prefer interfaces that make behavior tests straightforward through public Effect APIs.

## Guidelines

1. Define reusable effectful operations with `Effect.fn("name")`, not ad-hoc `Promise` helpers.
2. Inject collaborators through `ServiceMap.Service` + `Layer`, never by constructing dependencies inside business logic.
3. Return domain values with `Effect.Effect<Success, Error, Requirements>` and typed errors.
4. Keep service interfaces small and intention-revealing (few focused methods over one generic method).
5. Use `return yield*` for terminal failures so control flow stays explicit in `Effect.gen`.

## Example

```ts
import { Effect, Layer, Schema, ServiceMap } from "effect";

type Invoice = {
  readonly id: string;
  readonly items: ReadonlyArray<{ readonly amountCents: number }>;
};

export class InvalidInvoiceError extends Schema.TaggedErrorClass<InvalidInvoiceError>()(
  "InvalidInvoiceError",
  { message: Schema.String },
) {}

export class TaxRules extends ServiceMap.Service<
  TaxRules,
  {
    readonly forInvoice: (
      invoice: Invoice,
    ) => Effect.Effect<{ readonly compute: (subtotalCents: number) => Effect.Effect<number> }>;
  }
>()("dotai/tdd/TaxRules") {}

export const calculateInvoiceTotal = Effect.fn("calculateInvoiceTotal")(function* (
  invoice: Invoice,
) {
  if (invoice.items.length === 0) {
    return yield* new InvalidInvoiceError({ message: "Invoice must have at least one item" });
  }

  const taxRules = yield* TaxRules;
  const subtotalCents = invoice.items.reduce((sum, item) => sum + item.amountCents, 0);
  const rule = yield* taxRules.forInvoice(invoice);
  const taxCents = yield* rule.compute(subtotalCents);

  return {
    subtotalCents,
    taxCents,
    totalCents: subtotalCents + taxCents,
  };
});

// Tests can provide TaxRules with Layer.succeed(TaxRules, { ... })
export const TaxRulesTest = Layer.succeed(TaxRules, {
  forInvoice: () =>
    Effect.succeed({ compute: (subtotalCents) => Effect.succeed(Math.floor(subtotalCents * 0.1)) }),
});
```

This keeps assertions focused on observable behavior while making dependency wiring explicit and replaceable in tests.
