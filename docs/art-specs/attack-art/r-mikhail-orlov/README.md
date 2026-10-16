# Dr. Mikhail Orlov Attack Art

Default outfit pose reference: a contained amber reactor pulse from his left palm.
His right hand retains the upright brass/glass reactor instrument throughout.
Six poses build and release the pulse, then lower the casting hand.
Impact revision: brighter pale white/yellow-green core and reactor-green inner
rings on Fire, retaining amber outer detail. Other source poses are unchanged.
Exactly two hands; target-facing gaze and planted stance are continuity requirements.

Runtime: six 512x768 RGBA PNGs, one shared scale, translation-only registration.
Holds: 100/100/130/60/90/120 ms, total 600 ms. Pose 4 is impact.
Foot baseline y756; 24 px side and 18 px top safe margins.
Leftward attacks mirror; vertical attacks reuse sideways art per the approved spec.
Abilities retain existing behavior. No new projectile or gameplay rules.

Review: `contact-sheet.png`, `attack-preview.gif`, `r-mikhail-orlov-attack.ora`.
Sources and reproduction: `sources/`, `sources.json`, `prompts.md`, `registration.json`.
Built-in ImageGen used `game/assets/figures/r-mikhail-orlov/default.png` as identity reference.
The generated palm glow stays close to the figure; no baked-in ground or target.

Rebuild: `tools/prepare_attack_sequence.py r-mikhail-orlov docs/art-specs/attack-art/r-mikhail-orlov/sources.json`.
Register: `node tools/register_attack_frames.js r-mikhail-orlov`.
