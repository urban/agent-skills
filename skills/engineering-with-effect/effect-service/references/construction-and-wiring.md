# Service construction and wiring

## Default class-owned shape

A concrete `Context.Service` class owns its default constructor and default Layer. This keeps the capability identity, construction requirements, and supported wiring discoverable from one symbol while preserving constructor and Layer replacement as separate seams.

```ts
export class Service extends Context.Service<Service, Shape>()(
  "@scope/package/Service",
) {
  static readonly make = Effect.gen(function* () {
    const dependency = yield* Dependency

    return Service.of({
      operation: dependency.operation,
    })
  })

  static readonly layer = Layer.effect(Service, Service.make).pipe(
    Layer.provide(Dependency.layer),
  )
}
```

- Use a stable, package-qualified service key.
- Acquire implementation dependencies once in `make` and close over them in the returned operations.
- Construct the service value with `Service.of`.
- Define the default Layer from the class-owned constructor and satisfy private construction requirements there.
- Leave requirements on service operations only when callers intentionally own them.

## Pure construction

Keep no-dependency construction as an Effect without adding an empty generator:

```ts
export class Service extends Context.Service<Service, Shape>()(
  "@scope/package/Service",
) {
  static readonly make = Effect.succeed(Service.of({ operation }))

  static readonly layer = Layer.effect(Service, Service.make)
}
```

The uniform constructor seam lets tests and alternate application compositions replace construction without inventing another convention.

## Parameterized construction

When explicit options determine service behavior or identity, make both class members functions of the same domain options:

```ts
export class Service extends Context.Service<Service, Shape>()(
  "@scope/package/Service",
) {
  static readonly make = Effect.fn("Service.make")(function* (
    options: Options,
  ) {
    const dependency = yield* Dependency
    return Service.of(makeShape(options, dependency))
  })

  static readonly layer = (options: Options): Layer.Layer<Service> =>
    Layer.effect(Service, Service.make(options)).pipe(
      Layer.provide(Dependency.layer),
    )
}
```

Options should be explicit domain data rather than a collection of optional implementation overrides. When options change Layer identity, choose them at the composition boundary and reuse the resulting Layer value wherever acquisition should be shared.

## Variants and public aliases

Name deliberate variants by policy, such as `layerTest`, `layerCached`, or `makeWith`. Keep `make` and `layer` as the discoverable defaults.

Export a package-level Layer only when embedding callers intentionally consume it. Make that export a direct alias of the class-owned Layer so the package surface has one default implementation:

```ts
export const layer = Service.layer
```

Application composition roots remain separate from individual service classes because they assemble several capabilities and own a broader runtime and scope boundary.
