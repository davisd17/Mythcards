# Elena Morozova: Signal Recognized

Art approved by the user on 2026-10-22. Audio status is tracked separately in the production queue; claim visual playback is not verified.

## Performance

Approved wording from `data/ember_lines.json`, preserved verbatim:

- Claim: "The pattern continues."
- Big claim: "I see you now!"

Gather lifts the electrode cap while she listens, smiling toward the instrument.
Hold opens her posture and lifts her gaze with pleased recognition. Settle
lowers the cap toward idle while keeping that new confidence. The closed ledger
remains tucked under the left arm; the right hand retains the cap. Exactly two
hands, both occupied. No worn cap, opened book or signal-attack effects.

## Registration

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Reviewed crown-to-sole
landmarks normalize all poses to idle's 599-pixel body height. Foot-center x352.5
preserves her offset stance. Lowest visible pixel y756 follows the claim contract;
idle is y747, so check the nine-pixel idle transition and individual boot contacts
in-game. Small generated differences in cap wiring, ledger and coat remain
visual-review items. No painted Ember or other new light is included.

The GIF loops claim poses only, without idle, dialogue or engine effects. It is
not a gameplay recording. Default/attack sprites and wardrobe are unchanged.

## Receiving Sockets

Coordinates in final runtime pixels, origin top-left, above the electrode cage
rim and clear of the gripping hand. Art annotations need in-engine verification.

| Pose | x | y |
| --- | --- | --- |
| Gather | 220 | 290 |
| Hold | 224 | 275 |
| Settle | 213 | 440 |

Hold arrival socket: **(224, 275)**. Mirror x with 511 minus x, followed by the
figure transform. Interpolate attachment as the cap lowers.

## Sources

Exact prompts, source PNGs, landmarks, registration, three-layer ORA master,
contact sheet and 600 ms review GIF are included. Runtime candidates are under
`game/assets/figures/r-elena-morozova/claim-*.png`. No dialogue, sound, rules or
runtime playback changes were made.

```powershell
python tools/prepare_attack_sequence.py r-elena-morozova docs/art-specs/ember-claim/r-elena-morozova/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/r-elena-morozova/body-landmarks.json
```
