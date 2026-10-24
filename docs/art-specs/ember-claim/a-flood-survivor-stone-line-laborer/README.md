# Stone-Line Laborer: A Way Forward

Art approved by the user on 2026-10-22. Visual playback is not verified.
Audio work is tracked separately in the shared production queue.

## Performance

Approved dialogue from `data/ember_lines.json`, preserved verbatim:

- Claim: "The others still need a road."
- Big claim: "This time, everyone gets through."

He receives with an open palm, lifts his chin into a warm resolved smile, then
lowers the hand and settles. This is communal relief and hope, not a trophy
display. His working tool remains low in the right hand; the left palm is empty.
No stone marker, new prop, painted Ember, extra hand or attack effect is included.

## Registration

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Crown-to-sole landmarks
normalize to idle's 735-pixel body height. Foot-center x258.5 is within one pixel
of the reviewed idle footprint. Lowest visible pixel is y756, two pixels below
idle. Individual foot contacts and small generated rope/tool/cloth differences
still need visual review in-game. The GIF loops claim poses only, with no idle,
text or incoming Ember; it is not a gameplay recording.

## Receiving Sockets

Final runtime coordinates, top-left origin, above the free palm. Art annotations
need engine verification and interpolation with the moving hand.

| Pose | x | y |
| --- | --- | --- |
| Gather | 437 | 242 |
| Hold | 438 | 256 |
| Settle | 383 | 361 |

Hold arrival socket: **(438, 256)**. Mirror with x = 511 minus x, followed by
the figure transform. No glow is baked into these sprites.

## Sources

Exact prompts, source PNGs, landmarks, registration, layered ORA, contact sheet
and 600 ms GIF are included. Runtime candidates are in
`game/assets/figures/a-flood-survivor-stone-line-laborer/claim-*.png`.
This art pass changed no existing default/attack sprites, wardrobe, sound,
dialogue or gameplay logic.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-stone-line-laborer docs/art-specs/ember-claim/a-flood-survivor-stone-line-laborer/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/a-flood-survivor-stone-line-laborer/body-landmarks.json
```
