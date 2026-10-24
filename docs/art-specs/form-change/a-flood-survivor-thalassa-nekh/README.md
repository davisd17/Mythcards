# The Drowned Seraph Takes Form

## Current Direction: V2 Spectral Manifestation

The user-approved direction is the separate towering entity from the original
character card, not Nekh transformed into armor. V1 below is superseded and kept
only as an unregistered review archive. Do not install its armored textures.

- `seraph-manifestation-concept-v2.png`: approved visual direction.
- `seraph-entity-source-v2.png`: isolated entity generation, genuine alpha.
- `game/assets/figures/a-flood-survivor-thalassa-nekh/seraph-entity-v2.png`:
  512 x 768 production layer, prepared with the existing figure normalizer.
- `seraph_manifestation.gd`: state-driven presentation layer behind Nekh.

Nekh's default figure and six attack images remain unchanged. The entity is drawn
separately at 1.42 times her canvas height, capped against the view's top edge;
the compact spirit peeks over her inner shoulder when headroom is tight.
Nekh is never refitted or shrunk to accommodate it. Her original outfit, body and
foot anchor persist. Attack mirroring and movement apply to both layers. The
spirit fades with her defeat ghost, while labels remain above the figure.

Successful L3 activation reveals the entity over 600 ms, then retains it at 58%
opacity. Existing registered attack impact timing drives a brief rise to 88%.
Reduced motion shows a steady final manifestation immediately. Recreated views
read the model flag directly without replaying the reveal or granting bonuses.
No gameplay rules, cosmetics catalog or default attack timing were changed.

This layered approach does not require twelve regenerated human poses. The
shared claim-art playback is still a separate outstanding feature; its eventual
implementation must retain this overlay and not use the obsolete armored form.
Visual gameplay approval of size, translucency and board crowding is still needed.

## Archived V1 Handoff

Art review candidate, 2026-10-23. Not registered or verified in-game.

## Deliverables

- `transform-1-awaken.png`: the human vessel gathers power; compact fans appear.
- `transform-2-manifest.png`: armor and greave emerge, mantle lengthens.
- `transform-3-seraph.png`: full armored form and long folded opal mantle.
- `seraph-form-v1.png`: identical standalone persistent-form candidate.

All runtime candidates are under `game/assets/figures/a-flood-survivor-thalassa-nekh/`.
Existing `default.png`, `drowned-seraph.png`, attack and claim art are preserved.
Exact prompts, selected sources, anatomical landmarks, registration, three-layer
ORA, contact sheet and GIF are included here. No feathers, extra head/arms,
weapons or new attack projectile. Same recognizable human identity remains.

## Timing And Registration

Proposed transformation timing: Awaken 150 / Manifest 200 / Seraph 250 ms.
This 600 ms duration is an art proposal, not a new rule or implemented timer.
In a build, the final texture must remain after the transition, not loop back.
The review GIF repeats the three beats for inspection only.

512 x 768 RGBA, lowest visible pixel y756, anatomical crown-to-sole span 676 px,
forward-foot center x251. Scale derives from anatomy, not expanded mantle bounds.
Panels were folded downward to preserve body size within the existing canvas.
Default baseline y748 differs by eight pixels; review the idle transition and
bare-foot to armored-foot change in-game. Generated jewelry, mantle and anatomy
details remain subject to designer review.

## Engineering Handoff

Inspected source: `game/scripts/systems/abilities/a_thalassa_nekh_ability.gd`.
Activation sets `ability_uses_this_match["seraph_form"] = true`, grants +2 ATK
and +1 RANGE, once per match at Level 3. The form lasts for the rest of the match.
Do not trigger just because Level 3 was reached, or change AP/stats/duration.

The current figure catalog is cosmetic-only. Do not register this as merely a
user-selected costume or let a cosmetic selection activate the gameplay ability.
A future form resolver should derive the texture from authoritative character
state, render transition once after successful activation, and restore the final
form on save/load/reconnect without replaying activation or stat bonuses.

Form-specific attack and claim sequences are NOT produced in this package.
They need their own six attack and three claim poses after this form is approved;
do not silently switch back to default clothing during those animations.
The existing default claim's brief fans are not this persistent form.

Required verification: activation once, failed activation, mirrored placements,
same visual scale, input not blocked, persistent texture across actions/save-load,
and match-ending behavior. No runtime code, wardrobe or sound changes made here.

```powershell
python tools/prepare_attack_sequence.py a-flood-survivor-thalassa-nekh docs/art-specs/form-change/a-flood-survivor-thalassa-nekh/sources.json --kind transform --body-landmarks docs/art-specs/form-change/a-flood-survivor-thalassa-nekh/body-landmarks.json
```

After regeneration, copy transform-3-seraph.png to seraph-form-v1.png to keep the
standalone candidate identical. Do not overwrite the existing older outfit.
