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

A fallback is meaningful only for a named failure class. For example, recover from not-found with an empty initial document if that is the product contract; do not also hide malformed data, permission denial, or storage outage behind that fallback.
