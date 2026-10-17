# Proportion and Size Registration

Read when creating a sequence or correcting shrinkage, growth, or scale drift.

## Body Size Is Not Canvas Fit

The board draws the attack textures with the idle texture's transform. Smaller
painted bodies inside equally sized canvases therefore appear to shrink.
An outstretched hand or a larger alpha halo can make the default packing helper
reduce the common scale of every pose. Matching canvas, margins, and baseline
alone will not catch that regression.

Compare at a shared foot anchor and display scale:

- Crown-to-sole height for an upright humanoid, excluding effects and raised props.
- Head size, shoulder width, waist/hip level, torso and leg lengths, and boot size.
- Both foot contact positions and their ordering, including return to idle.
- For nonhumanoids, reviewed chassis/body landmarks and wheel/contact spacing.

Uniform scaling can reconcile an overall source-size difference. If anatomy itself
drifts (such as the head getting smaller or legs getting longer), correct the art;
matching total height will conceal rather than fix that defect. Do not stretch axes
independently. Allow intentional pose compression only when the choreography needs
it, with a proportion-preserving reference and explicit review.

## Reviewed Landmark Normalization

The repo helper supports optional semantic body landmarks:

```text
python tools/prepare_attack_sequence.py CHARACTER SOURCES_JSON --body-landmarks BODY_LANDMARKS_JSON
```

Schema (coordinates are examples, not values to reuse for another character):

```json
{
  "idle": {"crown_y": 106, "sole_y": 751},
  "ready": {"crown_y": 106, "sole_y": 1471},
  "raise": {"crown_y": 197, "sole_y": 1493},
  "brace": {"crown_y": 173, "sole_y": 1461},
  "fire": {"crown_y": 14, "sole_y": 1430},
  "recoil": {"crown_y": 173, "sole_y": 1455},
  "recover": {"crown_y": 201, "sole_y": 1501}
}
```

Inspect and annotate idle and every source; include all six pose keys. Measurements
are source-image coordinates, inclusive: `sole_y - crown_y + 1`. The helper applies
uniform anatomical normalization per source to the idle span, then translates the
feet to the output baseline. Registration records each effective source scale and
landmarks. This is not arbitrary fitting to weapon/glow extents.

When the existing idle footprint is off-center, preserve it. The landmark JSON
may set top-level `target_anchor_x` (output pixels; default 256), with each pose's
`foot_center_x` recording its source contact center. Iset-Nara uses output x185.
Compare both sandal contacts to idle and add a footprint regression rather than
assuming every idle was painted at x256. Do not move the idle to fit the helper.

Opaque alpha bounds can assist only when crown and soles are truly the top/bottom
opaque features. Verify visually: a raised hand, antenna, tall hat, effect, or a
different pose can invalidate that shortcut. The crown-to-sole mode is for suitable
upright figures, not a generic solution for curled creatures or crouching attacks.
Record the reviewed landmark file and full rebuild command with each delivery.

If idle-sized packing violates margins, the landmark mode should fail rather than
reduce body size. Shorten reach with an elbow bend, compact a tool arc, or reduce
effect spread through an image edit. Preserve identity, stance and accepted palette.
Do not clip anatomy, shrink idle, or change global board rendering to hide the issue.

## Regression Verification

For Orlov, all opaque hands/effects stay below the crown, so
`test_orlov_attack_keeps_idle_body_height` measures alpha >= 0.5 crown-to-sole height
and allows +/-2 output pixels. Reuse that check only for characters with the same
measurement validity; otherwise test their reviewed landmarks/dimensions.

Review a same-scale idle-plus-six-poses comparison and same-position browser idle,
anticipation, impact, follow-through and return-to-idle captures. Check internal
proportions visually as well as total height. Recheck alpha compositing and margins
after corrections. A passing height assertion does not prove consistent anatomy.
