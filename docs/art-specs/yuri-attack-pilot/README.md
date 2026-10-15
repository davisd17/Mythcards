# Major Yuri Volkov Attack Art Pilot

Delivery for `LLD-figure-animation.md`, Section 8, and
`docs/art-specs/attack-windup-spec.html`. This pilot supplies art for review before
commissioning the remaining 13 characters.

## Runtime Assets

Folder: `game/assets/figures/r-yuri-volkov/`

| File | Pose | Hold |
| --- | --- | --- |
| attack-1-ready.png | Rifle at low ready, watching the target | 100 ms |
| attack-2-raise.png | Rifle rises from chest toward shoulder | 100 ms |
| attack-3-brace.png | Braced shoulder and bent knees before firing | 130 ms |
| attack-4-fire.png | Rifle shot toward screen-right, compact muzzle flash | 60 ms |
| attack-5-recoil.png | Rifle kicks up, upper body absorbs the shot | 90 ms |
| attack-6-recover.png | Rifle lowered toward idle | 120 ms |

The six-pose, 600 ms sequence supersedes the four-frame pilot after designer feedback
that the sequence should feel less choppy. Playback should also blend between poses.

Every frame is a transparent RGBA 512x768 PNG. Registration uses the boot contact at
`(256, 756)`. The original four poses retain their shared scale; the two new poses
are registered together with one shared scale against that set. All six use
translation-only boot alignment. There is no independent per-frame bounds fit.
Inspect `registration.json` for the exact source coordinates and shared scale.

## Review And Source Files

- `contact-sheet.png`: six labeled frames at half resolution.
- `attack-preview.gif`: looping sequence at the specified hold durations; this is an
  art preview, without the engine's additional blend, lean, or lunge.
- `source-sheet.png`: original four-pose raster master.
- `raise-source.png` and `recoil-source.png`: generated masters for the two additions.
- `four-frame-v1/`: archived superseded runtime files, excluded from playback.
- `r-yuri-volkov-attack.ora`: layered OpenRaster source, supported by Krita and GIMP.
  Each registered pose is a separate full-canvas layer. These are rendered pose layers,
  not a rig or independently painted clothing/limb layers.
- `prompts.md`: generation and correction prompts.
- `registration.json`: reproducible packing metadata.

Run `tools/prepare_attack_pilot.py SOURCE_SHEET.png --raise-pose RAISE_SOURCE.png
--recoil-pose RECOIL_SOURCE.png` with a Python environment containing Pillow to rebuild
the delivery. Do not use the older per-figure bounds fitter. The explicit file ordering
and durations are in `registration.json`; do not infer them from old four-frame names.

## Design Notes And Review Gate

- The helmet stays secured at the left hip, leaving both hands free for the rifle.
  This is a deliberate transition from the default's carried helmet and needs review
  when blending back to idle.
- Wind-up uses a firing brace rather than a large melee-style backward swing.
- Generative artwork preserves the costume and broad identity, but is not guaranteed
  to reproduce every seam or weapon detail exactly. Review the silhouette at 80 pixels
  and compare the registered frames against `default.png` before approval.
- A pose's visible width must not drive independent engine rescaling/recentering.
  Reuse the default figure's transform and fixed canvas anchor across all attack frames.
- Existing `FigureCatalog` and `FigurePose` do not yet play these PNGs. The next engine
  task is the Phase 6 frame integration, mirroring and procedural fallback in the spec.
- Ahesu's stray-wheel cleanup is still due with Ahesu's own frame commission, after
  the Yuri pilot has been reviewed.

No gameplay rules, wardrobe entries, or animation playback were changed by this art
delivery. The pull's local typography conflicts were resolved separately.
