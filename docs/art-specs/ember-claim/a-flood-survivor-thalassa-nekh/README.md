# Thalassa-Nekh: Feed Us

Art approved by the user on 2026-10-23. Visual playback is not verified.
Shared audio status is tracked separately in the production queue.

## Performance

Approved wording from `data/ember_lines.json`, preserved verbatim:

- Claim: "Yessss....."
- Big claim: "Feed us!"

Gather draws both palms inward with a hungry pleased smile. Hold cups the empty
space near her sternum, lifts her gaze in delight, and briefly reveals compact
three-fold opal-cyan Seraph shoulder fans. Settle reopens the arms as the fans
disappear into ordinary water. This is satisfaction, not a new attack. Her
normal outfit remains; exactly two hands, no extra faces, physical trophy,
painted Ember or incoming projectile. Existing water remains identity art.

## Registration

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Crown-to-sole landmarks
normalize to idle's 676-pixel body span, not the moving water/fan bounds.
Visible-foot center x251 stays within three pixels of reviewed idle placement.
Lowest visible pixel y756 is eight pixels below idle. Check the return to idle,
individual toe contacts and knee position in-game. Small generated water,
cloth, jewelry and body-detail variations remain review items.

The GIF loops claim poses only, without idle, text or incoming Ember; it is not
a gameplay recording. Existing default/attack sprites and wardrobe are unchanged.

## Receiving Sockets

Final sprite pixels, origin top-left, above/between cupped palms. Art annotations
need engine verification and attachment interpolation as the hands reopen.

| Pose | x | y |
| --- | --- | --- |
| Gather | 255 | 250 |
| Hold | 251 | 235 |
| Settle | 251 | 310 |

Hold arrival socket: **(251, 235)**. Mirror x using 511 minus x, then apply the
figure transform. Preserve a central chest anchor as hands reopen in Settle.

## Sources

Exact prompts, source PNGs, landmarks, registration, layered ORA, contact sheet
and 600 ms GIF are included. Runtime candidates are under
`game/assets/figures/a-flood-survivor-thalassa-nekh/claim-*.png`. This pass made
no audio, dialogue, gameplay or playback changes.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-thalassa-nekh docs/art-specs/ember-claim/a-flood-survivor-thalassa-nekh/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/a-flood-survivor-thalassa-nekh/body-landmarks.json
```
