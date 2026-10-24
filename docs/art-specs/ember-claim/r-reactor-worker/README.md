# Reactor Worker: Photo Over Heart

Art approved by the user on 2026-10-21. Not integrated; sound has not been produced.

Instead of a victory flourish, he checks the family photo, holds it over his
heart, then returns to readiness. His wrench stays lowered and both feet stay
planted. This is a protective acknowledgement of survival, not a trophy pose.

- Gather: 120 ms, glance toward the photo and draw it inward.
- Hold: 360 ms, photo over heart, a small breath and lifted gaze.
- Settle: 120 ms, photo moves back out toward the idle position.

The review GIF loops the three poses without an idle pause. It is not a recording
of game playback. Runtime candidates are 512 x 768 RGBA, with a lowest visible
pixel at y=756. Anatomical height is normalized to the idle's 733-pixel span;
the horizontal foot anchor matches the idle's offset stance, not canvas center.
Small generated changes in glove/photo detail remain subject to art review.

## Receiving Sockets

Measured in final runtime-canvas pixels, origin top left. The arrival point sits
above the photo, away from its faces. Engine-rendered Ember light is intentionally
absent from these sprites. Mirrored x is 511 minus x.

| Pose | x | y |
| --- | --- | --- |
| Gather | 344 | 170 |
| Hold | 344 | 170 |
| Settle | 395 | 225 |

Hold arrival socket: **(344, 170)**. Coordinates are art annotations pending
in-game visual verification, not a registered runtime contract yet.

## Files And Reproduction

Sources, exact prompts, anatomical landmarks, registration, contact sheet,
three-layer OpenRaster master and 600 ms review GIF are in this directory.
Candidate sprites are under `game/assets/figures/r-reactor-worker/claim-*.png`.
No wardrobe entries, gameplay code, sound or dialogue have been changed.

```powershell
python tools/prepare_attack_sequence.py r-reactor-worker docs/art-specs/ember-claim/r-reactor-worker/sources.json --kind claim --body-landmarks docs/art-specs/ember-claim/r-reactor-worker/body-landmarks.json
```
