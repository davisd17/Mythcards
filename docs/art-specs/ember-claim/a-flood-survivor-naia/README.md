# Naia: Serve Life

Art approved by the user on 2026-10-22. Visual playback is not verified.
Audio status remains separately tracked in the shared queue.

## Performance

Approved wording from `data/ember_lines.json`, preserved verbatim:

- Claim: "No one will use you now."
- Big claim: "May you all serve life!"

Gather draws the shield close with a protective glance. Hold lifts her gaze,
opens the shoulders and lets relief become a warm confident smile. Settle
reopens her guard without losing that resolve. The shield and curved blade
remain held in their original hands; no third hand or sarcophagus is invented.
No attack, trophy or incoming Ember light is painted into the sprite.

## Registration And Review

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Reviewed crown-to-sole
landmarks use a 666-pixel anatomical span; the idle silhouette including loose
hair extends four pixels above the selected crown. Foot-center x280 is about
nine pixels right of idle to accommodate the full curved blade within safe
margins without shortening it. Lowest visible pixel y756 is six pixels below
idle. These idle transitions and individual boot contacts need in-game review.
Small generated armor, braid, cloth and weapon-detail differences remain review
items. Overall scale normalization is not proof of exact anatomical continuity.

The GIF loops claim poses only, without idle, text or engine effects; it is not
a gameplay recording. Existing default/attack sprites and wardrobe are unchanged.

## Receiving Sockets

Final sprite pixels, origin top-left, above the shield's inner upper edge, clear
of her face. Art annotations require verification with engine effects.

| Pose | x | y |
| --- | --- | --- |
| Gather | 345 | 250 |
| Hold | 366 | 212 |
| Settle | 374 | 266 |

Hold arrival socket: **(366, 212)**. Mirror x using 511 minus x, then apply the
figure transform. Interpolate with the shield as its angle changes.

## Sources

Exact prompts, source PNGs, landmarks, registration, three-layer ORA, contact
sheet and 600 ms GIF are included. Runtime candidates are under
`game/assets/figures/a-flood-survivor-naia/claim-*.png`. This pass changed no
sound, dialogue, gameplay rules or playback code.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-naia docs/art-specs/ember-claim/a-flood-survivor-naia/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/a-flood-survivor-naia/body-landmarks.json
```
