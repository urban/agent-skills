# Adapter boundary

Prefer named domain methods when callers benefit from stable product vocabulary and normalized responses. Keep a generic escape hatch for very large SDKs or low-level adapter modules.

A generic operation descriptor should contain one object with:

- stable operation name
- callback that receives the private client
- safe low-cardinality telemetry metadata

Construct the client from redacted configuration in the layer. Separate construction/configuration errors from request errors if the application treats startup failure differently from one failed operation.

Wrap Promise rejection once at the adapter. Preserve opaque cause and safe provider codes/status/request IDs needed for diagnosis or retry classification. Higher-level domain services may translate that adapter error further.
