# Project music references

Resolve these paths relative to the MythCards repository. Read only the sources
needed for the current request; consult current direction and later approvals.

| Purpose | Existing source |
| --- | --- |
| Shared sound direction | `outputs/music/DIRECTION.md` |
| Irina main theme A, revision 2 | `outputs/music/irina/compose-v2.py` |
| Irina jam/breakdown B, draft 1 | `outputs/music/irina/compose-b.py` |
| Arrangement, versions, and review state | `outputs/music/irina/README.md` |
| A → B → A audition builder | `outputs/music/irina/make-transition-preview.py` |
| Closed City exploration/base, approved v2 | `outputs/music/closed-city/compose-v2.py` |
| Shared menu ambience, The Threshold | `outputs/music/menu/compose.py` |
| Character and relic lore | `data/cards/review_drafts/closed_city_characters.json`, `closed_city_relics.json` |
| Runtime music selection and menu behavior | `game/scripts/autoloads/music_manager.gd` |
| Integration tests | `game/tests/unit/test_match_music.gd`, `test_game_screen.gd` |

At the skill's creation, the user accepted Irina A v2; B was composed and awaiting
listening review. B is separate audio, not an automatically scheduled game loop.
Avoid treating this snapshot as a permanent approval registry.

Irina's palette combines soft FM electric piano, rounded triangle-like bass,
muted chip lead, plucked replies, pad, rim/brush drums, and swung hats. A's hook
is A–C–A / G–F over Dm9 / Bbmaj9 / Gm9 / A7(b9), with two bars per chord.
B keeps the same cycle and instruments but develops piano variations, passes
the lead to the chip voice, breaks down around 0:42–0:56, and rebuilds.

The source implements circular release/echo mixing, a restrained tape-like
finish, and custom synthesis. Keep the sound relationship when borrowing these
techniques; don't reuse Irina's notes as another character's identity by default.
`compose-b.py` uses small synthesis/mastering chunks and temporary mapped files.

Example WAV verification, using a Python runtime and this skill's script path:

```text
python scripts/check_loop.py <irina-loop.wav> --bpm 69 --bars 24 --require-loop
python scripts/check_loop.py <new-loop.wav> --compare-length <reference.wav> --require-loop
```

The checker streams PCM data with the standard library, so it doesn't load the
whole soundtrack into memory. It reports levels, clipping, endpoints, and optional
duration consistency. Listen to the actual arrangement and transitions when
listening capability is available; otherwise provide the preview for review.
