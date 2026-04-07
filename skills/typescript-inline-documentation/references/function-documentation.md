# Function Documentation

Use these examples for sync, async, generic, and overload function docs.

## Example: Basic function

```typescript
/**
 * Calculates total price including tax.
 * @param price - Base amount before tax.
 * @param taxRate - Tax rate as a decimal (for example `0.08` for 8%).
 * @returns Total amount including tax.
 */
export function calculateTotal(price: number, taxRate: number): number {
  return price * (1 + taxRate);
}
```

## Example: Async function with throws

````typescript
/**
 * Fetches a user profile from the API.
 * @param userId - Stable user identifier.
 * @returns Parsed user payload.
 * @throws {NotFoundError} When the user does not exist.
 * @throws {NetworkError} When the request fails or times out.
 * @example
 * ```typescript
 * const user = await fetchUser("user-123");
 * console.log(user.name);
 * ```
 */
export async function fetchUser(userId: string): Promise<User> {
  const response = await fetch(`/api/users/${userId}`);

  if (response.status === 404) {
    throw new NotFoundError(`User ${userId} not found`);
  }

  if (!response.ok) {
    throw new NetworkError("Failed to fetch user");
  }

  return response.json();
}
````

## Example: Generic function

```typescript
/**
 * Filters an array with a type-safe predicate.
 * @typeParam T - Element type of the input array.
 * @param array - Source array.
 * @param predicate - Selector function returning `true` for included items.
 * @returns New array containing only matching items.
 */
export function filterArray<T>(
  array: ReadonlyArray<T>,
  predicate: (item: T, index: number) => boolean,
): Array<T> {
  return array.filter(predicate);
}
```

## Example: Overloaded function

```typescript
/**
 * Formats numeric output using default rules.
 * @param value - Numeric value to format.
 * @returns Formatted string.
 */
export function format(value: number): string;

/**
 * Formats numeric output using a named format strategy.
 * @param value - Numeric value to format.
 * @param formatStr - Strategy key, such as `currency` or `percent`.
 * @returns Formatted string.
 */
export function format(value: number, formatStr: "currency" | "percent"): string;

/** @internal */
export function format(value: number, formatStr?: "currency" | "percent"): string {
  if (formatStr === "currency") {
    return `$${value.toFixed(2)}`;
  }

  if (formatStr === "percent") {
    return `${(value * 100).toFixed(1)}%`;
  }

  return value.toString();
}
```
