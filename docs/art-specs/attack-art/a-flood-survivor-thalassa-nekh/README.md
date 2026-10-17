# Thalassa-Nekh Attack Art

Default outfit: black-water compression and release. Both hands gather the
existing surrounding ribbons inward; the right hand supports the compressed
coil while the left palm drives a brief crescent pulse toward screen-right.
The left arm retracts as droplets fade, then both arms reopen toward idle.
Exactly two arms and hands, no carried props or weapons. The revised attack
briefly reveals spectral Seraph shoulder-fans, without changing her outfit/form.
This is ordinary ranged-attack presentation, not Black-Water Communion or the
level-3 Seraph transformation. No gameplay changes; alternate outfits are excluded.

Six 512x768 RGBA sprites, holds 100/100/130/60/90/120 ms, total 600 ms.
Pose 4 is impact at 330 ms. Fire has the strongest white/cyan core; Raise/Brace
contain dark-water coils, Recoil retains droplets, Recover returns to ambient
ribbons. The surrounding water changes shape intentionally through the cast.

Seraph revision: three short translucent opal-cyan fin/veil panels emerge behind
each shoulder during Brace, read most clearly at Fire, then dissolve into faint
edge traces during Recoil. Shapes echo the existing Drowned Seraph reference;
there is no extra face, body, or pair of arms and no full transformation/outfit
swap. This glimpse was requested for ordinary attacks. Ready, Raise and Recover
runtime PNGs remain byte-identical after rebuilding (SHA-256 verified).
The previous water-only sources/preview/registration are in `previous-water-only/`.
After the Seraph revision, all 542 Godot tests and the focused browser attack test
passed again. The same 600 ms timing, body-size regression and impact rules hold.

Reviewed crown-to-sole body height is 674 px idle and 673-674 px runtime.
The visible forward bare foot stays planted, other foot remains concealed.
The last four opaque foot rows stay within three horizontal pixels of idle.
Target foot anchor x247 preserves her original placement. Registration translates
the generated Fire source back into alignment instead of fitting to water bounds.
Safe margins: 24 px sides, 18 px top, lowest visible y756. Body is never reduced
to accommodate the wave. Fire received compact-wave and margin corrections.

Idle art remains unchanged. Its upturned face transitions to rightward target
tracking; leftward attacks mirror and vertical targets reuse sideways art.
Fine hair, water, jewelry and cloth variations remain for visual review.
Partial Seraph visual revision accepted for publication on 2026-10-17.

Verification: all 542 Godot tests passed, including the shared six-pose art
contract and Thalassa body-height regression. Focused browser attack test passed
with Thalassa at (4,4) attacking Yuri at (4,2), after movement AP refreshed.
Damage resolved with no runtime errors. Idle, anticipation, impact and
follow-through screenshots captured. All 14 default roster figures now have
registered six-pose sequences.

Review: `attack-preview.gif`, `contact-sheet.png`, and layered
`a-flood-survivor-thalassa-nekh-attack.ora`.
Reproduction: `sources/`, `sources.json`, `body-landmarks.json`,
`registration.json`, and exact built-in ImageGen prompts in `prompts.md`.

Rebuild: `tools/prepare_attack_sequence.py a-flood-survivor-thalassa-nekh docs/art-specs/attack-art/a-flood-survivor-thalassa-nekh/sources.json --body-landmarks docs/art-specs/attack-art/a-flood-survivor-thalassa-nekh/body-landmarks.json`.
Register: `node tools/register_attack_frames.js a-flood-survivor-thalassa-nekh`.
