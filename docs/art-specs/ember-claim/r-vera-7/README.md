# VERA-7: Sample Secured

Art approved by the user on 2026-10-21. Audio not produced; no runtime playback integration.

The sampling claw gathers an invisible sample, closes partway for a careful
inspection, then opens and returns to its parked position. The camera gives a
small acknowledgement tilt before resuming its watch. The chassis does not
deliberately roll or bounce. Existing green instrument light remains; Ember
light is reserved for the engine.

## Registration

Three transparent 512 x 768 runtime candidates use 120/360/120 ms timing.
The grounded wheel span, not the moving mast or extended arm, sets scale.
Reviewed source wheel spans normalize to the idle's 440-pixel span; bottommost
visible pixel is y756. The fixed wheel center is x267, matching idle placement
within one pixel. The original idle bottom is y749, so these candidates follow
the claim baseline contract 7 pixels lower; verify the idle transition in-game.
Small tread and equipment-detail differences remain subject to art review.

Review GIF loops only the claim poses. It is not a gameplay recording.

## Receiving Sockets

Runtime pixel coordinates, top-left origin; empty claw gap, not the green lens.
Coordinates are review annotations pending in-engine verification.

| Pose | x | y |
| --- | --- | --- |
| Gather | 131 | 550 |
| Hold | 115 | 554 |
| Settle | 70 | 597 |

Hold arrival socket: **(115, 554)**. Mirror x using 511 minus x, then apply the
figure transform. The moving socket needs interpolation with the claw.

## Sources

Exact generation and framing-correction prompts, selected source PNGs, landmarks,
registration, layered ORA master, contact sheet and review GIF are included.
Rejected clipped drafts are explicitly named and are not runtime candidates.
No wardrobe attack frames, gameplay rules, dialogue or sounds were changed.

```powershell
python tools/prepare_attack_sequence.py r-vera-7 docs/art-specs/ember-claim/r-vera-7/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/r-vera-7/body-landmarks.json
```
