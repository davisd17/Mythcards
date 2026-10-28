# Mounted Character Artwork

Status: implemented locally; awaiting user art review. Not pushed or exported to Web.

Ahesu V2: the user approved the giant-serpent scale study. Both Sahu-Ren and
Meret-Anu now use that scale across ready/idle and all six attack poses. The
serpent dominates the composite; neither rider grows during attacks. Review the
close-up `ahesu-v2-attacks.gif` and `ahesu-v2-pairings.jpg`. New exact prompts are
in `AHESU_V2_PROMPTS.md`; smaller v1 masters remain in `sources-v1/`. VERA-7 art
was not regenerated.

## Current Pairings

| Rider | Mount | Art |
| --- | --- | --- |
| Dr. Mikhail Orlov | VERA-7 | Seated operator, green reactor-palm attack |
| Irina Karpova | VERA-7 | Seated operator, pistol attack, keys retained |
| Sahu-Ren | Ahesu | Astride serpent, tablet-supported memory cast |
| Queen Meret-Anu | Ahesu | Side-saddle, casket retained, tide-palm cast |

These are the four same-team Hero/Leader combinations in the current playable
Closed City and Flood Survivors rosters, not four distinct mount characters.
Other combinations retain the existing fallback. No mount eligibility rules changed.

## Delivery

- Runtime assets: `game/assets/figures/mounted/<pair>/`.
- Manifest: `game/assets/figures/mounted/catalog.json`; cosmetic-only, separate from wardrobe ownership.
- Masters: each pair's `sources/` directory here; exact built-in ImageGen prompts in `PROMPTS.md`.
- Preview: `mounted-pairings.jpg`, `mounted-attacks.gif`, individual contact sheets and GIFs.
- Rebuild: `python tools/prepare_mounted_figures.py` from the repository's Python environment with Pillow.
- Sources are portable repository-relative paths in `production-inputs.json`.

512 x 768 RGBA canvases, transparent background, contact baseline y756, 24px side
and 18px top safe margins. Six poses: 100/100/130/60/90/120ms, total 600ms,
single impact at 330ms. Ready is also idle; Irina's recover intentionally settles
back to corrected ready so keys and pistol do not switch hands.

Each pair is registered using its supporting wheels or coil, with one common
export scale. Reviewed source normalization corrects Irina ready/recover by 0.94
using mast-to-wheel and crown-to-contact landmarks. The Ahesu v2 sources share
their native scale and need no source normalization. These are source-size corrections, not per-frame
effect-bound fitting. Registration records retain the factors and anchors.

## Runtime Behavior

The board selects the actual rider/mount/default-outfit combination from match
state. Only the rider draws; the mount is part of the composite artwork. Idle,
movement hop/slide, selection, recoil, ability cast, turn-ready and level-up use
the existing figure animation system. Mounted attacks use the pair's six frames,
including against placed objects; they never temporarily show an on-foot rider.
Leftward attacks mirror the entire pair. As with existing attack art, vertical
targets reuse side-facing art. No separate directional sets or locomotion cycles.

Attack frames always use idle's draw rectangle. The mounted silhouette fits
within 0.98 tile width and 1.28 tile height; labels and tile hit targets do not move.
This is a larger composite, not a reduction of the original on-foot character.
Dismount restores both original figures. A form change during an attack stops
stale pose layers. Defeat snapshots the mounted appearance before model links
are cleared, producing one composite ghost rather than a standing rider or two
overlapping ghosts. Alternate outfits without matching mounted art are not
silently redressed into the default outfit.

No stats, AP, movement rules, ability effects, music or board themes changed.
Existing claim artwork playback is outside this delivery; no new celebration
system or mounted-specific locomotion animation is introduced.

Mounted Ember claims: the designer approved reusing the riding character's
normal/big-claim text with no separate celebration animation. Keep the mounted
artwork and its existing attack-to-idle playback; never swap to on-foot claim
frames or play a second mount celebration. The existing rider sting and generic
Ember feedback remain. This is integrated with the latest claim-text playback,
with mounted pairs exempt from the on-foot claim stretch. See the mounted
exception in `../ember-claim/SPEC.md` for the implementation contract.

## Verification

After integration with the latest GitHub claim/network changes: 677 tests / 4,733
assertions passed, including both giant-Ahesu revisions and mounted rider-line
selection with no on-foot claim sprites. The full suite needs permission to write
its temporary Godot user-data save files for the online-session tests.
Existing orphan-UI and
shutdown RID/ObjectDB warnings remain; no script or test failures. Native review
passed all four pairings. Browser/Web-export testing was not run for this delivery.

`tools/run_game_tests.ps1` covers the complete game suite, including mounted
catalog membership, transparent assets, canvas/margins/contact, two-percent
height continuity, timing/impact, correct frame selection, mirroring, dismount,
defeat ownership, object attack and unchanged label geometry.

Native visual fixture:

```powershell
& (./tools/find_godot.ps1) --path game --audio-driver Dummy `
  --log-file "$PWD/build/mounted-review.log" `
  res://tests/helpers/mounted_visual_review.tscn
```

All four pass real mount, move, attack and dismount requests. The fixture arranges
three pieces on the board, supplies a normal four-AP pool, and refreshes the rider
through TurnManager before dismounting, since attacking spends its character AP.
`qa/` contains desktop 1440x960 mounted/impact and phone 390x844 mounted/dismounted
captures. Captures freeze presentation time at impact for comparison and use
the real GameScreen, not an illustrative mockup. No new exported game build yet.
