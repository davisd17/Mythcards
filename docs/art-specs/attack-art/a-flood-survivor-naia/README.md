# Naia Attack Art

Default Tomb Sentinel outfit: right-hand curved-blade cut while guarding with the
existing shield on her left forearm. Ready is low guard, Raise/Brace prepare the
cut, Fire crosses toward screen-right, Recoil carries it low, Recover returns.
Revised 2026-10-17 for a heavier swing: higher coiled Brace, forward shoulder
drive at Fire, and a distinct low finishing arc in Recoil. Shield tucks aside.
Armor, collar, forehead jewel, braids and shield/blade identity are retained.
No gameplay or ability changes. Idle art is unchanged.

Six 512x768 RGBA runtime frames, 100/100/130/60/90/120 ms (600 ms total).
Pose 4 is impact at 330 ms. Reviewed anatomical source normalization matches idle
body height; translation registers the planted feet. Safe margins 24 px sides,
18 px top, y756 foot baseline. Blade stays above soles; its raised tip may be
above the crown without affecting anatomical size registration.
Leftward attacks mirror; vertical targets reuse sideways poses.

Review: `contact-sheet.png`, `attack-preview.gif`, `a-flood-survivor-naia-attack.ora`.
Reproduction: `sources/`, `sources.json`, `body-landmarks.json`, `registration.json`,
`prompts.md`. Built-in ImageGen used idle for candidate Ready; later poses used
that candidate for continuity. The stronger-swing revision was accepted on
2026-10-17 before proceeding to Meret-Anu.
Review note: some rear-leg spacing and cloth variation relative to Ready remains.
This residual variation remains documented. The raised blade extends above the crown;
body landmarks exclude it. Brace uses an exposed crown band at x292..299 for the
runtime body-height regression because the blade now crosses the old band.
The previous guarded swing is archived in `previous-guarded-swing/` for comparison.

Verification after the stronger-swing revision: all 538 Godot tests passed, along
with the focused Naia browser attack test. Reviewed opaque crown-to-sole heights
are 667-668 px across all six poses versus 668 px idle. No timing/rules changes.

Rebuild: `tools/prepare_attack_sequence.py a-flood-survivor-naia docs/art-specs/attack-art/a-flood-survivor-naia/sources.json --body-landmarks docs/art-specs/attack-art/a-flood-survivor-naia/body-landmarks.json`.
Register: `node tools/register_attack_frames.js a-flood-survivor-naia`.
