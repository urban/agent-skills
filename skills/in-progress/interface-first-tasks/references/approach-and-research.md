# Method and supporting research

Interface-first, iterative and incremental development starts with an operable experience, makes key journeys interactive through supplied simulations, and progressively connects real implementations. Task decomposition should preserve both addition of capabilities and revision based on user feedback.

This skill accepts any suitable slice plan; it does not depend on a particular planning skill or artifact filename. The approach is the user's synthesis, not a claim that the sources prescribe one identical framework.

Primary sources consulted October 29, 2026:

- Basecamp/37signals, [Interface First](https://basecamp.com/gettingreal/09.1-interface-first): actual screens make product intent and scope easier to evaluate. Use this to keep tasks connected to observable experience.
- Basecamp, [From Idea to Implementation](https://basecamp.com/gettingreal/06.3-from-idea-to-implementation): work from concepts/sketches to screens for features/flows, then implementation; expect repetition. The HTML example does not require a graphical interface or a separate full frontend phase.
- Basecamp, [Rinse and Repeat](https://basecamp.com/gettingreal/06.2-rinse-and-repeat): operate, evaluate, and revise the application. Leave room for refinement tasks after feedback.
- Jeff Patton, [Don't Know What I Want, But I Know How to Get It](https://jpattonassociates.com/dont_know_what_i_want/), January 21, 2008: iteration improves existing behavior; increments add functionality. A backlog of additions alone is not iterative learning.
- Hunt and Thomas, [The Art in Computer Programming](https://media.pragprog.com/articles/other-published-articles/ArtInProgramming.pdf), September 2001, pages 2–3: the painting-over-a-sketch analogy motivates establishing relationships and flow before filling in detail.
- Hunt and Thomas interviewed by Bill Venners, [Tracer Bullets and Prototypes](https://www.artima.com/articles/tracer-bullets-and-prototypes): grow a thin end-to-end application through use cases; separate disposable experiments from evolving implementation.
- Alistair Cockburn, [Bio — notable concepts](https://www.alistaircockburn.com/Bio): the walking skeleton is a thinly connected functioning architecture.

## Consequences for task creation

- Interface, service, persistence, and verification tasks may be separate responsibilities, but collectively complete a named user journey.
- Controlled service behavior should use the intended contracts and meaningful application paths. Keep reproducible delays, failures, and partial results useful after the real adapter arrives.
- A demonstration with fake recognition establishes interaction behavior, not recognition quality. Real output, source files, timing, resource behavior, and installed operation need corresponding evidence.
- For a CLI, the experience includes commands, progress, errors, and artifacts. Internal service work can use a meaningful caller-visible demonstration without inventing a graphical UI.
- Critical technical uncertainty can require a small evidence-gathering task before provider adoption. Define its question and dependent work; task creation alone does not authorize running it.
