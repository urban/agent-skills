# Inbound contracts

A first-party API contract should own:

- method and path
- params, query, headers, and payload schemas
- success schema and status
- expected error schemas and statuses
- alternate encodings such as text, multipart, or streaming

Keep the contract module shareable by client and server. Handler code receives decoded input, resolves the domain capability, invokes it, and returns the typed result. Domain validation should not be duplicated in handlers.

Use custom structured errors when clients need fields. Use ordinary protocol errors when status alone is sufficient. Put status/encoding metadata on the schema or group contract rather than rebuilding responses in every handler.

A defect boundary may translate unexpected faults to an opaque public 500 while retaining full internal telemetry. Do not add a generic internal error to every domain service merely because HTTP needs a safe response.
