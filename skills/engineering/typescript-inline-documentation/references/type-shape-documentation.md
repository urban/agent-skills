# Type Shape Documentation

Use this file for interface, type alias, and property patterns.

## Example: Interface and property docs

```typescript
/**
 * Represents a user profile returned by account services.
 */
export interface UserProfile {
  /** Stable identifier for the user record. */
  id: string;

  /** Public display name shown in the UI. */
  displayName: string;

  /** Preferred locale used for formatting and translations. */
  locale: string;

  /** Optional avatar URL if user uploaded an image. */
  avatarUrl?: string;
}
```

## Example: Type alias with type parameters

```typescript
/**
 * Result type for operations that can fail.
 * @typeParam T - Success value type.
 * @typeParam E - Error value type.
 */
export type Result<T, E = Error> = { success: true; data: T } | { success: false; error: E };
```
