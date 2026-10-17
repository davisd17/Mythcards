# Ahesu Attack Art and Idle Cleanup

Default Stone-Current Serpent: draw neck back, brace, compact forward bite, recoil,
settle. Lower coil width is the size reference; total height changes with neck pose.
No rider, limbs, wings, projectile, or gameplay changes. Rider attacks remain separate.

The idle source was cleaned using built-in ImageGen to remove the unrelated rover
wheel and detached debris. `idle-before-cleanup.png` retains the previous export;
`idle-clean-source.png` is the cleaned master. The idle pack centers its coil and
registers its base at y756 on the original 512x768 canvas.

Six 512x768 RGBA attack poses: 100/100/130/60/90/120 ms, total 600 ms.
Pose 4 is impact at 330 ms. Reviewed left/right coil landmarks normalize source
units to cleaned idle width; translation anchors the coil contact. No per-frame
fitting to changing neck height. Side margins 24 px, top 18 px. Screen-right
art mirrors leftward; vertical attacks reuse sideways art.

Review: `contact-sheet.png`, `attack-preview.gif`,
`a-flood-survivor-ahesu-attack.ora`. Reproduction: `sources/`, `sources.json`,
`body-landmarks.json`, `registration.json`, `prompts.md`.
Built-in ImageGen used the cleaned idle source for all six poses. Visual review pending.

Rebuild: `tools/prepare_attack_sequence.py a-flood-survivor-ahesu docs/art-specs/attack-art/a-flood-survivor-ahesu/sources.json --body-landmarks docs/art-specs/attack-art/a-flood-survivor-ahesu/body-landmarks.json --idle-source docs/art-specs/attack-art/a-flood-survivor-ahesu/idle-clean-source.png`.
Register: `node tools/register_attack_frames.js a-flood-survivor-ahesu`.
