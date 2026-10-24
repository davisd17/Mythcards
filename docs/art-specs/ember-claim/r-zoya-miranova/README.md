# Zoya Miranova: Which Of Us?

Art approved by the user on 2026-10-22. Claim visual playback is not verified.
Shared audio work is tracked separately in the production queue.

## Performance

Approved dialogue from `data/ember_lines.json`, preserved verbatim:

- Claim: "Which of us did that?"
- Big claim: "I collect followers"

A curious head cant and hand rising toward the temple lead into a knowing,
slightly unsettling smile. Fingertips pause short of her temple; then her hand
lowers and head straightens. Existing cyan ribbons remain identity art, not
new claim light. No extra face, follower figure or painted Ember is included.

## Registration

Three 512 x 768 RGBA candidates, Gather 120 / Hold 360 / Settle 120 ms.
Anatomical crown-to-sole landmarks normalize to idle's 662-pixel body span;
spectral bounds do not determine scale. Foot-center x284 is within three pixels
of the reviewed idle footprint. Lowest visible pixel y756 follows the claim
contract; idle is y747, requiring a nine-pixel transition check in-game.
Individual toe contacts, cloth and ribbon variations remain visual review items.

The GIF loops claim poses only, without idle, text or incoming Ember. It is not
a gameplay recording. Existing default/attack sprites and wardrobe are untouched.

## Receiving Sockets

Final runtime pixels, origin top-left; beside fingertips, clear of the eyes.
Coordinates are art annotations pending engine verification.

| Pose | x | y |
| --- | --- | --- |
| Gather | 180 | 160 |
| Hold | 184 | 150 |
| Settle | 184 | 405 |

Hold arrival socket: **(184, 150)**. Mirror x using 511 minus x, then apply the
figure transform. Interpolate the attachment as the hand lowers.

## Sources

Exact prompts, source PNGs, landmarks, registration, layered ORA, contact sheet
and 600 ms review GIF are included. Runtime candidates are under
`game/assets/figures/r-zoya-miranova/claim-*.png`. This art pass made no sound,
dialogue or gameplay changes.

```powershell
python tools/prepare_attack_sequence.py r-zoya-miranova docs/art-specs/ember-claim/r-zoya-miranova/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/r-zoya-miranova/body-landmarks.json
```
