# Ember claim audio — a-flood-survivor-iset-nara

Status: revision 2 approved by Drew on October 22, 2026.

Revision: removed the shared noise wash. Static is limited to Elena and Zoya, with only a very small steam puff for Reactor Worker; other characters use clean tonal/material-specific synthesis.

Direction: Clear fifth-interval chimes and a low sliding resonance.

Original procedural synthesis by Codex for MythCards. No recordings, external samples, third-party music, voice, or spoken words. No external sample licence is required. Source: `tools/synthesize_ember_claims.py` (Python and numpy; deterministic per-character seed).

Runtime: `game/assets/sfx/a-flood-survivor-iset-nara/claim.wav`. Mono, 44.1 kHz, 16-bit PCM, 0.65 s. Same sting for normal and big claims; Sound setting controls playback.

Approved text remains verbatim in `data/ember_lines.json`; this asset does not speak or modify it. Art approval is tracked separately.
