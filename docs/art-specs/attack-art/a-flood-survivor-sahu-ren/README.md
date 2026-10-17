# Sahu-Ren Attack Art

Default outfit: a focused two-finger memory cast toward screen-right. The right
hand lifts from the archive, draws into a charged gesture, drives forward with a
brief icy white/cyan line-fragment burst, retracts, and relaxes above the tablet.
The left hand retains the irregular etched stone archive throughout; no prop
swap or extra weapon. This is ordinary ranged-attack presentation, not Forbidden
Testimony or Last Memory Released. Gameplay and abilities are unchanged.

Six 512x768 RGBA sprites; holds 100/100/130/60/90/120 ms, total 600 ms.
Pose 4 is the sole impact, starting at 330 ms. Fire has the strongest fingertip
flash and brighter right-arm markings; Recoil has residual fragments, Recover
has no fingertip burst. Ready retains a few faint fragments near the archive.

Body registration uses reviewed crown-to-sole landmarks, not arm/effect bounds.
Measured opaque heights are 671-672 px across the poses versus 672 px idle.
Both sandals remain planted, with viewer-left lower/forward and viewer-right
higher/back. Safe margins: 24 px sides, 18 px top; y756 lowest visible baseline.
No floor or baked-in ground shadow. Some fine cloth, tattoo and jewelry detail
variation remains for visual review. Idle art is unchanged: its downward reading
gaze transitions into level screen-right target tracking for the cast. Leftward
attacks mirror; vertical targets reuse sideways art.

Review: `attack-preview.gif`, `contact-sheet.png`, and layered
`a-flood-survivor-sahu-ren-attack.ora`.
Reproduction: `sources/`, `sources.json`, `body-landmarks.json`,
`registration.json`, and exact built-in ImageGen prompts in `prompts.md`.
Visual direction accepted on 2026-10-17 before proceeding to Iset-Nara.
Changes remain local until a requested push.

Verification: all 540 Godot tests passed, including the shared six-pose art
contract and Sahu-Ren body-height regression. Focused browser test passed with
Sahu-Ren at (3,4) attacking Yuri at (3,2), confirming damage and no runtime errors.
Idle, anticipation, impact and follow-through screenshots captured for review.

Rebuild: `tools/prepare_attack_sequence.py a-flood-survivor-sahu-ren docs/art-specs/attack-art/a-flood-survivor-sahu-ren/sources.json --body-landmarks docs/art-specs/attack-art/a-flood-survivor-sahu-ren/body-landmarks.json`.
Register: `node tools/register_attack_frames.js a-flood-survivor-sahu-ren`.
