# HTTP testing

Choose fidelity from the behavior:

| Behavior | Boundary |
| --- | --- |
| Contract round trips, handler mapping, API middleware, routing, headers/cookies, body encoding | `HttpApiTest.groups(api, ["group"])` |
| Outbound request construction, status/body mapping, retry decisions | Provided `HttpClient.make` fake with `HttpClientResponse.fromWeb` responses |
| Public error rendering, runtime aborts, socket cleanup, unread-body draining | Local server and real runtime client |
| TLS/proxy/deployment integration | Explicit environment integration test |

`HttpApiTest.groups` builds an in-memory generated client through the builder/router pipeline; it is not a direct handler invocation. Provide selected group implementations, middleware, HTTP platform services, and an owning Scope. Unselected groups are wired to fail if called. It does not start a listening server or emulate socket aborts/draining/499 responses. For Node transport tests, `NodeHttpServer.layerTest` supplies a local test server/client; serve the real router with `HttpRouter.serve`.

Keep the application on its real HTTP abstraction instead of patching global fetch. Assert the wire method/path/headers/body at the fake boundary and caller-visible results at the protocol-service boundary. Important cases include a meaningful conflict body, malformed success content, declared error decoding, and middleware rejection before a domain side effect. A generated client encodes valid input, so send malformed raw requests when testing rejection of invalid wire data.

## Retry outcomes and logical time

An exhausted response retry is not inherently a failed effect. This focused test makes that distinction explicit; protocol-service tests should additionally assert the domain failure produced from the final status:

```ts
import { assert, it } from "@effect/vitest"
import { Effect, Ref } from "effect"
import { HttpClient, HttpClientResponse } from "effect/http"

it.effect("returns the final 503 after bounded response retries", () =>
  Effect.gen(function*() {
    const attempts = yield* Ref.make(0)
    const client = HttpClient.make((request) =>
      Effect.gen(function*() {
        yield* Ref.update(attempts, (n) => n + 1)
        return HttpClientResponse.fromWeb(request, new Response(null, { status: 503 }))
      })
    ).pipe(HttpClient.retryTransient({ retryOn: "response-only", times: 2 }))

    const response = yield* client.get("http://test/")
    assert.strictEqual(response.status, 503)
    assert.strictEqual(yield* Ref.get(attempts), 3)
  }))
```

For delays and deadlines, fork the operation and synchronize on the attempted request or scheduled boundary before advancing `TestClock`. Assert that no attempt happens just before the boundary and that one happens at it. Cover `Retry-After` overriding a shorter schedule, non-retryable statuses, write replay safety, and cancellation during backoff. Include an overall-deadline case rather than testing only the number of attempts.

## Streaming ownership

Test incremental delivery, not just collected equality. Gate production of the next payload element on the handler observing the previous one; this detects accidental buffering. `HttpApiTest` forwards streaming payloads unbuffered and keeps handler resources alive until a streaming response ends or the client's owning Scope closes.

Attach a finalizer to a handler resource and assert it is open after the client call, usable during consumption, and closed after completion or owning-scope closure. For actual transport cancellation, consume only part of a response and assert cleanup using the runtime client/server, since the in-memory test does not emulate disconnects. Test source/body-read failures separately from valid stream elements that fail schema decoding.
