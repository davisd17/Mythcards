# Queen Meret-Anu — Tidekeepers

## Current revision: Tidekeepers, version 3 — A → B → A

Approved by Drew on October 29, 2026 for Meret-Anu-led matches. Pearl Current was rejected as too similar to
Irina. Atlantis now has a distinct identity: layered hand drumming and wordless
choir within the shared 8–16-bit/lo-fi aesthetic. Flood Survivors adds aquatic
movement. The Queen still chooses this music for herself; luxury comes from
space, rich choral color and confident rhythm, not another electric-piano lounge.

The new song uses interlocking low skin drums, open hand drums, slaps, wood and
shell clicks; a synthesized wordless vowel-formant choir; liquid pitched drops;
slow underwater-like tonal swells; and rounded bass. No electric piano, brushed
backbeat, recorded voices, intelligible words or continuous noise wash. The
percussion is an original fictional Atlantean palette, not a claim of authentic
music from a particular real-world people. Lo-fi finish keeps the chip character.

The new G–Bb–D / C–A signature sits over G minor / F / C minor / D. Both sections
are 24 bars of 4/4 at 69 BPM, about 83.48 seconds each. They use a common pulse,
key, palette and return cadence. The hand-drum patterns interlock in thirds
against the four-beat bass pulse, instead of repeating Irina's swung groove.

| Full-song time | Section | Arrangement |
| --- | --- | --- |
| 0:00–1:23 | A | Choir hook and hand-drum groove; water replies, a quiet passage, hook return. |
| 1:23–2:47 | B | Water-tone variations, choir call-and-response, a breakdown at about 2:05–2:19, then a rebuild. |
| 2:47–4:10 | A return | Main refrain and groove return with the same musical arrangement. |

- `meret-anu-tidekeepers-aba-v3.wav`: the complete continuously rendered song,
  250.43478 seconds, selected for match playback. It repeats the full A/B/A cycle.
- `meret-anu-tidekeepers-a-v3.wav` and `meret-anu-tidekeepers-b-v3.wav`: separate
  section loops, 83.47825 seconds each, for review or later adaptive playback.
- Matching MIDI files: six parts plus tempo/meter. General MIDI choir/perc
  patches approximate the original synthesis; the WAVs are the intended sound.
- `render-info-a-v3.json`, `render-info-b-v3.json`, `render-info-aba-v3.json`:
  render measurements, section dynamics, and voice provenance.
- Rebuild all: `python tools/compose_meret_tidekeepers_v3.py`; choose one with
  `--form a`, `--form b` or `--form aba`. Requires numpy and the shared renderer
  `tools/compose_flood_survivors_music.py`.

The complete song is synthesized continuously, not made by cutting together
self-looping masters. Release and echo tails carry across A/B/A on the same
sample clock. The two internal boundaries are rounded from beat positions;
the full file has 8,013,913 frames at 32 kHz. The separate section WAVs each
round to 2,671,304 frames. The one-frame total difference is expected rounding.
The game plays one full-song stream; no dynamic section scheduler was added.

All earlier Queen recordings and the accepted Flood Survivors area theme are
preserved. Tidekeepers v3 is the selected match song. Broader Atlantean area variants
should follow the new drum/choir direction; this task does not overwrite the
previously accepted area recording.

## Previous revision: Pearl Current, version 2 — superseded

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
