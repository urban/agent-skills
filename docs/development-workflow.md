# Interface-first development with AI agents

Urban's preferred approach · Updated October 29, 2026.

## My approach

**Interface-first, iterative and incremental development, using simulated services that are progressively replaced with real implementations.**

Start with an application I can operate. Make its main journeys interactive, add real capabilities in small steps, and refine earlier work after demonstrations. The interface may be a desktop UI, website, or CLI.

Interface-first works from user experience toward implementation: [sketches, screens, then working code](https://basecamp.com/gettingreal/06.3-from-idea-to-implementation).

Like painting, establish the composition before refining details. See [The Art in Computer Programming](https://media.pragprog.com/articles/other-published-articles/ArtInProgramming.pdf), pages 2–3.

## Why I use it

- **Earlier feedback:** judge the experience before all capabilities are finished.
- **Visible progress:** each slice ends with a journey I can demonstrate.
- **Room to learn:** revise earlier choices as real behavior reveals problems.

Simulations make delays and failures repeatable. They need maintenance and can overstate progress. Real capabilities need separate evidence.

## How AI agents should work

1. **Plan journeys.** Follow requirements and approved designs. Propose demonstrable slices; investigate uncertain capabilities early.
2. **Create tasks within slices.** State outcomes, dependencies, acceptance criteria, and what becomes real. Include integration and demonstration.
3. **Implement and review.** Keep simulated and real services behind the same contracts. Verify results, demonstrate them at agreed checkpoints, and refine the plan from my feedback.

Each slice must answer: **What can I operate? What is real or simulated? What evidence shows it works? What needs my feedback?**

Use the [planning](../skills/in-progress/interface-first-planning/SKILL.md) and [task-creation](../skills/in-progress/interface-first-tasks/SKILL.md) skills when requested. Maintain the project's existing plan and tasks.

## How it compares with established approaches

These comparisons are my interpretation. My approach combines existing ideas with explicit service replacement.

| Approach and source                                                                                             | What I share                                              | What differs; benefit (+) and cost or limit (−)                                                                                                                                                  |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Interface First** — [Basecamp](https://basecamp.com/gettingreal/09.1-interface-first)                         | Start with screens and user journeys.                     | I add interactive simulated services. **+** Review behavior early. **−** Simulation takes upkeep.                                                                                                |
| **Iterative and incremental development** — [Jeff Patton](https://jpattonassociates.com/dont_know_what_i_want/) | Improve existing behavior and add capabilities over time. | I specify how early interactions become real. **+** Clearer agent handoffs. **−** The process still needs time for revision.                                                                     |
| **Tracer bullets** — [Hunt and Thomas](https://www.artima.com/articles/tracer-bullets-and-prototypes)           | Grow thin paths through the system using feedback.        | Some early paths use simulations. **+** Experience can be reviewed sooner. **−** Real integration remains unproven until connected.                                                              |
| **Walking skeleton** — [Alistair Cockburn](https://www.alistaircockburn.com/Bio)                                | Keep a small, connected application running as it grows.  | I also expose broader journeys through simulation. **+** See the product's shape early. **−** Visible breadth can overstate working capability.                                                  |
| **Prototyping** — [Hunt and Thomas](https://www.artima.com/articles/tracer-bullets-and-prototypes)              | Use limited experiments to learn.                         | I usually evolve application paths and replace supplied services; exploratory prototypes may be discarded. **+** Reuse reviewed behavior. **−** Experimental shortcuts need review before reuse. |

Basecamp's [Rinse and Repeat](https://basecamp.com/gettingreal/06.2-rinse-and-repeat) reinforces the cycle: operate, evaluate, revise.

## Example: Scribe

Retain requirements and feasibility gates; review and refine each step.

| Slice                     | What I can demonstrate                                                  |
| ------------------------- | ----------------------------------------------------------------------- |
| 1. Shell                  | Launch and navigate the approved Start/setup screens.                   |
| 2. Simulated journeys     | Exercise import, capture, pause/resume, review, and recovery.           |
| 3. Real WAV transcription | Select local audio; see progressive text and saved files.               |
| 4. Durable review         | Change speaker names/assignments; save and reopen.                      |
| 5. Imported playback      | Listen, seek from passages, and inspect waveform/timeline.              |
| 6. Microphone capture     | Record, pause/resume, stop, and verify the WAV.                         |
| 7. Live transcription     | See text before Stop; settle remaining recognition.                     |
| 8. System audio           | Capture both sources and preserve overlapping speech.                   |
| 9. Listening copy         | Build the combined WAV after Stop; enable playback and repair.          |
| 10. Installed acceptance  | Verify quality, privacy, recovery, and operation on qualified hardware. |

Check overlap recovery and speaker continuity early. Keep recognition, save, and playback status separate. Mic-only capture is intermediate. Core may use a filesystem abstraction supplied by desktop or CLI.

Follow the [specification](../../scribe/specs/001-scribe-project/spec.md), [plan and feasibility gates](../../scribe/specs/001-scribe-project/plan.md), and [approved UI behavior](../../scribe/specs/001-scribe-project/scribe-ui/behavior.md).

Main Scribe chat: **Diagram system architecture**, thread `01a189c5-48b8-77f0-bdba-a8c2db64b258`. Use this approach there; this reference does not itself authorize implementation.

Writing guide: [ISO 24495-1:2023 — Plain language](https://www.iso.org/standard/78907.html). Research links reviewed October 29, 2026.
