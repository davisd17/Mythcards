---
name: mythcards-character-music
description: Compose and revise MythCards character and leader music, including catchy main themes, compatible jam and breakdown loops, playable audio, editable scores, and optional Godot playback integration. Use for character soundtrack work; not attack sound effects, artwork, or unrelated commercial songs.
---

# MythCards Character Music

Deliver playable music, not only a written concept, when the user asks to compose
or revise a song. Keep the current user's direction ahead of these defaults.

## Establish the musical identity

Locate the MythCards repository from the workspace rather than assuming a drive.
Check its instructions and working-tree state; preserve unrelated edits. Read
`outputs/music/DIRECTION.md`, the character's lore, and the relevant music README.
Use `references/project-music.md` for existing source examples and playback entry points.

Separate three identities: area/exploration music describes a place; a leader
theme describes a person within that place; shared menu ambience belongs to
neither. Preserve the existing area recording when making a leader song.

The established palette is 8–16-bit-inspired, lo-fi, and downtempo, with room for
richer instrumentation. Favor rounded bass, warm extended chords, restrained
upper frequencies, relaxed timing, and deliberate space. Avoid piercing square
leads. Texture and character matter more than strict historical channel limits.
Leader themes should have a sense of luxury, interpreted through the character's
personality rather than applying the same lounge arrangement to everyone.

Turn lore and the user's listening image into specific musical choices. For
Irina, the working image is expensive drinks aboard VERA: velvet, crystal,
private privilege, controlled menace, and comfort amid machinery. Do not invent
new lore from an evocative musical brief or add literal foley without a reason.

## Compose or revise

- Build a singable rhythmic/melodic hook for Loop A. Repeat it with purposeful
  answers and harmonic changes; keep its identity audible across timbre changes.
- Retain accepted parts when revising. State the requested musical change,
  create a versioned source/audio pair, and preserve previous versions.
- Use the existing instruments and synthesis sources as a starting point when
  continuity matters. New characters may need different timbres and harmonies.
- Match an existing loop by sample count when requested. Roughly 83 seconds is
  the current reference, not a mandatory tempo or length for every character.
  Irina uses 24 bars at 69 BPM; Closed City uses 32 at 92 BPM. Both round to
  2,671,304 frames at 32 kHz.
- Treat Loop B as a distinct composed improvisation: develop hook fragments,
  exchange instrumental phrases, vary touch and spacing, remove layers for a
  real breakdown, then rebuild toward A. More notes over the same backing alone
  do not satisfy the jam/breakdown request. A fixed performance can sound free;
  do not describe it as live or generatively improvised unless it actually is.
- Keep A/B tempo, meter, tuning, core palette, and entry/exit harmony compatible.
  Design phrase-boundary returns and preserve release/echo tails. An equal
  length or matching endpoint sample alone does not prove a musical transition.

## Render and deliver

Use versioned files under `outputs/music/<character>/`. Include the playable WAV,
editable MIDI when appropriate, reproducible composition/synthesis source,
render measurements, and concise arrangement notes. MIDI program choices only
approximate custom synthesis; identify the WAV as the intended sound.

Python/numpy synthesis is the established local workflow; it does not require a
paid music service. Locate the available runtime through workspace dependencies
when necessary. Render in small chunks or use file-backed buffers if memory is
limited; close mapped files before deleting them on Windows.

For A/B work, create a separate transition audition when useful: A's last eight
bars, B, and A's first eight bars. Brief boundary corrections may prevent clicks,
but keep the bar grid fixed and document any processing. Preserve the standalone
loops. Do not claim that an audition implements runtime switching.

Run `scripts/check_loop.py` against each standalone 16-bit PCM WAV, supplying its
tempo/bar count and `--require-loop` when appropriate. Compare duration, levels,
and the intended arrangement with the reference. Verify MIDI structure and
balanced note events with available MIDI tooling when delivering a score.
Confirm a breakdown reduces layers and dynamics instead of merely changing notes.
Numerical checks do not establish musical quality; never claim to have listened
when no audio listening tool or actual listening review was available.

Embed the playable WAV in the response with its absolute local path. Summarize
the changed musical behavior, length, and any remaining integration work. Keep
the distinction between a listening draft and user-approved music explicit.

## Game integration when requested or already in scope

Inspect the current `MusicManager` before editing it. Preserve leader-specific
selection before area fallback, selection by the starting player's leader,
continuous match playback across turns, menu pause/resume, and Sound settings.
Composition alone does not imply a request to implement automatic A/B scheduling.
If scheduling is requested, change arrangements on musical boundaries and verify
the actual return, tails, reset, menu behavior, and mute behavior.

Install versioned audio in `game/assets/music/` and update only the intended
mapping. Keep WAVs covered by the repository's LFS rules. Run music/playback tests
for integration changes; don't rerun the whole game suite for an audio-only draft
without a reason. Do not commit, push, or publish unless the user requests it.
