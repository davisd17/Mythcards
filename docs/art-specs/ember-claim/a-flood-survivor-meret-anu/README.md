# Meret-Anu: Because I Choose

Art approved by the user on 2026-10-23. Visual playback is not verified.
Shared audio status is tracked separately in the production queue.

## Performance

Approved wording from `data/ember_lines.json`, preserved verbatim:

- Claim: "Nothing more will be lost."
- Big claim: "Atlantis survives because I choose."

Gather brings the free hand to the archive with a pleased downward glance.
Hold rests fingertips over the closed lid seam and lifts her chin in composed
authority. Settle releases that hand toward idle while retaining her satisfied
gaze. Right arm always supports the same closed casket. No opened lid, contents,
new prop, crown swap, extra hand or painted Ember is included.

## Registration And Review

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Crown-tip to grounded hem
normalizes to idle's 733-pixel span. The crown is included in every landmark,
not treated as an effect. Hem-center x253.5 matches idle placement; lowest visible
pixel y756 is four pixels below idle. Initial Gather/Hold trains were corrected
in ImageGen to fit without reducing overall figure height. Hem spread still
varies between poses, especially Settle, and must be reviewed through the idle
transition in-game. Jewelry/casket/fabric details also remain visual-review items.

The GIF loops claim poses only, without idle, text or engine effects; it is not
a gameplay recording. Existing default/attack sprites and wardrobe are untouched.

## Receiving Sockets

Final runtime pixels, origin top-left, above archive lid/clasp, clear of fingers.
Review annotations need verification with engine effects.

| Pose | x | y |
| --- | --- | --- |
| Gather | 205 | 225 |
| Hold | 205 | 225 |
| Settle | 205 | 225 |

Hold arrival socket: **(205, 225)**. Mirror x using 511 minus x, then apply the
figure transform. Keep the arrival point on the closed archive, not her hand.

## Sources

Exact generation and hem-correction prompts, selected source PNGs, landmarks,
registration, three-layer ORA, contact sheet and 600 ms GIF are included.
Runtime candidates: `game/assets/figures/a-flood-survivor-meret-anu/claim-*.png`.
This pass changed no dialogue, sound, rules or playback code.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-meret-anu docs/art-specs/ember-claim/a-flood-survivor-meret-anu/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/a-flood-survivor-meret-anu/body-landmarks.json
```
