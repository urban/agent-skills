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

Translate lower-level errors where the capability's meaning is known, not mechanically at every internal call. Preserve a safe cause or diagnostic detail when operators need root-cause evidence. Do not expose every provider status or errno unless the service is intentionally low-level.

Typed operation failures are not a promise that every possible failure has been normalized. `Effect.mapError` transforms typed failures, not defects or interruption. Adapt expected SDK throws or rejections into typed failures at the integration boundary; do not catch every cause and relabel programming bugs or cancellation as an ordinary unavailable result. Startup acquisition failures belong to construction; an operation's public error family describes attempts made after construction.

Prefer a small fixed family of public failures over messages assembled from database rows, filesystem paths, provider payloads, or other untrusted values. Include an observed external value only when a caller needs it to choose an action and the contract defines an appropriate sensitivity, size, and rendering policy. Otherwise keep it in bounded, safe operator diagnostics rather than the public failure.

Keep two low-level distinctions separate only when callers behave differently. Conversely, do not collapse absence, malformed data, permission denial, conflict, and unavailability when they imply different decisions. A separate query or adapter operation is justified when it preserves one of those caller-visible distinctions; merge it only as an explicit contract change.

## Named fallback semantics

Recover from not-found with an empty initial draft only if absence means “not created yet” in the product contract. Permission denial, malformed content, or storage outage must not look like a new document that is safe to overwrite.

```ts
import { Data, Effect } from "effect"

class DraftNotFound extends Data.TaggedError("DraftNotFound") {}
class DraftUnavailable extends Data.TaggedError("DraftUnavailable") {}
class DraftMalformed extends Data.TaggedError("DraftMalformed") {}

const loadInitialDraft = (
  read: Effect.Effect<string, DraftNotFound | DraftUnavailable | DraftMalformed>,
) => read.pipe(
  Effect.catchTag("DraftNotFound", () => Effect.succeed("")),
)
```

The unavailable and malformed cases remain failures; a single catch-all returning an empty string would erase the distinction that protects existing user data.

## Source anchors (Effect v4)

- `packages/effect/src/Effect.ts`: `mapError`, `catchTag`, `catchDefect`, and `tryPromise`.
- `packages/effect/test/Effect.test.ts`: `catchTag`, `tryPromise`, and mixed-cause mapping / recovery tests.
- `packages/effect/src/Layer.ts`: `effect` preserves construction errors separately from the service value.
