# Decorator Escaping

Use these examples when JSDoc text or examples include decorators like `@Injectable()`.

## Example: Decorator mention in prose

```typescript
/**
 * Queue worker for invoice events.
 * @description Handles jobs emitted by `@Processor("invoice-events")`.
 * @remarks Uses `@Injectable()` lifecycle from NestJS.
 */
export class InvoiceEventsProcessor {}
```

## Example: Decorators inside @example blocks

````typescript
/**
 * Creates a queue worker.
 * @example
 * ```typescript
 * \@Processor("invoice-events")
 * export class InvoiceEventsProcessor {
 *   \@Process()
 *   async handle(job: Job): Promise<void> {
 *     // ...
 *   }
 * }
 * ```
 */
export function buildProcessorDocs(): void {
  // Example container only
}
````
