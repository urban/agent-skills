# Class Documentation

Use this file for class-level intent, factory methods, and method contract docs.

## Example: API client class

```typescript
/**
 * Client for HTTP requests against the billing API.
 * @remarks Handles auth headers, retries, and normalized error mapping.
 */
export class BillingApiClient {
  /**
   * Creates a configured client instance.
   * @param config - Transport and authentication settings.
   * @returns Ready-to-use API client.
   */
  static create(config: BillingClientConfig): BillingApiClient {
    return new BillingApiClient(config);
  }

  /** @internal */
  private constructor(private readonly config: BillingClientConfig) {}

  /**
   * Fetches an invoice by identifier.
   * @param invoiceId - External invoice ID.
   * @returns Invoice payload.
   * @throws {ApiError} When the invoice cannot be fetched.
   */
  async getInvoice(invoiceId: string): Promise<Invoice> {
    return this.request<Invoice>(`/invoices/${invoiceId}`);
  }

  /** @internal */
  private async request<T>(path: string): Promise<T> {
    const response = await fetch(`${this.config.baseUrl}${path}`);

    if (!response.ok) {
      throw new ApiError(`Request failed with status ${response.status}`);
    }

    return response.json() as Promise<T>;
  }
}
```
