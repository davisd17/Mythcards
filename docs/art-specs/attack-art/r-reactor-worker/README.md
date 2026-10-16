# Reactor Worker Attack Art

Default outfit pose reference for Nikolai Yegorov / Reactor Worker. This is the first
of the 13 characters following the Yuri pilot. Pending designer review.

The attack is a one-handed swing of his existing red pipe wrench toward screen-right.
His free hand retains the family photograph against his chest. Frame 4 is the blow;
the shared file name `fire` denotes impact for melee characters too.

Revision: head and eyes stay directed screen-right throughout the attack, following
the Ready pose's target direction even while the torso coils. The first delivery's
wandering gaze was rejected. Its sources and previews are archived in `gaze-v1/`.

| Pose | Action | Hold |
| --- | --- | --- |
| 1 ready | Low wrench guard, eyes toward target | 100 ms |
| 2 raise | Lift wrench toward shoulder | 100 ms |
| 3 brace | Torso coils back, elbow draws behind shoulder | 130 ms |
| 4 fire | Wrench extends toward the target; impact | 60 ms |
| 5 recoil | Tool drops through the follow-through | 90 ms |
| 6 recover | Shoulder and tool settle toward idle | 120 ms |

Runtime PNGs: `game/assets/figures/r-reactor-worker/attack-N-POSE.png`.
The canvas is 512x768 RGBA with a boot baseline at y756. All six sources use one
shared scale, followed by translation-only registration. The metadata records both
the scale and every offset. Generated seams and anatomy still need visual review;
contract tests check file geometry, not artistic correctness.

Review files:

- `contact-sheet.png`: six labeled poses.
- `attack-preview.gif`: 600 ms looping sequence with short pose crossfades.
- `r-reactor-worker-attack.ora`: six full-canvas raster pose layers for Krita/GIMP.
- `sources/`: original generated poses.
- `sources.json`, `prompts.md`, `registration.json`: reproducible source mapping,
  built-in ImageGen prompts, and packing metadata.

Rebuild with `tools/prepare_attack_sequence.py r-reactor-worker SOURCES_JSON`, then
register using `node tools/register_attack_frames.js r-reactor-worker`.
The engine uses the outfit's six poses with the default shared transform and mirrors
leftward attacks. Abilities retain their existing procedural animation. Later outfits
must re-dress these poses after approval rather than introduce new timing.
