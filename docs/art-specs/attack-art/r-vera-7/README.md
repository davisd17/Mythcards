# VERA-7 Attack Art

Default outfit pose reference: a compact articulated work-arm punch, not a projectile.
The rover loads its suspension, retracts the front claw, strikes, and settles. Sensor
mast stays focused screen-right. The passenger seat remains empty throughout.

Six 512x768 RGBA runtime poses use 100/100/130/60/90/120 ms holds (600 ms total).
Pose 4 is impact. Wheel contact replaces the humanoid boot anchor at y756.
The canonical attack direction is screen-right; the engine mirrors leftward attacks.
Idle art has a different three-quarter facing, so review the fade to/from idle in play.

Review: `contact-sheet.png`, `attack-preview.gif`, `r-vera-7-attack.ora`.
Sources: `sources/`, `sources.json`, `prompts.md`, `registration.json`.
Generated using built-in ImageGen, with the existing default rover as identity reference.
All six source canvases share one scale, with translation-only registration.
No passenger, additional weapon, or game-rule changes.

Rebuild: `tools/prepare_attack_sequence.py r-vera-7 docs/art-specs/attack-art/r-vera-7/sources.json`.
Register: `node tools/register_attack_frames.js r-vera-7`.
