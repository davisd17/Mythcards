# The Threshold — menu and team selection ambience

Approved by Drew on October 17, 2026. Version 1 is the selected menu ambience.

Original 64-second stereo loop for MythCards. Understated and ambient, with
weight from a deep D pedal, slow engine-like swells, suspended synthetic chords,
filtered air, and distant metallic resonance. No foreground melody or drum beat.
Chip-era oscillators remain in the palette, with a wider atmospheric room.
This shared theme is not assigned to a particular culture or sub-area.

- `the-threshold-menu-v1.wav`: 32 kHz, 16-bit stereo audio preview/master.
- `compose.py`: reproducible synthesis and composition; Python 3 and numpy.
- `render-info.json`: numerical audio checks.

The same WAV is installed at `game/assets/music/the-threshold-menu-v1.wav`.
It plays across the new-match chooser and team deployment. Opening the in-game
menu brings back the ambience and pauses the match theme; closing it resumes
the match theme. At match start, the ambience fades out over one second as the
starting Leader's sub-area theme begins. The Sound setting controls both.
Unscored sub-areas remain silent during matches. The existing quiet SFX drone
continues as a separate background texture.

Numerical verification covers finite samples, peak level, duration, and loop
endpoints. Final musical balance needs listening review in the game.
