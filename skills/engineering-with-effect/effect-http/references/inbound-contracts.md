# Inbound contracts

A first-party API contract should own method/path, request schemas, success/error schemas and statuses, and body encodings. Keep the contract module shareable by client, server, and OpenAPI generation; do not import runtime transports or domain implementations into it.

Handlers adapt decoded input to domain capabilities. Keep structural validation in schemas and business invariants in domain services, rather than repeating either in each handler.

## Status and body meaning

Declare structured errors when clients need fields; use status-only errors when the status is the whole contract. Attach status/encoding to schemas rather than rebuilding responses in every handler:

```ts
import { Schema } from "effect"
import { HttpApi, HttpApiEndpoint, HttpApiGroup, HttpApiSchema } from "effect/http-api"

const Ticket = Schema.Struct({ id: Schema.String, subject: Schema.String })
const TicketMissing = Schema.TaggedStruct("TicketMissing", {
  id: Schema.String
}).pipe(HttpApiSchema.status(404))

export const SupportApi = HttpApi.make("Support").add(
  HttpApiGroup.make("tickets").add(
    HttpApiEndpoint.get("find", "/tickets/:id", {
      params: Schema.Struct({ id: Schema.String }),
      success: Ticket,
      error: TicketMissing
    })
  )
)
```

Here a missing ticket is a declared failure with an identifying body, not a successful nullable ticket or a generic transport error. The generated client decodes that 404 into the declared failure. Do not put `HttpClient.filterStatusOk` underneath that client: it fails before this dispatch can run. The resulting `HttpClientError` still retains its response, but normal contract decoding has been bypassed.

For deliberately empty error responses, use a no-content schema such as `HttpApiError.NotFoundNoContent`. Returning a built-in respondable error directly can render an empty body; that is not interchangeable with declaring a JSON error schema and expecting clients to decode JSON.

## Middleware and unexpected failures

- Put authentication, authorization, and request-scoped capabilities in API middleware when they belong to the endpoint contract; declare middleware error schemas there so clients and documentation see them.
- Client middleware decorates outgoing requests; it does not enforce server authorization. Keep actual access decisions on the server and domain-specific authorization close to the capability it protects.
- Keep transport-wide concerns such as CORS or deployment adapters outside domain handlers. Middleware placement and ordering are observable: test denied requests as well as successful ones.
- Distinguish malformed input from a broken response encoder. `HttpApiSchemaError` renders request decoding failures as empty 400 responses, but response body/header encoding failures as empty 500 responses. Do not turn both into a domain validation error.
- The in-memory pipeline can surface these schema failures as defects rather than rendered responses. Use a serving boundary when testing public error rendering.

A defect boundary may translate unexpected faults to an opaque public 500 while retaining internal telemetry. Do not add a generic internal error to every domain service merely because HTTP needs a safe response. Once a streaming response has begun, a later failure cannot generally replace its status: choose framing with an in-band failure representation when the protocol needs one.
