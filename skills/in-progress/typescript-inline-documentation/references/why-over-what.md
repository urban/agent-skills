# Why Over What

Use these examples to replace low-value comments with high-value rationale.

## Example: Function intent

Bad:

```typescript
/**
 * Gets user by ID.
 * @param id - The ID.
 * @returns The user.
 */
export function getUserById(id: string): User {
  return userStore[id];
}
```

Good:

```typescript
/**
 * Retrieves a user by UUID from the cached read model.
 * @param id - Stable UUID from the v2 identity provider.
 * @returns The active user, or `null` when not found or soft-deleted.
 * @remarks This keeps lookup semantics aligned with GraphQL resolvers that treat
 * missing and soft-deleted users identically.
 */
export function getUserById(id: string): User | null {
  return userStore[id] ?? null;
}
```

## Example: Inline rationale comment

Bad:

```typescript
// Loops through users and filters active users.
const activeUsers = users.filter((u) => u.active);
```

Good:

```typescript
// Active users are filtered first to avoid expensive permission checks on inactive accounts.
const activeUsers = users.filter((u) => u.active);
```
