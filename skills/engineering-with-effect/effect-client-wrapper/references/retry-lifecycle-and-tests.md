# Retry, lifecycle, and tests

Retry only known transient failures. Bound exponential backoff and attempts, honor provider retry hints within limits, and require operation idempotency for mutation retries. Provider idempotency keys should derive from the logical operation.

Add a span when one SDK call is an operator-useful boundary. Do not include credentials, payloads, recipient data, or unbounded provider messages by default.

If a client needs close, flush, or shutdown, acquire/release it in the layer scope. Choose whether release failure is logged, combined with primary failure, or surfaced at shutdown based on risk of data loss.

Test the low-level adapter with a scripted client when constructor, rejection, retry, decoding, or cleanup matters. Test domain consumers with the narrow service fake. Assert retry classification, attempt bound, no retry for unsafe operations, redaction, and cleanup after interruption.
