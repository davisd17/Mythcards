# Zoya Miranova Attack Art

Default outfit only: remote-viewing subject gathers pressure, then pushes out a
compact teal dream-static wave with both hands. Preserve the black gown, loose
lab coat, electrode contacts/leads and bare feet. Aurora Rite is a later outfit pass.

Six 512x768 RGBA runtime frames: ready 100, raise 100, brace 130, fire 60,
recoil 90, recover 120 ms. Impact starts at 330 ms; total 600 ms.
Idle-size anatomical landmark normalization precedes translation-only registration.
Foot baseline y756, safe margins 24 px sides/18 px top.
Source landmarks include a reviewed foot-center x coordinate so the loose coat
does not enter the automatic boot-anchor estimate.
Effects stay below crown and above soles. Do not shrink the body to accommodate
the wave or coat reach.
Screen-right art mirrors for leftward targets; vertical attacks reuse sideways art.

Review: `contact-sheet.png`, `attack-preview.gif`, `r-zoya-miranova-attack.ora`.
Sources and reproduction: `sources/`, `sources.json`, `prompts.md`,
`body-landmarks.json`, `registration.json`.
Built-in ImageGen used default idle for Ready; later poses used the generated
candidate Ready for continuity. Idle and abilities remain unchanged.
Ready is an alert raised-hand guard, not the requested low relaxed hands. A
targeted lowered-hand edit was blocked by the generator; the original candidate
is retained for review. Recovery lowers both hands toward idle.

Rebuild: `tools/prepare_attack_sequence.py r-zoya-miranova docs/art-specs/attack-art/r-zoya-miranova/sources.json --body-landmarks docs/art-specs/attack-art/r-zoya-miranova/body-landmarks.json`.
Register: `node tools/register_attack_frames.js r-zoya-miranova`.
