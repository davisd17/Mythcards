# Ahesu: The Deep Keeps It

Art approved by the user on 2026-10-22. Visual playback is not verified.
Shared audio work is tracked separately in the production queue.

## Performance

Approved nonverbal lines from `data/ember_lines.json`, preserved verbatim:

- Claim: "(a low rumble beneath the stone)"
- Big claim: "(the sealed depths answer)"

Gather lowers the head toward the receiving space. Hold curls the upper neck
inward in contained satisfaction. Settle lifts the head in a proud acknowledgement.
The jaw stays closed: no strike, swallowing, trophy, rider or new effect. Existing
cyan markings remain identity art; the incoming Ember is engine-rendered.

## Registration

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Fixed coil-width landmarks
normalize to idle's 402-pixel span, rather than fitting each changing neck height.
Grounded coil-center x256.5 and lowest visible pixel y756 match the idle baseline.
The Settle head rises above idle and must be reviewed through the transition back
to default in-game. Small generated coil/scale/ring differences remain review
items, despite consistent overall width. The GIF loops claim poses without idle,
dialogue or incoming Ember and is not a gameplay recording.

## Receiving Sockets

Final sprite pixels, origin top-left, in negative space inside the upper coil,
beneath the chin. Review annotations need engine verification.

| Pose | x | y |
| --- | --- | --- |
| Gather | 324 | 518 |
| Hold | 330 | 530 |
| Settle | 320 | 456 |

Hold arrival socket: **(330, 530)**. Mirror x with 511 minus x, followed by the
figure transform. Keep Ember light separate from the existing chest markings.

Mounted ownership: only play this claim when Ahesu is the credited claimer;
do not animate Ahesu as well as a claiming mounted rider.

## Sources

Exact prompts, source PNGs, coil-width landmarks, registration, layered ORA,
contact sheet and 600 ms review GIF are included. Runtime candidates are under
`game/assets/figures/a-flood-survivor-ahesu/claim-*.png`. This art pass changed
no existing default/attack sprites, wardrobe, audio, dialogue or rules.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-ahesu docs/art-specs/ember-claim/a-flood-survivor-ahesu/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/a-flood-survivor-ahesu/body-landmarks.json
```
