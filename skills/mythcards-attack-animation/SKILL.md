---
name: mythcards-attack-animation
description: Create, revise, register, and verify six-pose character attack artwork for the MythCards Godot game. Use for attack sprites, wind-up art, pose continuity corrections, and outfit attack variants; not general card illustrations or unrelated game animations.
---

# MythCards Attack Animation

Deliver one reviewable character attack at a time unless the user requests a batch.
Use the current project's art specification and helpers, not a new animation engine.
Load the available imagegen skill before generating or editing raster artwork.

## Establish the Contract

- Locate the repository from the current workspace; do not hardcode a user's drive.
- Read applicable repository instructions, `docs/art-specs/attack-art/README.md`,
  `docs/art-specs/attack-windup-spec.html`, and `LLD-figure-animation.md` Section 8B.
  These are current MythCards conventions; explicit newer decisions take precedence.
- Inspect the character's default figure, wardrobe entry, and character record.
  Inspect every local image reference with `view_image` before editing it.
- Identify attack type, range, carried props, silhouette, facing, and outfit.
  A ranged pulse, gunshot, wrench swing, and rover punch need different choreography.
- Check working-tree state. Preserve unrelated edits. Pull, commit, push, or publish
  only when requested; making art does not authorize those actions.

## Plan Six Poses

| File Suffix | Purpose | Hold |
| --- | --- | --- |
| 1-ready | Establish target and attack posture | 100 ms |
| 2-raise | Draw, raise, or begin charging | 100 ms |
| 3-brace | Readable anticipation | 130 ms |
| 4-fire | Strike or release; sole impact frame | 60 ms |
| 5-recoil | Follow-through or discharge decay | 90 ms |
| 6-recover | Return toward idle | 120 ms |

Total 600 ms; impact starts at 330 ms. `fire` also names melee impact.
These timings belong to the current MythCards contract, not every game.

Define the motion before generation. Keep an identifiable anticipation, impact,
and recovery. Make recovery visibly settle; do not accept another extended strike.
Canonical attack direction is screen-right; the engine mirrors leftward attacks.
Vertical targets currently reuse sideways art. Do not expand directional scope.
Flag a frontal/left-facing idle transition for review rather than silently replacing idle.

## Generate and Correct

Use built-in ImageGen by default, one call per pose, with true transparency.
Do not switch to a paid API workflow without user authorization. Use existing art
as the identity reference, not a loose inspiration. Persist the exact prompts.
Use [references/pose-prompts.md](references/pose-prompts.md) for prompt scaffolding.

Lock these invariants explicitly:

- Same face, hair, costume, props, rendering, lighting, scale, and camera.
- Head and eyes track the same target independently of torso rotation. Do not
  look at the viewer, weapon, palm, or photograph mid-attack.
- Exactly the intended limbs and hands; inspect hand-to-sleeve connections.
- For stationary humanoid shots/casts, keep both boots planted, with the same
  forward-foot ordering, spacing, knee shape, and leg length throughout. Record
  which boot is forward in image coordinates to avoid anatomical ambiguity.
- Keep carried props in their assigned hands. Flag deliberate prop movement.
- Keep the whole figure and weapon visible. No ground, baked-in shadow, labels,
  target, or background. Keep attack glow compact enough for print-sized sprites.
- Make impact glow clearly peak at impact when requested. Do not brighten every
  frame or change the established palette without reason.

Use the approved Ready pose as continuity reference for later poses when helpful.
Inspect results before installation: a prompt requesting invariants is not proof
that generation preserved them. Compare all six side by side and in motion.
For a defect, edit only affected poses with the offending image as target and the
approved pose as reference; preserve everything else. Make up to two focused
correction passes per defect, then show the remaining issue and ask for direction
instead of silently consuming unlimited generations or declaring it fixed.

## Package and Register

Read the existing helpers before running them; reuse rather than duplicate them:

```text
python tools/prepare_attack_sequence.py CHARACTER SOURCES_JSON
node tools/register_attack_frames.js CHARACTER
```

Use installed/discovered runtimes, not assumed machine-specific executable paths.
Save final sources inside `docs/art-specs/attack-art/CHARACTER/sources/` and use
repo-relative paths in `sources.json`; never leave a project dependency only in
the generator's output directory. Retain rejected deliveries only when useful.

The preparation helper emits runtime PNGs, registration metadata, a contact sheet,
review GIF, and a layered OpenRaster file. The default runtime names are
`game/assets/figures/CHARACTER/attack-N-POSE.png`.
Canvas: 512x768 RGBA. Baseline: lowest visible pixel y756 (contract tolerance +/-4).
Keep 24 px side and 18 px top margins. Use one common scale, then translation-only
registration; never fit every frame independently. Verify both foot positions,
not just the lowest pixel. Rovers use wheel contacts; other nonhumanoids need an
appropriate contact anchor, not an invented human stance.

On a narrow revision, compare registration metadata before and after packing.
Changed glow bounds can change the helper's common scale and re-export every pose.
Do not claim surrounding runtime frames are unchanged without checking them.
Avoid a new scale/anchor jump; investigate any changed registration before delivery.

Each outfit owns its attack list in `wardrobe.json`. Alternate-outfit filenames
use `OUTFIT-attack-N-POSE.png`; the current preparation helper targets defaults,
so do not overwrite default assets while preparing an alternate outfit. Re-dress
approved poses without changing silhouette/timing. An outfit without frames uses
the engine fallback, never another outfit's clothing.

## Verify and Present

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_game_tests.ps1
powershell -ExecutionPolicy Bypass -File tools/run_e2e.ps1 -g 'CHARACTER attack test'
```

Use required execution approvals. Wait for test sessions to finish. Verify six
registered frames, one impact on pose 4, correct holds, transparency, canvas,
baseline, safe margins, and a readable visual sequence. Technical contracts do
not establish artistic correctness.

For a new character, adapt an existing focused browser test with legal movement
for that character. Check start positions, movement restrictions, attack range,
line of sight, AP, mounted state, and defenses instead of blindly copying a route.
Capture anticipation/impact/follow-through, inspect screenshots, confirm damage
or the expected block and absence of runtime errors. Abilities are separate;
mounts attack alone, while a mounted rider uses the rider's attack.

Update delivery notes and queue status accurately: generated, registered, tested,
awaiting review, or user-approved. Only the user approves visual direction.
Show the rebuilt GIF using an absolute local Markdown image path, with a still
for focused edits when useful. Link the delivery notes/prompts, report test results
and any limitations, and say whether changes remain local. Do not start the next
character before the user's review in the one-at-a-time workflow.
