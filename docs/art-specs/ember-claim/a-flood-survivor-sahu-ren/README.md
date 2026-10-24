# Sahu-Ren: A Memory Carried

Art approved by the user on 2026-10-23. Visual playback is not verified.
Shared audio status is tracked separately in the production queue.

## Performance

Approved dialogue from `data/ember_lines.json`, preserved verbatim:

- Claim: "I will remember you."
- Big claim: "So many lives. None forgotten."

Gather draws the right hand toward his heart. Hold rests it at the sternum with
a small bowed acknowledgement. Settle returns the hand above the stone archive
and lifts his gaze. The left forearm continuously supports the slab. This is
sincere remembrance, not a boast or fearful reaction. Existing cyan markings
remain; no incoming Ember, new face, extra hand or attack light is painted in.

## Registration

Three 512 x 768 RGBA candidates, 120 / 360 / 120 ms. Crown-to-sole landmarks
normalize to idle's 675-pixel body height. Foot-center x268.5 matches the reviewed
idle footprint. Lowest visible pixel y756 is seven pixels below idle, so check
the return transition and individual sandal contacts in-game. Small generated
slab, shell, robe and marking differences remain visual-review items.

The GIF loops claim poses only, without idle, text or incoming Ember. It is not
a gameplay recording. Existing default/attack sprites and wardrobe are untouched.

## Receiving Sockets

Final runtime pixels, origin top-left, forward of sternum/right palm; clear of
the slab. Art annotations need in-engine verification and attachment interpolation.

| Pose | x | y |
| --- | --- | --- |
| Gather | 260 | 242 |
| Hold | 260 | 244 |
| Settle | 302 | 260 |

Hold arrival socket: **(260, 244)**. Mirror x using 511 minus x, then apply the
figure transform. Keep the arriving light separate from existing body markings.

## Sources

Exact prompts, source PNGs, landmarks, registration, layered ORA, contact sheet
and 600 ms review GIF are included. Runtime candidates are under
`game/assets/figures/a-flood-survivor-sahu-ren/claim-*.png`. This pass changed
no audio, dialogue, gameplay rules or playback code.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-sahu-ren docs/art-specs/ember-claim/a-flood-survivor-sahu-ren/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/a-flood-survivor-sahu-ren/body-landmarks.json
```
