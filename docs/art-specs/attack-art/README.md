# Attack Art Review Queue

Default outfits only. Work through characters individually and review each six-pose
sequence before starting the next. Use the 600 ms timing and pose-4 impact specified
in `docs/art-specs/attack-windup-spec.html` and `LLD-figure-animation.md` Section 8B.

| Order | Character | Status |
| --- | --- | --- |
| Pilot | Major Yuri Volkov | Implemented and playtested |
| 1 | Reactor Worker | Corrected gaze approved; registered and tested |
| 2 | VERA-7 | Approved; registered and tested |
| 3 | Irina Vasilievna Karpova | Stance correction approved; registered and tested |
| 4 | Dr. Mikhail Orlov | Impact glow revision accepted; registered and tested |
| 5 | Dr. Elena Morozova | Six-pose dream-signal attack registered; awaiting designer review |
| 6 | Zoya Miranova | Approved; registered and tested |
| 7 | Stone-Line Laborer | Approved; registered and tested |
| 8 | Ahesu, the Stone-Current Serpent | Approved; cleaned idle and six poses registered and tested |
| 9 | Naia of the Black Sarcophagus | Stronger swing accepted; registered and tested |
| 10 | Queen Meret-Anu | Approved; six-pose tide-palm cast registered and tested |
| 11 | Sahu-Ren, Last Memory-Keeper | Approved; six-pose memory cast registered and tested |
| 12 | Iset-Nara | Approved; six-pose divider pulse registered and tested |
| 13 | Thalassa-Nekh | Partial Seraph revision approved; registered and tested |

Each delivery folder contains master sources, prompts, registration metadata, a layered
OpenRaster file, contact sheet, and review GIF. Runtime PNGs belong in the corresponding
`game/assets/figures/<character-id>/` folder. Register with
`tools/register_attack_frames.js`, then run the Godot art-contract tests and inspect
the animation in the exported game. Future outfits re-dress the approved poses.
