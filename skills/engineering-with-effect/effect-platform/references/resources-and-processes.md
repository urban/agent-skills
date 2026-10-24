# Resources and processes

## Scoped ownership

Keep acquisition and use under the same lifetime owner. `FileSystem.open`, scoped temp helpers, and `ChildProcessSpawner.spawn` register release with the acquisition scope. A service that owns a long-lived resource should acquire it in its layer's scope; a per-operation resource belongs to the operation's scope. Do not hide a short local scope around acquisition and return the handle.

A lazy stream must acquire its resources when consumed or retain an explicitly shared owner. Returning a stream over an already-closed file or process handle does not extend that handle's lifetime. Apply the same ownership reasoning to socket reader/writer acquisition and server layers.

Use `makeTempDirectoryScoped` / `makeTempFileScoped` for transient work. Non-scoped temp creation is appropriate only when a separate owner intentionally manages retention and removal. A path string conveys no cleanup ownership.

## Processes

Use `ChildProcess` to describe the command and `ChildProcessSpawner` to run it. Prefer executable plus argument values over shell interpolation; enable shell behavior only when shell interpretation is intentional and input is controlled.

### Output and completion are different contracts

- With a raw handle, consume piped stdout and stderr concurrently. If input is incremental, feed stdin concurrently too; an interactive child can block waiting for input while the parent waits for output.
- The spawner's output helpers already drain stderr when returning stdout; `exitCode` drains both until process exit. Do not add a second consumer of those same pipes.
- `handle.all` interleaves stdout and stderr. Choose either `all` or separate consumers; consuming both competes for the same output and loses reliable attribution.
- `string` and `lines` collect the whole output. Use streaming, redirection, or an explicit output-limit failure for untrusted or potentially large output; a timeout is not a memory bound.
- A numeric non-zero exit is a successful `exitCode` result, not automatically an Effect failure. Output helpers collect output without checking that status. When command success matters, own one raw handle, consume output while awaiting its exit, and map the status into a domain result. Do not run the command again just to obtain its exit code.
- Keep spawn failure, I/O failure, non-zero status, signal termination, timeout, and output-limit failure distinct when callers react differently. An external tool rejecting input is not inherently a program defect.

### Termination policy

A scope owns normal child cleanup, but scoped does not mean instant or infallible cleanup. In the Node adapter, termination defaults to SIGTERM; without `forceKillAfter`, waiting for the leader has no time limit. Configure escalation when an operation needs bounded shutdown. Its duration is not a strict total deadline: Node can wait again after SIGKILL, and cleanup varies by OS.

Node's default detached process group on POSIX permits descendant cleanup. `detached: false` changes that ownership; on Windows, descendants that outlive the leader cannot be assumed cleaned up. Test the process-tree behavior the deployment requires rather than promising identical semantics across hosts.

`handle.unref` is an explicit lifetime escape, not a cleanup primitive. In the Node adapter, a still-running unreferenced child is not terminated by normal scope release; the returned effect restores its reference. Use this only for an intentionally independent process with a separate owner, not to make tests or shutdown finish faster.
