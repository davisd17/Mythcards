# Iset-Nara Attack Art

Default outfit: a precise divider-directed geometric pulse. Her right hand lifts
the existing brass surveying dividers, draws into a charged aim, drives forward
at impact, retracts, then lowers the tool. Her left hand retains the luminous
brass-framed plan tablet. Exactly two hands and one two-legged divider; the tablet
tilts slightly during release to clear the casting arm. This is ordinary ranged
attack presentation, not Hidden Geometry or Hidden Vault placement. No rule changes.

Six 512x768 RGBA sprites, holds 100/100/130/60/90/120 ms, total 600 ms.
Pose 4 is impact at 330 ms. Geometric light is strongest in Fire, diminished in
Recoil, and absent from the divider in Ready/Recover. Tablet light remains.

Reviewed crown-to-sole registration matches 625 px idle height. Runtime opaque
heights measure 624-625 px. Both sandals remain planted: viewer-left lower/forward,
viewer-right higher/back. Fire received two focused stance correction passes.
Minor cloth, tool-detail, and torso-position variation remains for visual review.

Idle art is unchanged. Its down-left gaze transitions into rightward target
tracking in the attack. Idle's footprint is left of canvas center; preserve that
placement rather than recentering at x256. The landmarks set `target_anchor_x`
to 185 and record source foot centers. The helper defaults to x256 for all other
deliveries. Safe margins remain 24 px sides, 18 px top, with lowest visible y756.
Leftward attacks mirror; vertical targets reuse sideways art.

Review: `attack-preview.gif`, `contact-sheet.png`, and layered
`a-flood-survivor-iset-nara-attack.ora`.
Reproduction: `sources/`, `sources.json`, `body-landmarks.json`,
`registration.json`, and exact built-in ImageGen prompts in `prompts.md`.
Visual direction accepted on 2026-10-17 before proceeding to Thalassa-Nekh.
Changes remain local until a requested push.

Verification: all 541 Godot tests passed, including height and off-center sandal
position regression. Focused browser attack test passed with Iset-Nara at (4,4)
and Yuri at (4,2), after refreshing her one character AP following movement.
Damage resolved and no runtime errors were reported. Idle, anticipation, impact
and follow-through screenshots were captured for visual review.

Rebuild: `tools/prepare_attack_sequence.py a-flood-survivor-iset-nara docs/art-specs/attack-art/a-flood-survivor-iset-nara/sources.json --body-landmarks docs/art-specs/attack-art/a-flood-survivor-iset-nara/body-landmarks.json`.
Register: `node tools/register_attack_frames.js a-flood-survivor-iset-nara`.
