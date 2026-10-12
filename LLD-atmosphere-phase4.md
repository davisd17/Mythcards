# LLD: Atmosphere, Audio, and Side Palettes (Visual Polish Phase 4)

| Field | Value |
| --- | --- |
| Source | `VISUAL_POLISH_PHASE_1.md` (Long-Term Visual Roadmap, Phase 4), and designer request 2026-10-11: "a color palette per side based on the area and sub-area of the leader being used; if 2 leaders of the same area play, one gets an inverse color set" |
| Status | Implemented 2026-10-11 |
| Files | `side_palette.gd`, `board_atmosphere.gd`, `sfx.gd`, `settings.gd` (all new, `game/scripts/ui/`); `game_board_view.gd`, `game_screen.gd`; `game/tests/unit/test_atmosphere_phase4.gd` |

## 1. Summary

Each side's colors and ambient effect now come from its Leader's sub-area. The board gains restrained motion (atmosphere, frost drift, convergence motes) and the game gains synthesized sound, a drone, and vibration. The Menu has toggles for each, saved across restarts. Everything here is presentation only.

## 2. Side Palettes (`SidePalette`)

| Sub-area | Culture | Primary | Accent | Atmosphere |
| --- | --- | --- | --- | --- |
| Closed City | Russian-inspired | warning red `#b5474c` | reactor green `#6fae7c` | ash motes rising |
| Winter Front | Russian-inspired | icon gold `#c9a04a` | banner crimson `#b5474c` | snow falling |
| Far North | Russian-inspired | aurora green `#5fc48a` | aurora violet `#9a86e0` | aurora curtains |
| Flood Survivors | Atlantean | tide cyan `#4fb3bd` | bronze `#a8875a` | water caustics |
| First Mind | Atlantean | star blue `#6f8ee8` | ivory `#e6dccb` | twinkling stars |
| Crystal Dominion | Atlantean | quartz rose `#d06fa8` | crystal white `#e8f0f2` | quartz glints |

- **Source:** the Leader on the side (in the setup tray or on the board) supplies the sub-area. An unknown sub-area falls back to the culture's flagship sub-area: Closed City for Russian-inspired, Flood Survivors for Atlantean.
- **Inlay:** the back-row inlay style follows the culture (Russian-inspired channels, Atlantean ley lines), not the seat.
- **Mirror rule:** if both Leaders share a sub-area, Player 2 gets the inverse set. Each color's hue turns 180° (its complement) and keeps its saturation and brightness, so a Closed City mirror is red vs. teal. The atmosphere stays the same; only the colors flip.
- **Coverage:** territory wash, inlays, figure bases, name pills, placed-object outlines, HUD relic chips, the turn line and bar, and the turn banner. The center stays neutral bronze and gold.
- **Interpretation:** "same area" was read as the same sub-area. Two different sub-areas of one culture (e.g. Winter Front vs Closed City) already get distinct palettes. `[NEED: designer confirm]` whether same-*culture* matches should also invert.

## 3. Atmosphere (`BoardAtmosphere`)

- Each side's atmosphere covers its three home rows and fades toward the middle like the territory wash.
- Frost tiles get flakes sifting down inside the tile.
- The center gets seven warm motes orbiting and breathing.
- Particle positions are pure functions of index and time: no stored state, and no flicker on redraw.
- The idle redraw rate rose from 15 to 24 fps to keep the motion smooth.
- Menu > Atmosphere turns it off.

## 4. Sound and Haptics (`Sfx`)

- **Synthesis:** every sound is synthesized once at startup (sines, sweeps, filtered noise; 22 kHz, 16-bit). There are no audio files to license or ship.

| Signal | Sound |
| --- | --- |
| move / reposition | soft swish |
| damage > 0 / damage 0 | low thud / metallic ping |
| shield | chime |
| ability | rising sweep |
| defeat (not a Mount falling with its rider) | descending tone |
| level-up | four-note arpeggio |
| Ember picked up / banked | sparkle |
| card draw | card swish |
| turn start | soft bell |
| Leak | low wobble |
| match end | chord swell |

- **Drone:** a 6 s seamless loop (55 / 55.5 / 110 / 82.5 Hz) at −27 dB gives the convergence an ambience.
- **Playback:** sounds play from a pool of 8 players. Repeats of the same sound within 45 ms are dropped, and the pitch varies slightly.
- **Haptics:** `Input.vibrate_handheld` fires on a hit (25 ms), a defeat (60 ms), and a level-up (40 ms). It does nothing on desktop.
- **Settings:** Menu > Sound / Atmosphere / Vibration, stored in `user://settings.cfg`.

## 5. Tests

- `test_atmosphere_phase4.gd` (14 tests), covering palettes, atmosphere, sound and settings:
  - **Palettes:** the playtest matchup's sub-areas; the original Leaders (Winter Front, First Mind); mirror inversion (complementary hue, same brightness, same atmosphere); inverting twice restores the original; culture fallback; every sub-area's hue is distinct; the board uses the mirror palette.
  - **Atmosphere:** the fade, and every atmosphere draws.
  - **Sound:** every sound is synthesized and under 1.5 s; signals play sounds only while sound is on; the drone loops and follows the setting.
  - **Settings:** toggles by name.
- GUT 496/496, Playwright 13/13.
- Screenshots are in `docs/visual-polish-phase4/`. A mirror match (Closed City vs Closed City, red vs teal) was checked by eye in the web build with a temporary matchup, which has since been reverted.

## 6. Open

- `[NEED: designer confirm]` the same-culture inversion question in Section 2.
- `[NEED: designer review]` palette picks for the four sub-areas not yet in play (Winter Front, Far North, First Mind, Crystal Dominion).
- `[NEED: designer review]` sound character and volume in hands-on play. The Flood caustics are subtle in stills; tune after seeing them move.
