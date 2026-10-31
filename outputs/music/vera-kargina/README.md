# Vera Kargina — The Snow Keeps Tracks

Approved by Drew on October 30, 2026. Vera Kargina / Meteor Spear, the Far
North's hunter and practical village leader. This is Vera Kargina's music, not
VERA-7's. Her source lore is in `data/cards/review_drafts/far_north_story_relics.json`
and the Queen of Wands entry in `russian_tarot_guidebook.json`.

Think of music Vera would choose after returning from a winter trail: scarred
confidence, the warmth she guards, the huge space outside the village, and an
aurora that feels watchful. Her bond with Buran is trust between independent
beings, not obedience. The music is grounded and protective, with a small
current of wonder beneath it; it is not a soft mystical character portrait.

## Musical identity

72 BPM, E minor, 4/4. Each A or B is 24 bars/80 seconds; the full A/B/A is four
minutes. The shared 8–16-bit and lo-fi foundation comes from dark plucked
folk-like chip strings, warm low bowed tones, a muted reed, rounded bass and
restrained high ice/aurora harmonics. Dry frame skin, wood and a few metal ticks
follow a 3+3+2 eighth-note gait. No recorded wind, constant hiss, electric-piano
lounge arrangement, or Atlantean choir/water palette is reused.

The recurring E–E–G / F#–B–D phrase gives Vera a sturdy, memorable calling line.
Open E-minor / C / A-minor / B shapes favor space and resonance over jazz chord
comping. These are original fictional folk-inspired sounds, not an archival
recording or a claim to reproduce a particular northern people's instruments.

| Full-song time | Section | Arrangement |
| --- | --- | --- |
| 0:00–1:20 | A | Plucked signature and a steady winter-road gait; bowed warmth, reed replies, aurora glints; a short quiet passage before the hook returns. |
| 1:20–2:40 | B | Plucked variations, bowed-string replies, then an open-string/aurora breakdown around 2:00–2:13; the pulse and hook rebuild. |
| 2:40–4:00 | A return | The signature and full groove return. |

## Files and rebuild

- `vera-kargina-snow-keeps-tracks-aba-v1.wav`: complete A → B → A listening mix.
- `vera-kargina-snow-keeps-tracks-a-v1.wav`, `vera-kargina-snow-keeps-tracks-b-v1.wav`:
  standalone looping sections for review or later adaptive playback.
- Matching MIDI: seven instrumental/percussion tracks plus tempo/meter track.
  General MIDI instruments approximate the custom synthesis; the WAV is the reference.
- `render-info-<form>-v1.json`: waveform and section measurements.
- Rebuild: `python tools/compose_vera_far_north_v1.py` (Python and numpy).
  Use `--form a`, `--form b`, or `--form aba` to rebuild one form. It uses the
  shared chunked renderer in `tools/compose_flood_survivors_music.py`.

All WAVs are 32 kHz/16-bit stereo. The complete A/B/A is rendered continuously
on one musical clock, allowing releases and echoes to carry across the changes.
It contains 7,680,000 frames; each standalone section has 2,560,000 frames.
Loop B is a deliberately composed improvisation-like performance with its own
interplay and breakdown, not live/random performance or busier backing alone.

Vera currently has a story/card draft but no canonical playable ID or Far North
team entry. `MusicManager.LEADER_NAME_THEMES` prepares playback using the exact
Leader name `Vera Kargina` and sub-area `Far North`. It selects the full A/B/A
only when she leads the team going first, regardless of p1/p2 seat, and keeps it
across turn changes. An opposing Vera, VERA-7, or a namesake from another area
does not select it. Existing ID-specific music takes priority over this fallback.
No gameplay card, canonical ID or roster has been invented. Move this entry to
`LEADER_THEMES` when her playable ID is authored; adding that roster entry is
still future work. Existing character songs and approved area music are unchanged.
