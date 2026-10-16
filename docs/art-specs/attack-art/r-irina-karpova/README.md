# Irina Karpova Attack Art

Default outfit pose reference: a restrained one-handed sidearm shot toward screen-right.
Right hand retains the brass keys; left hand draws from her coat, aims, fires, and lowers.
The keys move slightly with the hand; no gameplay or ability rules change.
Head and eyes stay aimed at the same target through every pose.
Stance revision: Brace, Fire and Recoil now retain Ready's foot ordering instead
of reversing the forward foot. Timing and upper-body choreography are unchanged.

Six 512x768 RGBA runtime poses: ready 100, raise 100, brace 130, fire 60,
recoil 90, recover 120 ms. Total 600 ms; pose 4 is impact.
Sources share one scale and translation-only registration, boot baseline y756.
Engine mirrors leftward attacks and reuses sideways art for vertical targets.

Review: `contact-sheet.png`, `attack-preview.gif`, `r-irina-karpova-attack.ora`.
Reproduction: `sources.json`, `prompts.md`, `registration.json`, `sources/`.
Built-in ImageGen used the existing default figure as identity reference.
Attack sources exclude the stray blue fragment at the idle image's lower-right edge.
Idle artwork is unchanged; review the transition to/from its frontal pose in play.

Rebuild: `tools/prepare_attack_sequence.py r-irina-karpova docs/art-specs/attack-art/r-irina-karpova/sources.json`.
Register: `node tools/register_attack_frames.js r-irina-karpova`.
