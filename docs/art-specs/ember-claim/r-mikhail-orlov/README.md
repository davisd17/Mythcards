# Mikhail Orlov: Perfectly Calculated

Art approved by the user on 2026-10-22. No sound or Godot claim integration.

## Performance

Approved wording from `data/ember_lines.json`, preserved verbatim:

- Claim: "perfectly calculated"
- Big claim: "I'm so powerful i'm fading"

Gather inspects the receiving palm with a pleased half-smile. Hold lifts the
palm in a confident presentation, chin up and shoulders open: vindication with
a touch of exhilaration. Settle lowers the hand without losing his satisfaction.
This supersedes the original worried-reading sketch. The character does not
literally fade; the same art serves both claim lines.

The right hand continuously holds the diagnostic instrument. The left hand is
empty, with no painted Ember or orange palm sigil. Existing green instrument
glass remains. No new prop, extra hand or attack effect.

## Registration And Review

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Reviewed crown-to-sole
landmarks normalize to idle's 650-pixel body height, avoiding independent
effect-bounds fitting. The receiving arm does not determine scale.
Foot-center target x267 is within two pixels of idle placement; lowest visible
pixel is y756. Idle's lowest visible pixel is y751, so the five-pixel transition
and individual boot contacts still require in-game visual verification.
Minor generated coat, stance and instrument-detail variations remain review items.

The GIF loops only the claim poses, without idle, text or engine-rendered light;
it is not a gameplay recording. Default and attack sprites are untouched.

## Receiving Sockets

Coordinates in final runtime pixels, top-left origin, above the open palm.
These are art annotations pending verification with engine effects.

| Pose | x | y |
| --- | --- | --- |
| Gather | 410 | 228 |
| Hold | 458 | 165 |
| Settle | 443 | 245 |

Hold arrival socket: **(458, 165)**. Mirror x with 511 minus x, then apply the
figure transform. Interpolate the attachment as the receiving hand moves.

## Sources

Exact prompts, source PNGs, anatomical landmarks, registration, contact sheet,
three-layer ORA and 600 ms review GIF are included. Runtime candidates are in
`game/assets/figures/r-mikhail-orlov/claim-*.png`. Wardrobe, dialogue and gameplay
were not changed.

```powershell
python tools/prepare_attack_sequence.py r-mikhail-orlov docs/art-specs/ember-claim/r-mikhail-orlov/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/r-mikhail-orlov/body-landmarks.json
```
