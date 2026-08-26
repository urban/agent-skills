# Exporters and testing

Choose Effect-native OTLP exporters for direct OTLP with Effect services. Choose the OpenTelemetry SDK bridge when existing processors, exporters, propagation, resources, or platform integration are required.

Exporter layers own background loops, provider lifetime, flush, and shutdown. Align lifetime with callbacks that may emit telemetry; request scope is too short when callbacks outlive requests.

Exporter failures normally degrade observability rather than business behavior. Bound retries and avoid recursive tracing of exporter traffic.

Test spans with a public fake tracer seam when available. Test exporters with a fake Effect HTTP client and logical time. Assert names, safe attributes, status/cause, encoded request, retry-after behavior where relevant, final flush, and shutdown.
