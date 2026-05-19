# Effect `HTTP` patterns for agents — part 3

Covers:

- Test with HTTP layers, not global mocks
- Keep client transforms close to typed clients
- Error handling patterns

---

### Test with HTTP layers, not global mocks

Effect's own tests use `NodeHttpServer.layerTest`, `HttpRouter.serve`, `HttpServer.serve`, and `HttpApiTest.groups`. A useful wrapper can build a scoped test server, expose a `baseUrl`, and return a `Layer.succeed(HttpClient.HttpClient, client)` for callers.

```ts
import * as NodeHttpServer from "@effect/platform-node/NodeHttpServer";
import { Context, Effect, Layer, Predicate, Schema, Scope } from "effect";
import { HttpClient, HttpRouter, HttpServer, HttpServerResponse } from "effect/unstable/http";

export class TestServerAddressError extends Schema.TaggedErrorClass<TestServerAddressError>()(
  "TestServerAddressError",
  { address: Schema.Defect },
) {}

export interface TestHttpServer {
  readonly baseUrl: string;
  readonly httpClientLayer: Layer.Layer<HttpClient.HttpClient>;
  readonly url: (path?: string) => string;
}

export const serveRoutes = (
  routes: readonly HttpRouter.Route<never, never>[],
): Effect.Effect<TestHttpServer, TestServerAddressError, Scope.Scope> =>
  Effect.gen(function* () {
    const context = yield* Layer.build(
      Layer.fresh(
        HttpRouter.serve(HttpRouter.addAll(routes), {
          disableListenLog: true,
          disableLogger: true,
        }).pipe(Layer.provideMerge(NodeHttpServer.layerTest)),
      ),
    );

    const server = Context.get(context, HttpServer.HttpServer);
    const address = server.address;
    if (!Predicate.isTagged(address, "TcpAddress")) {
      return yield* new TestServerAddressError(address);
    }

    const client = Context.get(context, HttpClient.HttpClient);
    const baseUrl = `http://127.0.0.1:${address.port}`;

    return {
      baseUrl,
      httpClientLayer: Layer.succeed(HttpClient.HttpClient, client),
      url: (path = "") => new URL(path, baseUrl).toString(),
    };
  });

export const okRoute = HttpRouter.route(
  "GET",
  "/health",
  Effect.succeed(HttpServerResponse.text("ok")),
);
```

Guidelines:

- Prefer real Effect HTTP servers for integration tests. They exercise routing, request encoding, response decoding, status handling, cookies, and middleware.
- Use `Layer.fresh` for scoped test servers so each test gets a clean port and lifecycle.
- Use `HttpApiTest.groups` for handler-level tests that should bypass the socket but still use the `HttpApi` contract.
- Disable listen and request logging in tests with `{ disableListenLog: true, disableLogger: true }`.
- Use `TestClock` for retry, timeout, and rate-limit tests. Effect's HTTP client tests advance logical time instead of sleeping.

### Keep client transforms close to typed clients

Effect docs use generated clients with request transforms for base URLs and auth.

```ts
import { Context, Effect, flow, Layer } from "effect";
import { FetchHttpClient, HttpClient, HttpClientRequest } from "effect/unstable/http";
import { HttpApiClient } from "effect/unstable/httpapi";

import { AssessmentApi } from "./AssessmentApi";

export class AssessmentApiClient extends Context.Service<
  AssessmentApiClient,
  HttpApiClient.ForApi<typeof AssessmentApi>
>()("fiberisle/AssessmentApiClient") {
  static readonly layer = (baseUrl: string): Layer.Layer<AssessmentApiClient> =>
    Layer.effect(
      AssessmentApiClient,
      HttpApiClient.make(AssessmentApi, {
        transformClient: (client) =>
          client.pipe(
            HttpClient.mapRequest(flow(HttpClientRequest.prependUrl(baseUrl))),
            HttpClient.retryTransient({ retryOn: "errors-only", times: 2 }),
          ),
      }),
    ).pipe(Layer.provide(FetchHttpClient.layer));
}
```

Guidelines:

- Use `baseUrl` or `transformClient` instead of hand-building URLs at every call site.
- Use `HttpApiMiddleware.layerClient` for auth or other middleware declared by the API contract.
- Keep generated clients inside services when many callers use the same remote API.

## Error handling patterns
