# Yuri Volkov: Containment Check

Art approved by the user on 2026-10-21. No audio produced or runtime playback integration.

Yuri draws the rifle-side gauntlet inward, briefly checks it with a firm chin
dip, then lowers the weapon and resumes his watch. The helmet stays cradled
under the opposite arm. Both hands remain occupied; no invented catching hand.
The rifle stays muzzle-down throughout, with no firing or new effect.

## Registration

Three 512 x 768 RGBA candidates, Gather 120 / Hold 360 / Settle 120 ms.
Reviewed crown-to-sole landmarks normalize to the idle's 647-pixel body height.
Horizontal boot anchor x245.5 matches the idle stance, not the canvas center.
Lowest visible pixel is y756; idle is y750, so confirm the six-pixel baseline
transition in-game. Tread, suit finish and small equipment-detail differences
remain subject to art review. The GIF loops claim poses only, without idle or
Ember effects, and is not a gameplay recording.

## Receiving Sockets

Final sprite coordinates, origin top-left, just above the rifle-side gauntlet.
These are art annotations requiring in-engine validation. No light is baked in.

| Pose | x | y |
| --- | --- | --- |
| Gather | 328 | 316 |
| Hold | 324 | 310 |
| Settle | 372 | 430 |

Hold arrival socket: **(324, 310)**. Mirror with x = 511 minus x, followed by
the figure transform. Interpolate the attachment as the wrist lowers.

## Sources

Exact prompts include the grip correction and alpha cleanup. Selected hold
source is hold-clean.png; the packer copies it to hold.png. The rejected opacity
draft is retained separately and must not be used by a build. Sources, landmarks,
registration, three-layer ORA, contact sheet and 600 ms review GIF are included.
Runtime candidates are `game/assets/figures/r-yuri-volkov/claim-*.png`.
Existing default and attack sprites, wardrobe, rules and dialogue are unchanged.

```powershell
python tools/prepare_attack_sequence.py r-yuri-volkov docs/art-specs/ember-claim/r-yuri-volkov/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/r-yuri-volkov/body-landmarks.json
```
