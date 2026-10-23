# Ember claim audio — October 22, 2026

Revision 2 responds to listening feedback that too many first-pass sounds shared
the same fuzz. The common noise bed is removed. Static is brief and specific to
Elena/Zoya, Reactor Worker retains only a small steam puff, and the others use
distinct ringing metal, dry impacts, smooth machinery, reeds, chimes or tonal
water motion. Audition `outputs/ember-claim/audio-review-v2.wav`; first-pass audio
and synthesis source are preserved under `outputs/ember-claim/v1/`.

All 14 revision 2 nonverbal stings were approved by Drew on October 22, 2026.
Audio-only runtime hookup passed the seven playback tests. This approval does
not approve the separate art/text package. Approved wording in `data/ember_lines.json` is unchanged.

Review `outputs/ember-claim/audio-review.wav` using the order/time labels in
`outputs/ember-claim/AUDIO_INDEX.md`. Each character has `AUDIO_SOURCE.md` here,
and a runtime file at `game/assets/sfx/<character-id>/claim.wav`.
Rebuild with `tools/synthesize_ember_claims.py` (Python and numpy), or use
`--check` to verify existing WAVs without changing them.

All WAVs are mono 44.1 kHz, 16-bit PCM, 0.4–0.9 seconds, below −1 dBFS, with
attacks within 10 ms and tails reaching silence. Synthesis is original, without
external samples, recordings, voice, or words. Normal/big claims share one sting.

`Sfx` waits for attack impact plus 500 ms. The newest claim interrupts older and
pending claim audio. Sound Off and match reset cancel it; the final claim of an
ended match remains eligible. Missing character audio falls back to the existing
generic Ember sound. Delivery keeps its existing generic sound. A separate claim
player prevents stealing the attack sound and uses a fixed pitch.

The pickup signal still has no gained count, because audio does not need it.
Claim-frame registration, line popups, big-claim text/burst selection, Level 3
visual ordering, and results-overlay timing remain separate implementation work.
No exported web/Windows listening or full-package approval is claimed here.
