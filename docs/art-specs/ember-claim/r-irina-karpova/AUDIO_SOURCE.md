# Ember claim audio — r-irina-karpova

Status: revision 2 approved by Drew on October 22, 2026.

Revision: removed the shared noise wash. Static is limited to Elena and Zoya, with only a very small steam puff for Reactor Worker; other characters use clean tonal/material-specific synthesis.

Direction: Pen-like metal click and muted low brass punctuation.

Original procedural synthesis by Codex for MythCards. No recordings, external samples, third-party music, voice, or spoken words. No external sample licence is required. Source: `tools/synthesize_ember_claims.py` (Python and numpy; deterministic per-character seed).

Runtime: `game/assets/sfx/r-irina-karpova/claim.wav`. Mono, 44.1 kHz, 16-bit PCM, 0.45 s. Same sting for normal and big claims; Sound setting controls playback.

Approved text remains verbatim in `data/ember_lines.json`; this asset does not speak or modify it. Art approval is tracked separately.
