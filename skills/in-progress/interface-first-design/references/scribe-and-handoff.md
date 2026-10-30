# Scribe example and handoff boundaries

This example describes the retained Scribe interface artifacts reviewed on October 30, 2026. It illustrates the method, not requirements for another product. The skill works without the Scribe repository.

## What made the design useful

Scribe's reference paired an editable HTML source with a standalone interactive preview. It demonstrated recording setup, WAV import, live and paused capture, processing, review, speaker correction, timeline navigation, saving recovery, and unfinished-work exit decisions.

The preview offered explicit scenario controls for difficult-to-reach failures. Those controls were design tools, not application navigation. Capture, transcription, native dialogs, playback, and saving were simulated. A measured waveform fixture supported presentation checks, while transcript content and speaker timing remained illustrative; the waveform was not the audio for that transcript.

The reference package separated:

| Artifact | Purpose |
| --- | --- |
| Editable source and standalone preview | Operate and revise the design; review it outside the original host |
| Visual index and 47 state screenshots | Inspect important views and states of one design |
| README | Record visual decisions, interaction rationale, preview instructions, and limitations |
| Behavior contract, UI-01–14 | Make flows and coordinated view behavior explicit for implementation |
| Requirements coverage | Map interface representation while retaining real product acceptance obligations |
| Validation record | Identify the checked source, conditions, actual checks, and evidence limits |
| Approval manifest | Tie explicit user approval to a defined artifact baseline |

The retained validation record reports browser checks at seven widths and offline presentation checks. These are historical results for that artifact, not checks performed by this skill or evidence of real product privacy or acoustic behavior. Verify current artifacts before making fresh claims.

Scale the package down for simpler work. A short reference plus source, preview, and a few captures can be enough. Screenshot counts, hash manifests, exact typography, palettes, and folder names are project choices. A standalone export is useful for offline review or portability; do not require it when the existing preview environment meets the need.

## Composition with planning and tasks

These responsibilities exchange artifacts; they are not mandatory skill dependencies or a fixed waterfall:

| Responsibility | Owned output | Useful incoming design evidence |
| --- | --- | --- |
| Interface design | Operable reference, visual/behavior decisions, review status | Intent, requirements, existing behavior, and feedback |
| Interface-first planning | Demonstrable slices, real/simulated transitions, evidence gates, feedback opportunities | Accepted journeys and behaviors, unresolved capability assumptions, prototype limitations |
| Interface-first tasks | Executable work for selected slices, ownership, dependencies, acceptance evidence | Selected slice contract plus applicable design behaviors and verification references |

Design can precede planning, refine a selected slice, or evolve alongside real integrations. Do not wait for a complete design baseline before investigating an uncertain capability or proving a useful thin path. An independent prototype needs only enough seams to communicate interactions; an application demonstrator should preserve existing command/state paths where feasible.

In a handoff, identify the authoritative requirements, design revision and review status, relevant behavior IDs, preview access, controlled scenarios, simulated mechanisms, unresolved decisions, and actual remaining evidence. Present requirement changes as proposals unless their adoption is already authorized. Planning and task authors should be able to consume this contract without installing this skill or adopting its prototype framework.

## Original source locations

When the local Scribe repository is available, the original reference is at `specs/001-scribe-project/scribe-ui/` under its root. Useful files are `README.md`, `behavior.md`, `coverage.md`, `approval.json`, `validation.json`, `index.html`, `design.html`, and `sources/design.html`. Consult them only when their detail is relevant; do not copy Scribe's source or visual identity into other projects by default.
