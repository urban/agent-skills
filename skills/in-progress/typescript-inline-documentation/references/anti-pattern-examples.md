# Anti-Pattern Examples

Use these examples to identify low-value documentation and replace it with useful contract details.

## Anti-pattern: Duplicate type information

Bad:

```typescript
/**
 * @param id - {string} User id
 * @returns {Promise<User>} User
 */
export async function getUser(id: string): Promise<User> {
  return repo.getUser(id);
}
```

Better:

```typescript
/**
 * Loads a user record for profile rendering.
 * @param id - Stable UUID from the identity provider.
 * @returns Active user record.
 */
export async function getUser(id: string): Promise<User> {
  return repo.getUser(id);
}
```

## Anti-pattern: Obvious summaries

Bad:

```typescript
/**
 * Sets the timeout value.
 */
export function setTimeoutMs(timeoutMs: number): void {
  config.timeoutMs = timeoutMs;
}
```

Better:

```typescript
/**
 * Updates request timeout for downstream API calls.
 * @param timeoutMs - Timeout in milliseconds; values below `100` are rejected.
 * @remarks Lower values can cause false-negative network failures in staging.
 */
export function setTimeoutMs(timeoutMs: number): void {
  config.timeoutMs = timeoutMs;
}
```
