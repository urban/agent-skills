# HTTP testing

Choose fidelity from the behavior:

| Behavior | Boundary |
| --- | --- |
| Handler/domain mapping and contract decode | Handler-backed typed client |
| Routing, middleware, headers, cookies, encoding | In-process Effect server |
| Outbound request construction and status mapping | Provided fake/handler HttpClient |
| Runtime TLS/proxy/deployment integration | Explicit smoke test |

Keep the application on its real HTTP abstraction; do not patch global transport state. Assert method, path, relevant headers, encoded body, decoded result, meaningful non-success bodies, and cancellation/cleanup where applicable.

Drive retries, timeout, and rate limiting with logical time after the request fiber reaches the scheduled boundary.
