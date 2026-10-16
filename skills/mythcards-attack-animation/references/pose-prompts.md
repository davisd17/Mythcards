# Pose Prompt Scaffolding

Replace placeholders with the inspected character's actual details. Keep prompts
specific to the chosen pose; do not paste speculative costume or story additions.

## New Pose

```text
Use case: identity-preserve.
Input image 1: exact character identity/costume reference.
Input image 2, if supplied: approved Ready pose for registration and stance.
Asset: ONE full-body transparent attack pose for MythCards Godot.
Preserve: [face, hair, costume, lighting, props and their assigned hands].
Facing: three-quarter screen-right; eyes and nose aimed at the same enemy.
Stance: [describe both boot/wheel contacts and forward-foot ordering in viewer coordinates].
Keep scale, canvas, leg length, foot contacts and camera unchanged.
Pose: [one concrete action; which limb moves, where it begins/ends, and prop angle].
Exactly [limb count]; no duplicated hands or disconnected wrists.
Full figure and weapon in frame with safe margins; true alpha, no floor,
shadow, target, text, or opaque background. [Compact effect requirement if needed].
```

## Focused Correction

```text
Input image 1: edit target with [observed defect].
Input image 2: approved continuity reference.
Change ONLY [specific anatomy, gaze, stance, glow, or prop defect].
Match [explicit reference property, including viewer-side coordinates].
Preserve [upper-body attack action / lower-body stance / identity / clothing /
two-hand anatomy / canvas / registration / alpha, as applicable].
Do not introduce a new pose or alter unaffected parts.
```

For hand defects, trace each shoulder through elbow and cuff to its single hand.
For gaze, specify horizontal screen-right tracking, not merely 'face right'.
For foot drift, compare Ready, brace, impact and recoil rather than assuming the
defect occurs in only the frame first noticed by the user.
For impact brightness, describe core/rings/local spill separately and keep the
effect bounded. Check that added alpha glow does not change registration scale.
