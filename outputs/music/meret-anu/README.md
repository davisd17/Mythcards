# Queen Meret-Anu — Pearl Current

## Current revision: Pearl Current, version 2

The user rejected the ceremonial first version and asked for music the Queen
would enjoy listening to, with a lo-fi aquatic beat. The new listening draft is
`meret-anu-pearl-current-a-v2.wav`, with a matching editable MIDI and
`render-info-v2.json`. Version 1 and its source remain available for comparison.

Picture Meret-Anu at ease in a private underwater room: warm electric-piano
ninths and thirteenths, rounded moving bass, a laid-back swung kick/rim groove,
liquid chip plucks and reflected echoes. The recurring F–A–G / E–D hook carries
the melody inside the beat. Small breathing swells add an aquatic feel without
a constant hiss or surf layer. Low brass, ceremonial reed lead and crown chimes
are absent. Dm9 / G13 / Cmaj9 / Fmaj9 keeps the harmony open and fluid.

Same 69 BPM, 24 bars, 83.47825-second loop. The accepted Flood Survivors area
recording is unchanged. This is Loop A; its quiet passage is not the future jam B.
Future B should develop keys/liquid-pluck interplay and a stripped-back beat.

Rebuild: `python tools/compose_meret_aquatic_v2.py` (Python and numpy).
It reuses the shared renderer in `tools/compose_flood_survivors_music.py` but
does not render or overwrite the area theme or Queen v1. Current match selection
points to Pearl Current v2. Drew approved this selection for GitHub on October 26, 2026.

## First version — retained, not selected

First Loop A listening draft, October 26, 2026. Character ID:
`a-flood-survivor-meret-anu`. The hidden survivor queen preserves Atlantis through
disciplined memory, protected archives, and difficult choices. Her luxury is
ceremonial, immaculate, and controlled; it differs from Irina's private lounge.

24 bars of 4/4 at 69 BPM, 83.47825 seconds. The Flood Survivors' D–A–G–E tide
motif becomes a recognizable royal refrain over richer minor harmony. A warm
reed/chip lead, low horn answers, rolled harp-like chords, occasional crown
chimes, tuned stone percussion, and a weighted bass pulse establish authority.
The 8–16-bit and lo-fi foundation remains warm, without a constant noise layer.

The hook establishes her presence, returns with short instrumental answers,
then withdraws around 0:56–1:09 into the buried archive before returning to the
full refrain. Dm9 / Bbmaj7(#11) / Gm9 / A7(b9). The area theme's Dorian B-natural
becomes B-flat here, shifting communal hope toward regal restraint.

- `meret-anu-a-drowned-crown-a-v1.wav`: intended stereo mix, 32 kHz/16-bit.
- Matching `.mid`: seven instrumental/percussion tracks plus tempo/meter track.
  MIDI instruments approximate the custom synthesis; the WAV is the reference.
- `render-info-v1.json`: numerical measurements.
- Rebuild: `python tools/compose_flood_survivors_music.py --track queen`.
  Requires numpy. `--track both` rebuilds both connected pieces.

Mapped in `MusicManager.LEADER_THEMES`; it plays when Meret-Anu is the starting
player's leader, including p2 starting first, and stays across turn changes.
No initiative rules, default first player, or existing music settings are changed.
The Flood Survivors area base remains a separate asset and fallback.

Loop B remains future work: keep this tempo, harmony and palette, let reed,
harp and low horn trade variations, then break down to bass and sparse stone
percussion before rebuilding. This small bridge in A is not a substitute for B.
No automatic A/B scheduling is implemented. The current track is a listening draft.
