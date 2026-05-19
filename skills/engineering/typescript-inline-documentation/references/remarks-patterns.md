# Remarks Patterns

Use `@remarks` to document decisions, caveats, and integration constraints.

## Example: Class-level remarks

```typescript
/**
 * Queue processor for reconciliation jobs.
 * @remarks
 * - Jobs are idempotent and may be retried by the worker.
 * - Ordering is not guaranteed across partitions.
 * - Uses dead-letter queue after 5 failed attempts.
 */
export class ReconciliationProcessor {}
```

## Example: Method-level remark

```typescript
/**
 * Creates DataLoader instances for one GraphQL request.
 * @returns Request-scoped loaders.
 * @remarks Must be called once per request to prevent cross-user cache leakage.
 */
export function createLoaders(): Loaders {
  return {
    users: new DataLoader(loadUsersById),
  };
}
```
