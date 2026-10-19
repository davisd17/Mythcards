# Closed City — Behind the Gates

## Approved selection

Version 2 approved by Drew on October 17, 2026.
Selected audio: `closed-city-v2.wav`. Editable score: `closed-city-v2.mid`.

Carry this direction into future Closed City variations: an 8–16-bit foundation,
1980s Russian setting with folk-inspired phrasing, dark low-register driven
synths, early industrial machine pulses and metallic percussion. Preserve the
softer reed-led bridge as a point of contrast. Avoid the bright lead timbre of
version 1.

## Game integration

October 18 direction: this recording is the Closed City exploration/base theme
for eventual single-player play. It is preserved unchanged. Irina now has a
separate leader theme, `Irina — Private Favors`, which takes priority for her
matches. The current game has no single-player exploration scene yet.

The approved WAV is copied to `game/assets/music/closed-city-v2.wav`.
`MusicManager` starts it when the match begins, using the Leader belonging to
`MatchState.first_player_id` to select their leader theme, falling back to the
sub-area base when no leader-specific theme exists. Setup currently gives p1
the first turn. The theme loops for the match and stays the same across turns;
resetting or ending the match stops it. Unscored sub-areas are silent. Future
approved themes belong in `MusicManager.THEMES`.

Original first-pass exploration theme for MythCards. Setting: 1980s Russia,
an isolated city where reactor systems, the signal array, and dream research
begin answering one another. Restrained, watchful, and quietly human.

## Files

### Revision 2 — early industrial

- `closed-city-v2.wav`: revised mix, same 83-second loop and tempo.
- `closed-city-v2.mid`: revised notes; MIDI playback does not reproduce the
  custom distortion, FM lead, or metallic drum synthesis in the WAV.
- `compose-v2.py` and `render-info-v2.json`: rebuild source and measurements.

Responds to listening feedback: replace the bright upper-register square lead
with an octave-lower, driven pulse/FM voice. Shorter phrases leave more space
for saturated bass, heavier kick, metallic snare, and repeating machine hits.
Plucked accompaniment and receiver tones sit further back. The reed-led bridge
at approximately 0:42–1:03 keeps its original notes and gentler instrumentation.
The original v1 files remain available for comparison.

### Original version

- `closed-city-v1.wav`: stereo, 16-bit PCM, 32 kHz; the intended sound and mix.
- `closed-city-v1.mid`: seven editable instrumental/percussion tracks plus a
  tempo track. General MIDI instruments approximate the custom synth voices;
  playback in a MIDI player will differ from the WAV.
- `compose.py`: reproducible composition and synthesis source; needs numpy.
- `render-info.json`: render measurements.

## Composition

92 BPM, 4/4, D minor with harmonic-minor cadences. 32 bars, 83.47825 seconds.
Progression: D minor / B-flat / G minor / A major.

| Bars | Approx. time | Treatment |
| --- | --- | --- |
| 1–8 | 0:00–0:21 | A guarded square-wave folk-inspired question and answer. |
| 9–16 | 0:21–0:42 | Ornamented melody and busier plucked accompaniment. |
| 17–24 | 0:42–1:03 | Lower reed melody; a warmer, more spacious respite. |
| 25–32 | 1:03–1:23 | Main melody returns; the receiver signal becomes clearer. |

Triangle-like bass, pulse-wave lead, balalaika-like synthetic plucking, a soft
accordion-like reed voice, noise percussion, and a faint atmospheric pad.
The folk influence is a creative reference, not a quotation of a traditional
song or a claim to an archival 1980s performance. This is a retro-style hybrid
with more voices and effects than a strict historical console soundtrack.

## Loop and use

Loop the entire WAV at its native sample length, with no added pause. Release
tails and echoes wrap into the beginning. No fade-out is baked into the file.
Version 2 is the approved music asset and is integrated into Godot match playback.
The arrangement is an initial area theme, not yet a set
of independently scored sub-area variants.

Rebuild: run `compose.py` with Python and numpy. Numerical checks cover clipping,
duration, finite samples, and matching endpoint samples; listening review is
still needed to judge musical balance and the transition in context.
