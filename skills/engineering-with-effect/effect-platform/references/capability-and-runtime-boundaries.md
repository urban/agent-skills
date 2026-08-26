# Capability and runtime boundaries

## Capture or expose requirements

Capture platform requirements in service construction when files, paths, crypto, or processes are implementation details of a domain capability. Leave requirements explicit when the function is intentionally reusable across runtimes and platform providers.

## Runtime edges

Domain code depends on portable Effect capabilities. One infrastructure module or entrypoint selects Node, Bun, browser, Worker, or another adapter set. Dynamic selection is appropriate only when one deployed artifact truly supports multiple runtimes.

## Public surface

Expose domain operations rather than low-level handles. A raw handle is appropriate only when the capability itself is process control, random access, terminal control, or another lifecycle-owning primitive.
