# Irina Karpova: My Opportunity

Art approved by the user on 2026-10-22. No audio or Godot playback integration.

## Performance

Approved lines, preserved verbatim from `data/ember_lines.json`:

- Claim: "Your loss. My opportunity."
- Big claim: "A nice collection even for me"

She enjoys this win. Gather opens the free hand in a pleased, almost dismissive
shrug; Hold raises an elegant empty pinch for appraisal, with a knowing smile
and lifted chin; Settle lowers that hand toward its pocket without losing the
satisfied expression. The right hand retains her keys throughout. Exactly two
hands, no attack pistol, no invented trophy, no painted Ember light.

## Registration And Review

Three 512 x 768 RGBA candidates use 120 / 360 / 120 ms timing. Crown-to-sole
landmarks normalize each source to the idle's 706-pixel body height. Foot anchor
x307 preserves idle placement; lowest visible pixel is y756. Idle's bottom is
y746, so verify the ten-pixel idle/claim baseline transition in-engine rather
than treating this review GIF as proof of runtime continuity. Source framing
varies; registration removes the resulting overall scale changes. Small coat,
jewelry and key-detail differences remain subject to visual review.

The GIF loops claim poses only, without an idle pause, text or engine effects.
The contact sheet and three-layer ORA are included beside sources, prompts and
registration. Existing default/attack sprites and wardrobe are unchanged.

## Receiving Sockets

Final sprite pixel coordinates, origin top-left. Hold sits in the empty pinch;
Gather/Settle track the receiving hand. Art annotations need in-game verification.

| Pose | x | y |
| --- | --- | --- |
| Gather | 435 | 195 |
| Hold | 383 | 128 |
| Settle | 374 | 342 |

Hold arrival socket: **(383, 128)**. Mirror x with 511 minus x, followed by the
figure transform. Interpolate the attachment through the moving hand.

```powershell
python tools/prepare_attack_sequence.py r-irina-karpova docs/art-specs/ember-claim/r-irina-karpova/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/r-irina-karpova/body-landmarks.json
```
