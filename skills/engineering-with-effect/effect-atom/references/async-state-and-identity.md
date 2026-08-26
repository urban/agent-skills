# Async state and identity

An async atom represents lifecycle:

- Initial: no completed value yet
- Success: completed value, possibly waiting during refresh
- Failure: cause, possibly with retained policy-dependent data elsewhere

Do not substitute an empty domain value for Initial or Failure.

Use a family when state depends on input. Include every field that changes cache identity: tenant, user, entity, scope, mode, locale, filter, or provider. Structural keys avoid accidental referential misses for compound identity.

Choose lifetime:

- mounted/subscribed lifetime for ordinary state
- idle TTL for reusable remote cache
- keep-alive for intentional application-lifetime state

Define refresh and window-focus policy beside the query atom so all consumers share it.
