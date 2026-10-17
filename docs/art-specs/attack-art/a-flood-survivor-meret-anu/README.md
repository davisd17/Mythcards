# Queen Meret-Anu Attack Art

Default outfit: a controlled tide-palm cast toward screen-right, retaining the
closed Tide-Sealed Archive under her right arm (viewer-left). Her free left hand
raises, gathers turquoise/pale-gold tide-light, presses forward at impact, draws
back as the light dissipates, and returns toward idle. Exactly two hands; the
archive never opens. This illustrates her ordinary ranged attack, not Memory
Discipline or the Tide-Sealed Archive ability. No gameplay changes.

Six 512x768 RGBA sprites, holds 100/100/130/60/90/120 ms, total 600 ms. Pose 4
is the sole impact at 330 ms. Brightness peaks in Fire, with no glow in Ready or
Recover. Full crown and gown remain visible; y756 baseline, 24 px side margins,
18 px top margin. Anatomical registration uses crown-to-hem height, excluding
hand/VFX reach. Opaque heights measure 732-733 px against 732 px idle.

Idle art is unchanged. Its frontal head transitions to a rightward-looking cast;
the engine mirrors leftward attacks and reuses sideways art for vertical targets.
Some generated gown-fold and jewelry detail variation remains for visual review.
Visual direction accepted on 2026-10-17 before proceeding to Sahu-Ren.

Verification: all 539 Godot tests passed, including crown-to-hem size regression
and the shared six-pose art contract. The focused browser attack test passed with
Yuri at (4,2) and Meret-Anu at (4,4), an unobstructed orthogonal ranged attack.
Idle, anticipation, impact and follow-through screenshots were captured; no
runtime errors were reported. Changes remain local until a requested push.

Review: `attack-preview.gif`, `contact-sheet.png`, and layered
`a-flood-survivor-meret-anu-attack.ora`.
Reproduction: `sources/`, `sources.json`, `body-landmarks.json`,
`registration.json`, and exact built-in ImageGen prompts in `prompts.md`.
Rejected outputs are not project dependencies.

Rebuild: `tools/prepare_attack_sequence.py a-flood-survivor-meret-anu docs/art-specs/attack-art/a-flood-survivor-meret-anu/sources.json --body-landmarks docs/art-specs/attack-art/a-flood-survivor-meret-anu/body-landmarks.json`.
Register: `node tools/register_attack_frames.js a-flood-survivor-meret-anu`.
