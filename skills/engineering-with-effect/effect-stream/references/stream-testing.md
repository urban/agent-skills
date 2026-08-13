# Stream testing

- Bound long-lived streams with count, condition, timeout policy, or a finite sink before collecting.
- Coordinate producer and consumer readiness with Deferred or Queue rather than sleeps.
- Use logical time for debounce, throttle, retry, repeat, grouped-within, and scheduled polling.
- Test callback cleanup by starting consumption in a scoped fiber, interrupting it, and asserting unregistration/release.
- Test buffer policy at capacity: suspension, drop, sliding, or failure should be observable.
- Test framing across adversarial chunk boundaries, including split UTF-8 code points and partial JSON/SSE frames.
- If reconnect can duplicate output, test sequence/deduplication semantics explicitly.
