# Irina — Private Favors

## Revision 2 — expensive drinks aboard VERA

Latest listening draft: `irina-private-favors-a-v2.wav` and its editable `.mid`.
Rebuild with `compose-v2.py`; measurements are in `render-info-v2.json`.
Irina's match music now points to v2. Version 1 is preserved for comparison.

The revision centers on a recurring five-note A–C–A / G–F electric-piano hook,
repeated across the changing chords with different answers. The piano remains
the signature voice throughout. A more mobile bass line, chromatic approaches,
dusty brush/rim groove, and quiet chip replies add a relaxed, assured swagger.
Imagine Irina sipping expensive dark liquor aboard VERA-7: comfort, crystal,
velvet, and private privilege amid machinery. This is mood direction, not a
new canon claim about VERA's fittings. No literal drink or rover sound effects.
The 69 BPM, 24 bars, and 83.47825-second duration are unchanged. The separate
jam/breakdown loop B is now composed as a separate listening draft below.

## Revision 1

First listening draft, October 18, 2026. Leader: Irina Vasilievna Karpova,
`r-irina-karpova`. Private power, cultivated taste, and luxury with a threat underneath.

Loop A: 24 bars at 69 BPM, 4/4, D minor; 83.47825 seconds. This matches the
Closed City exploration loop's duration while using a slower groove. Soft FM
electric-piano voicings, rounded triangle-like bass, a muted chip voice, glassy
plucked replies, and dusty swung drums. Dm9 / Bbmaj9 / Gm9 / A7(b9), two bars
per harmony. Richness comes from voicing, space, and timbre rather than volume.

- `irina-private-favors-a-v1.wav`: stereo, 32 kHz, 16-bit audio.
- `irina-private-favors-a-v1.mid`: editable six-part score plus tempo track;
  General MIDI playback approximates the custom synthesis and mix.
- `compose.py`: reproducible source, Python 3 and numpy.
- `render-info.json`: numerical checks. Musical balance still needs listening review.

Bars 1–8 establish the signature. Bars 9–16 move the motif into a lower, softer
chip voice, with electric-piano replies. Bars 17–20 strip back the drums and
foreground line; bars 21–24 return the hook and cadence back to D minor.
This small contrast within A is not the eventual jam-and-breakdown loop B.

## Loop B — After Hours

Composed October 18, 2026; first listening draft. Same 69 BPM, D minor, 24 bars,
83.47825 seconds, and custom instruments as A v2. A's WAV and source are unchanged.
The improvisation is a fixed, composed performance with varied phrasing and touch.

- `irina-private-favors-b-v1.wav`: standalone looping B arrangement.
- `irina-private-favors-b-v1.mid`: editable six-part score plus tempo track.
- `compose-b.py`: independent reproducible synthesis source; Python and numpy.
  Uses temporary file-backed buffers and small chunks to keep memory modest.
- `render-info-b-v1.json`: levels, loop checks, and section dynamics.
- `irina-a-b-a-transition-preview.wav`: 139-second audition, starting with A's
  last eight bars, playing all of B, then returning to A's first eight bars.
  Rebuild with `make-transition-preview.py`. Four-millisecond endpoint corrections
  suppress clicks at joins without moving musical boundaries.

| B time | Bars | Arrangement |
| --- | --- | --- |
| 0:00–0:28 | 1–8 | Piano takes A's hook into longer, varied lines; chip replies. |
| 0:28–0:42 | 9–12 | Muted chip voice takes the foreground; piano answers it. |
| 0:42–0:56 | 13–16 | Bass and sparse keys; drums leave, then return as small touches. |
| 0:56–1:09 | 17–20 | Groove rebuilds while piano and chip phrases trade places. |
| 1:09–1:23 | 21–24 | Hook fragments return and A7(b9) leads back toward A's Dm9. |

B can repeat at its own boundary or resolve back to A. Numerical checks cover
duration, clipping, matching endpoint samples, and MIDI structure. The transition
audition is for listening review; it does not implement runtime scheduling.
No automatic A/B switching has been added to the game. That future system should
change arrangements at musical boundaries and handle their release tails.

## Game use

Irina's specific leader theme takes priority over a sub-area theme at match start.
The original Closed City recording remains unchanged as the area/exploration base
for eventual single-player use. Menu ambience and the Sound toggle continue to work.
