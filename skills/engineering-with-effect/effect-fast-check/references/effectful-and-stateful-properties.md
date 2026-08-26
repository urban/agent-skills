# Effectful and stateful properties

Use Effect-aware properties when the predicate needs services, typed errors, TestClock, fibers, refs, queues, streams, or scoped resources. Build fresh mutable state for every generated case.

Assert typed rejection by generating a deliberate invalid class, invoking the public boundary, and checking the caller-visible error reason.

For stateful systems, generate command sequences, run them against both a simple model and the real service, and compare observable results after each command. Keep commands small enough to shrink to the minimal failing transition.

Replace network, model provider, process, random, and clock capabilities. Expensive properties should use a lower run count plus focused generators rather than live integration.
