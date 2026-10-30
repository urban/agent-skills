# Example roadmap: Scribe

Illustrative sequence from Urban's October 29, 2026 planning discussion. Verify the current Scribe specification, approved UI, implementation plan, and evidence before using it; the example is not a new source of product requirements or acceptance.

| Slice                      | Operable demonstration                                                                             | Capability progression                                                                                    |
| -------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| S01 — Shell                | Launch and navigate the approved Start/setup experience; cancel and return.                        | Real application shell and transport; downstream services remain controlled.                              |
| S02 — Journeys             | Exercise import, recording, pause/resume, stop, finalizing, review, speaker changes, and recovery. | Real command/state/subscription paths with supplied capture, recognition, and storage services.           |
| S03 — WAV recognition      | Choose a local WAV and destination; see progressive recognition and saved transcript artifacts.    | Real input validation, bounded worker integration, and companion/Markdown publication.                    |
| S04 — Durable review       | Name/create speakers, reassign passages, save, close, and reopen.                                  | Durable review revisions, retained overrides, reconciliation, and file ownership.                         |
| S05 — Imported playback    | Play the original WAV and seek from a passage or speaker segment.                                  | Real media capability, time mapping, waveform summaries, and bounded transcript/timeline views.           |
| S06 — Mic capture          | Record, pause/resume, stop, inspect the WAV, and process it through the existing file path.        | Real mic and source writer; verify pause silence, elapsed duration, and resumed positions.                |
| S07 — Live mic recognition | See text before Stop and settle queued/final-tail work.                                            | Real persisted-range recognition, bounded backlog, live updates, and coverage accounting.                 |
| S08 — System audio         | Capture both sources, including simultaneous speech and permission/source failures.                | Real dual-source timing and originals; verify both contributions rather than inferring them from a meter. |
| S09 — Listening copy       | Inspect live peaks, stop, build the combined WAV, play when ready, and repair a failed mix.        | Bounded post-Stop mixing independent of final recognition; real waveform and generation-bound playback.   |
| S10 — Installed acceptance | Operate complete journeys on qualified hardware with the installed application.                    | Separate model installation, signed privacy/capture behavior, real quality and recovery evidence.         |

Run small overlap-recovery and speaker-continuity investigations while the early UI work progresses. Failed feasibility blocks adoption of the affected provider, not every independent presentation task.

## Boundaries that matter in this example

- Main is the canonical recording/review writer; renderer state is derived. Controlled and real services both pass through this ownership path.
- Core may require an abstract filesystem/platform service; CLI or desktop composition supplies its implementation.
- Captured meetings retain two original WAVs. The combined listening WAV is created after Stop and is not a recognition dependency.
- Imported audio stays unchanged; it does not require a new listening copy.
- Recognition, durable save, and playback readiness are independent outcomes. Preview/mix-only failure must not masquerade as lost recognition or erase review.
- Mic-only operation is a developmental slice. The final capture requirement still includes microphone and system audio.

Retain feedback checkpoints and refine earlier slices as real behavior exposes problems. Preserve current requirements and approved designs; a proposed change needs an explicit decision rather than being smuggled in as task decomposition.
