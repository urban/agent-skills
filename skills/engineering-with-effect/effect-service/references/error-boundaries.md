# Service error boundaries

Model expected failures from caller decisions, not dependency vocabulary.

| Caller decision | Useful distinction |
| --- | --- |
| Ask for different input | invalid input / unsupported value |
| Render absence | not found |
| Resolve concurrency | conflict / already exists |
| Retry later | unavailable / rate limited / timed out, with retry metadata when useful |
| Re-authenticate or request access | unauthenticated / forbidden |
| Stop and report an invariant breach | defect, not a generic expected error |

Translate lower-level errors once at the service boundary. Preserve a safe cause or diagnostic detail when operators need root-cause evidence. Do not expose every provider status or errno unless the service is intentionally low-level.

Prefer a small fixed family of public failures over messages assembled from database rows, filesystem paths, provider payloads, or other untrusted values. Include an observed external value only when a caller needs it to choose an action and the contract defines an appropriate sensitivity, size, and rendering policy. Otherwise keep it in bounded, safe operator diagnostics rather than the public failure.

Keep two low-level distinctions separate only when callers behave differently. Conversely, do not collapse absence, malformed data, permission denial, conflict, and unavailability when they imply different decisions. A separate query or adapter operation is justified when it preserves one of those caller-visible distinctions; merge it only as an explicit contract change.

When replacing dynamic diagnostic failures with fixed variants makes sanitizers, text encoders, byte measurement, or similar machinery unused, remove that obsolete machinery with the change rather than preserving a second error path.

A fallback is meaningful only for a named failure class. For example, recover from not-found with an empty initial document if that is the product contract; do not also hide malformed data, permission denial, or storage outage behind that fallback.
