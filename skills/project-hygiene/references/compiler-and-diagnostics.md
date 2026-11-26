# Compiler and diagnostics

## Policy follows the project contract

Inspect the language and tool versions, supported runtimes, package and build boundaries, and existing diagnostics before changing policy. Choose supported checks that expose consequential mistakes without requiring an unrelated migration. A compiled language may use compiler flags; an interpreted language may rely on static analyzers, import checks, or runtime validation.

For legacy code, scope stricter checks to a package, directory, or newly maintained surface when tooling permits. Do not conceal defects with assertions or broad suppressions. Keep the correctness baseline consistent for tests and implementation; an override should reflect an actual runtime or generated-fixture distinction.

## Diagnostic ownership

Use each tool for the guarantees it actually provides. Compilation, framework-aware analysis, advisory rules, and runtime compatibility are separate layers. A successful analyzer run does not establish that the deployment runtime can load the source or emitted artifacts.

Inspect recommended profiles and severity policy instead of enabling every experimental or advisory rule. Treat warnings as errors only when those rules express project policy. Follow mechanically enforced project conventions when they satisfy the runtime contract.

## Validation and stale artifacts

Run the repository's configured checks after changing compiler, analyzer, or module policy. Include affected dependent packages when interface or inference changes propagate across the build graph.

Use a repository-supported forced or clean build when cached analysis or generated output could hide a defect. Do not hardcode one package manager, compiler, or cache-deletion command into a reusable policy. A local check over one file may miss incompatible consumers or stale generated declarations.

## Diagnostic exceptions

Fix production defects in the model, function shape, or module boundary rather than suppressing them. When a tool verifiably misinterprets an established construct, use the narrowest supported centralized file-pattern override with a reason. If only local exceptions are supported, keep the exception on the affected construct. Leave the rule active elsewhere and revisit the exception when tool support changes.

Intentional rejection tests are different. Use the toolchain's supported expected-diagnostic or compile-fail mechanism, preferably one that fails when the expected rejection disappears. Isolate the rejected construct so an unrelated diagnostic cannot satisfy the test, and pair it with an accepted case where useful. This does not permit hiding production defects.
