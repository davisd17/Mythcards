# Dr. Elena Morozova Attack Art

Default outfit pose reference: a cool cyan dream-signal pulse from her existing
spherical electrode-cap laboratory device. Right hand lifts and presents the device;
left arm retains her research folders throughout. No new weapon or ability rules.
Cables move with the lifted device; the folders remain held against her torso.

Six 512x768 RGBA frames use one shared scale and translation-only registration.
Timing: ready 100, raise 100, brace 130, fire 60, recoil 90, recover 120 ms.
Total 600 ms; frame 4 is impact at 330 ms. Foot baseline y756; safe margins
24 px sides and 18 px top. Screen-right attack art mirrors for leftward targets.
Vertical attacks reuse sideways art. Idle remains unchanged.

Review: `contact-sheet.png`, `attack-preview.gif`, `r-elena-morozova-attack.ora`.
Sources/reproduction: `sources/`, `sources.json`, `prompts.md`, `registration.json`.
Built-in ImageGen used the default figure to create Ready; later poses used the
candidate Ready image as a continuity reference. Visual approval remains pending.

Rebuild: `tools/prepare_attack_sequence.py r-elena-morozova docs/art-specs/attack-art/r-elena-morozova/sources.json`.
Register: `node tools/register_attack_frames.js r-elena-morozova`.
