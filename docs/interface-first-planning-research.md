# Interface-first, iterative and incremental development

The user's preferred approach begins with something they can operate, makes important journeys interactive with simulated services, and progressively supplies real implementations through the same contracts. It combines refinement of existing behavior with addition of capabilities. It is a synthesis of established practices, rather than a claim that these sources define one identical methodology.

## Research and relevance

Primary sources consulted October 29, 2026:

| Source                                                                                                                                                           | Useful guidance                                                                                                              | Limit of the connection                                                                                        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Basecamp/37signals, [Interface First](https://basecamp.com/gettingreal/09.1-interface-first)                                                                     | Evaluate actual screens and flows early; let the experience guide underlying implementation and initial scope.               | Does not establish the feasibility of a backend merely because its UI is convincing.                           |
| Basecamp, [From Idea to Implementation](https://basecamp.com/gettingreal/06.3-from-idea-to-implementation)                                                       | Move from concepts and sketches to screens for a feature/flow, then connect implementation; repeat as understanding changes. | Its HTML-first example is not a mandatory technology or instruction to finish every screen before integration. |
| Basecamp, [Rinse and Repeat](https://basecamp.com/gettingreal/06.2-rinse-and-repeat)                                                                             | Use, evaluate, and revise the application; plan for refinement.                                                              | Iteration is a learning loop, not evidence that a release is ready.                                            |
| Jeff Patton, [Don't Know What I Want, But I Know How to Get It](https://jpattonassociates.com/dont_know_what_i_want/), January 21, 2008                          | Distinguishes iteration from incrementing and uses an artist's sketch/form/detail progression.                               | Adding feature tickets alone does not provide iterative refinement.                                            |
| Hunt and Thomas, [The Art in Computer Programming](https://media.pragprog.com/articles/other-published-articles/ArtInProgramming.pdf), September 2001, pages 2–3 | Connects painting over a composition sketch with tracer bullets and a thin end-to-end system.                                | The analogy helps choose sequence; it is not a reason to preserve every initial design choice.                 |
| Hunt and Thomas interviewed by Bill Venners, [Tracer Bullets and Prototypes](https://www.artima.com/articles/tracer-bullets-and-prototypes)                      | Grow a skeleton application through end-to-end use cases; distinguish evolving implementation from disposable experiments.   | A path whose central capability is mocked is not proof of that real capability.                                |
| Alistair Cockburn, [Bio — notable concepts](https://www.alistaircockburn.com/Bio)                                                                                | Identifies a walking skeleton as a thinly connected functioning architecture.                                                | This short definition does not mandate a particular toolchain or document set.                                 |

## Choosing fidelity

- **Experience:** controlled passages or responses can expose navigation, timing, wording, and recovery behavior. Agent judgment is not a substitute for observed human usability.
- **Integration:** exercise the real commands, state ownership, subscriptions, and intended contracts with supplied services. A separate animated mockup proves less about those paths.
- **Capability:** real recognition, capture, persistence, performance, and platform isolation require observation of the mechanism being evaluated.
- **Delivery:** installed operation requires its own evidence; a development checkout demonstration does not establish it.

Simulation is the user's preferred early implementation technique; the cited practices support the broader sequence but do not prescribe an identical service-replacement architecture.

For a CLI, rough in commands, help, progress, failures, and output artifacts instead of screens. For service/internal work, choose its meaningful caller-visible surface rather than adding a gratuitous UI. Reuse an existing interface for small features and skip a separate shell milestone.

Define service semantics before elaborate abstractions: inputs, outputs, fact ownership, lifecycle and expected failures. Different implementations should honor that contract; research may reveal that the contract itself needs explicit revision.
