# Iset-Nara: No Crown Can Seal This Truth

Art approved by the user on 2026-10-23. Visual playback is not verified.
Shared audio status is tracked separately in the production queue.

## Performance

Approved dialogue from `data/ember_lines.json`, preserved verbatim:

- Claim: "Every force needs an exit."
- Big claim: "No crown can seal this truth."

Gather lifts the dividers above the plan tablet. Hold confirms the measured gap,
then raises her chin with satisfied defiance. Settle lowers the dividers toward
idle. Right hand retains the two-legged tool, left supports the tablet. No extra
hand, new box, third divider leg or painted Ember. Original tablet light remains.

## Registration

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Crown-to-sole landmarks
normalize to idle's 627-pixel body height. Foot-center x185.5 retains her offset
stance instead of centering at x256. Lowest visible pixel y756 is two pixels
below idle. Check individual sandal contacts and the return to idle in-game;
small generated tool, tablet, jewelry and cloth differences remain review items.

The GIF loops claim poses only, without idle, text or incoming Ember; it is not
a gameplay recording. Existing default/attack sprites and wardrobe are unchanged.

## Receiving Sockets

Final sprite pixels, top-left origin. Gather/Hold: between divider tips above
tablet edge. Settle tracks the tool as it lowers. Art annotations need engine
verification and attachment interpolation.

| Pose | x | y |
| --- | --- | --- |
| Gather | 310 | 287 |
| Hold | 308 | 286 |
| Settle | 94 | 541 |

Hold arrival socket: **(308, 286)**. Mirror x using 511 minus x, then apply the
figure transform. Keep the incoming Ember distinct from the tablet drawing.

## Sources

Exact prompts, source PNGs, landmarks, registration, layered ORA, contact sheet
and 600 ms GIF are included. Runtime candidates are under
`game/assets/figures/a-flood-survivor-iset-nara/claim-*.png`. This pass changed no
audio, dialogue, rules or playback code.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-iset-nara docs/art-specs/ember-claim/a-flood-survivor-iset-nara/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/a-flood-survivor-iset-nara/body-landmarks.json
```
