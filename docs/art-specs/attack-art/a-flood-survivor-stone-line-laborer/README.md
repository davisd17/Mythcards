# Stone-Line Laborer Attack Art

Menka of the Lower Causeway, default outfit only. One-handed compact diagonal
stone-hammer blow: shoulder lift, coil, strike, low follow-through, recovery.
Existing rope, pendant, work wraps, belt tools and bare-foot stance remain.
No overhead arc, projectile, invented weapon, or gameplay changes.

Six 512x768 RGBA frames, 100/100/130/60/90/120 ms; total 600 ms.
Pose 4 is impact at 330 ms. Idle-size crown-to-sole source normalization then
translation-only foot registration; y756 baseline, 24 px side/18 px top margins.
Screen-right art mirrors leftward; vertical attacks reuse sideways poses.

Review: `contact-sheet.png`, `attack-preview.gif`,
`a-flood-survivor-stone-line-laborer-attack.ora`.
Reproduction: `sources/`, `sources.json`, `prompts.md`, `body-landmarks.json`,
`registration.json`. Built-in ImageGen used default idle for Ready and generated
candidate Ready as continuity reference for later poses. Visual approval pending.

Rebuild: `tools/prepare_attack_sequence.py a-flood-survivor-stone-line-laborer docs/art-specs/attack-art/a-flood-survivor-stone-line-laborer/sources.json --body-landmarks docs/art-specs/attack-art/a-flood-survivor-stone-line-laborer/body-landmarks.json`.
Register: `node tools/register_attack_frames.js a-flood-survivor-stone-line-laborer`.
