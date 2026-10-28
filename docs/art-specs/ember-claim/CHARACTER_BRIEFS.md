# Ember Claim: All 14 Character Briefs

Date: 2026-10-21. Status: proposed art/audio direction, not approved assets.

Use with [SPEC.md](SPEC.md). That spec owns triggers, timing, sound format, and
the current draft dialogue. This document refines its initial hold-pose sketches
against the actual default figures; it does not replace the locally revised lines.
Roster IDs come from `data/cards/teams.json`, not older culture-only squads.

## Shared Production Contract

- Mounted exception, approved 2026-10-27: use the rider's normal/big-claim text
  and existing sting without new character animation. Keep the mounted composite;
  these three-pose briefs apply only when the character is not riding. Do not
  animate or give a second line/sting to the carrying mount.

- Three poses per default outfit: Gather 120 ms, Hold 360 ms, Settle 120 ms.
  This is a character-specific payoff, not another attack. It can be exuberant,
  smug, relieved, protective, eerie or solemn; do not make everyone restrained.
- Read BOTH approved lines in `data/ember_lines.json` before storyboarding.
  Their emotional intent takes priority over the initial pose sketches below.
  Keep wording unchanged. One shared animation must suit normal and big claims;
  convey intensity through posture, expression and silhouette, not new props.
- The claim begins 500 ms after defeat impact. Keep the original spec's total
  timing, nonblocking input, mounted-rider ownership, and hazard exclusions.
- Normal and big claims reuse the SAME poses and sting. The engine changes the
  line and Ember burst; do not commission another 42 frames for big claims.
- No Ember, incoming wisp, claim glow, text, or opponent is baked into the PNGs.
  The empty receiving space described below is for an engine-drawn spirit/light.
  Ambient character water and existing markings may remain; do not erase identity.
- Preserve idle anatomy, body size, costume, carried props, grounded contacts,
  and facing through all three poses. No walking, new limbs, or jumps in scale.
  A brief intentional glance at the receiving space is allowed; no full turn.
- Use the attack-art canvas/safe margins, but CLAIM naming and three-pose timing.
  Match both foot contacts and idle's horizontal placement, not merely y756.
  Ahesu uses its coil footprint; VERA-7 uses its wheelbase.
- Keep hand counts and prop ownership explicit. Settle must reconnect with idle.
  Claim art starts after attack recovery; it does not leave weapons floating.
- Each sting is original/licensed, nonverbal, 0.4-0.9 s, per SPEC Section 4B.
  The durations below are design targets, not produced or measured audio.
- All entries use the normal/big draft lines in SPEC Section 5. They still need
  designer approval and the specified Closed City sensitivity review.

## Dialogue-Led Performance Direction

Updated after designer feedback on the first three previews, 2026-10-21.
Source: approved dialogue commit `8ff11bc`, verified against origin/main.
These directions override any conflicting restraint in the older pose sketches.

| Character | Performance to match both approved lines |
| --- | --- |
| Reactor Worker | "I made it": visible relief, small released breath and softened shoulders; big-claim caution keeps this from becoming swagger. Approved photo gesture remains usable. |
| VERA-7 | "BOOM" / "POWER!!!": unmistakable mechanical triumph. A raised sampling claw, proud camera lift and quick acknowledgement snap; no rolling wheelbase or invented hatch. Current approved sample-check preview is quieter than this intent; propose a celebratory revision before final integration, without silently replacing it. |
| Yuri Volkov | "Breach contained. Stay behind me.": confident protector, squared shoulders and decisive check. Approved restrained gesture fits; not everyone needs a cheer. |
| Irina Karpova | "Your loss. My opportunity.": delighted acquisition, a knowing smirk and lifted chin as she appraises the empty pinch. The big collection line adds smug satisfaction, not grief or solemn reverence. |
| Mikhail Orlov | "perfectly calculated": proud vindication, a satisfied half-smile and assertive presentation of the receiving hand. The big line adds a hint of unstable exhilaration; do not make him only worried or shrinking. |
| Elena Morozova | "The pattern continues." / "I see you now!": quiet recognition becomes an alert, pleased discovery, with a purposeful head lift and sharpened gaze. |
| Zoya Miranova | "Which of us did that?" / "I collect followers": surprised curiosity with an unsettling flicker of pleasure; a brief head cant, then knowing composure. No extra faces or body changes. |
| Stone-Line Laborer | Road and everyone-getting-through lines: grounded communal hope, shoulders opening and a small resolved smile. Success belongs to the group, not a trophy display. |
| Ahesu | Nonverbal depths answering: imposing satisfaction through a proud neck lift and compact coil acknowledgement; not human comedy or an attack lunge. |
| Naia | "May you all serve life!": protective release with visible warmth and uplift, shield opening slightly after the receiving gesture rather than permanent mourning. |
| Meret-Anu | "Atlantis survives because I choose.": regal satisfaction and commanding certainty, lifted chin and composed sealing gesture. |
| Sahu-Ren | Remembrance lines: sincere solemn gratitude, a brief bowed acknowledgement; celebration would conflict with his voice. |
| Iset-Nara | "No crown can seal this truth.": intellectual triumph and defiance, precise confirmation followed by a confident head lift. |
| Thalassa-Nekh | "Yessss....." / "Feed us!": hungry delight, an unmistakably pleased expression and eager inward gathering; brief Seraph suggestion, no gore or physical trophy. |

Celebrate through readable silhouettes, purposeful timing and expression. Keep
anatomy, body scale, grounded contacts, prop grips and the engine-drawn Ember
contract unchanged. The first three art approvals remain valid; any revision
must be separately shown and reviewed. Carry this emotional range into the next
character, Irina, before commissioning the remaining poses.

## Closed City

### 1. Reactor Worker - Protective Pocket

ID: `r-reactor-worker`

- **Gather:** draw the photo-bearing left hand closer to the jacket; right hand
  keeps the wrench low. Leave receiving space just above the photo hand.
- **Hold:** press the photo hand protectively against the breast pocket, with a
  small squared-shoulder nod: survival, not boasting or looting.
- **Settle:** ease that hand back to idle while the wrench stays securely gripped.
- **Ember socket:** above the left thumb/photo edge, outside the printed image.
- **Sting:** 0.55 s; dry wrench-metal tick, short steam-like exhale, warm low tail.
- **Avoid:** an extra catching hand, altering the photograph, or putting the
  wrench down on a newly invented pipe. The pocketing idea is a protective mime.

### 2. VERA-7 - Sample Secured

ID: `r-vera-7`

- **Gather:** viewer-left sampling claw draws inward toward the existing front
  instrument face; mast pivots a little toward the arriving sample.
- **Hold:** claw closes around empty receiving space, pauses by the front panel,
  and the mast gives one precise acknowledgement tilt.
- **Settle:** return claw and mast to their parked positions, wheels stationary.
- **Ember socket:** clear gap inside the receiving claw, not painted on its lens.
- **Sting:** 0.65 s; short telemetry chirp, servo stop, restrained confirmation click.
- **Avoid:** a new storage hatch, human hands, chassis bounce, or a rolling wheelbase.

### 3. Major Yuri Volkov - Containment Check

ID: `r-yuri-volkov`

- **Gather:** bring the rifle-side wrist slightly inward, barrel safely lowered;
  the other arm continues to cradle the helmet.
- **Hold:** present the back of the gauntlet for a brief seal/check gesture, then
  square the shoulders toward the remaining threat.
- **Settle:** lower wrist and rifle into idle without changing either grip.
- **Ember socket:** just above the rifle-side gauntlet's back, clear of the grip.
- **Sting:** 0.60 s; pressure-seal clunk, two fine instrument clicks, low air tail.
- **Avoid:** an empty fist while simultaneously holding the rifle, a new visor
  over his exposed face, or dropping/teleporting the helmet.

### 4. Irina Karpova - Appraised and Claimed

ID: `r-irina-karpova`

- **Gather:** free left hand comes out of its idle pocket, thumb and index poised
  to receive; right hand keeps the existing keys.
- **Hold:** raise the empty pinch to chest level and appraise it with a small
  chin lift; the key ring stays restrained rather than becoming a trophy chain.
- **Settle:** return left hand toward its pocket and right hand to its idle height.
- **Ember socket:** the negative space between left thumb and index finger.
- **Sting:** 0.45 s; tiny metal/pen-like click and a muted low brass punctuation.
- **Avoid:** a third hand. The attack pistol has already returned to its concealed
  idle state; do not keep it in the receiving hand or discard it mid-claim.

### 5. Dr. Mikhail Orlov - An Impossible Reading

ID: `r-mikhail-orlov`

- **Gather:** left casting hand turns inward to receive, while the right retains
  the diagnostic instrument at the same height.
- **Hold:** raise the open left palm slightly toward eye level, hesitate as if
  checking a result that worries him; keep his head size and leg length unchanged.
- **Settle:** lower the palm to its idle casting position, without another blast.
- **Ember socket:** above the open left palm, separated from the instrument glass.
- **Sting:** 0.75 s; needle tick and a low reactor-hum swell with an uneasy decay.
- **Avoid:** copying a large attack flare, changing instrument hands, or an
  independently fitted sprite that makes Orlov shrink again.

### 6. Dr. Elena Morozova - Signal Received

ID: `r-elena-morozova`

- **Gather:** right hand lifts the existing electrode cap a little; left arm
  keeps the closed ledger against her body.
- **Hold:** suspend the cap near the ribs and incline her head slightly as if
  listening to a pattern; leave the cage's center clear for the received light.
- **Settle:** lower the cap gently to idle; do not reopen the signal attack.
- **Ember socket:** empty space just above the electrode cap's upper rim.
- **Sting:** 0.80 s; detuned receiver texture resolving into one soft glass chime.
- **Avoid:** cupping with a nonexistent free hand, wearing the cap in 120 ms,
  opening the ledger, intelligible radio speech, or a newly added device.

### 7. Zoya Miranova - Another Name

ID: `r-zoya-miranova`

- **Gather:** lift one hand toward the temple while the other steadies low;
  existing spectral strands curl inward, without moving either bare foot.
- **Hold:** fingertips stop just short of the temple, head tilts a fraction as
  though another memory has arrived; retain her established expression/identity.
- **Settle:** let the hand lower and strands relax to their idle envelope.
- **Ember socket:** beside the raised fingertips at the temple, not over her eyes.
- **Sting:** 0.70 s; fine static, nonverbal breath-like texture, a short quiet tail.
- **Avoid:** extra faces, random screaming, a body swap, readable whispered words,
  or a large aurora effect that forces a smaller character inside the canvas.

## Flood Survivors

### 8. Stone-Line Laborer / Menka - A Way Forward

ID: `a-flood-survivor-stone-line-laborer`

- **Gather:** free left palm reaches inward to receive; right hand keeps the
  existing working tool low, belt equipment and rope unchanged.
- **Hold:** turn the receiving palm flat near the belt as if checking a foundation
  stone; straighten the shoulders with practical resolve.
- **Settle:** lower the free hand to idle. Both bare feet stay planted throughout.
- **Ember socket:** just above the flat left palm, with separation from the belt.
- **Sting:** 0.60 s; a rounded stone knock, a little grit, and a low resonant tail.
- **Avoid:** kneeling to place a new board object. This claims light; it does not
  create a Stone marker or add an ability activation.

### 9. Ahesu - The Deep Keeps It

ID: `a-flood-survivor-ahesu`

- **Gather:** lower the neck a little toward the clear inner-coil space; keep
  the head's proportions, closed jaw, and broad grounded coil footprint.
- **Hold:** curl the upper neck protectively around that space with a compact
  tightening gesture, not a whole-body contraction.
- **Settle:** unwind only that small neck gesture and return to idle head height.
- **Ember socket:** open space inside the near coil, beneath the lowered chin.
- **Sting:** 0.85 s; low stone-current rumble, short water rush, restrained hiss.
- **Avoid:** swallowing an enemy/body part, closing all negative space, narrowing
  the coil to fit an effect, or reintroducing the removed rover fragments.
- **Mounted case:** this package plays only when Ahesu is the credited claimer;
  a mounted rider's claim must not also animate Ahesu.

### 10. Naia - Under Guard

ID: `a-flood-survivor-naia`

- **Gather:** draw the shield a little closer to her chest; the curved blade
  remains down and firmly in its assigned hand.
- **Hold:** angle the shield protectively around the receiving space with a
  slight head bow, remaining vigilant rather than triumphant.
- **Settle:** reopen the shield angle and return to the existing low blade guard.
- **Ember socket:** above the shield's inner upper edge, visible during Hold.
- **Sting:** 0.70 s; shield-metal contact over a low stone resonance and drum pulse.
- **Avoid:** the initial sketch's physical sarcophagus lid. She has no sarcophagus
  prop on her board figure; do not conjure one, kneel, or widen the rear leg.

### 11. Queen Meret-Anu - The Archive Closes

ID: `a-flood-survivor-meret-anu`

- **Gather:** free left hand draws toward the casket; right arm supports the
  existing closed Tide-Sealed Archive exactly as in idle.
- **Hold:** rest the left fingertips over the clasp/lid seam in a measured sealing
  gesture. A small, controlled chin dip signals a decision, not a victory cheer.
- **Settle:** release the clasp and return the left arm toward idle.
- **Ember socket:** just above the casket clasp, clear of her fingers and shell relief.
- **Sting:** 0.75 s; restrained tide swell ending in a clean bronze latch click.
- **Avoid:** opening a new animated lid, new contents, a different casket material,
  a changed crown, or resizing the queen to fit her reaching arm.

### 12. Sahu-Ren - A Memory Carried

ID: `a-flood-survivor-sahu-ren`

- **Gather:** free right hand draws inward from above the slab; left forearm
  continues to support the same etched stone archive.
- **Hold:** right hand pauses at the sternum, fingers gently open, with a small
  bowed-head acknowledgement: another burden accepted, not an attack charge.
- **Settle:** return the right hand above the slab and lift the chin toward idle.
- **Ember socket:** just forward of the sternum/right palm, not hidden behind fingers.
- **Sting:** 0.80 s; one breathy reed-like tone with a short layered nonverbal echo.
- **Avoid:** a closed-eye facial redesign, new memory faces, changing the tablet
  hand, a fingertip projectile, or reaching far enough to change his stance.

### 13. Iset-Nara - Measured Passage

ID: `a-flood-survivor-iset-nara`

- **Gather:** lift the right-hand dividers toward the plan tablet while the left
  hand supports it; keep the same two brass legs and tool length.
- **Hold:** pause with an empty measured gap between divider points above the
  tablet's upper edge, then close the dividers a little as if confirming a ratio.
- **Settle:** lower the dividers to her existing idle side position.
- **Ember socket:** between the two divider points, clear of the tablet drawing.
- **Sting:** 0.65 s; two ratio-like chime tones at a fifth, then a soft stone slide.
- **Avoid:** a third hand, a new box to seal, changing tablet light into painted
  Ember art, or recentering her left-of-canvas idle footprint at x256.

### 14. Thalassa-Nekh - Received by the Seraph

ID: `a-flood-survivor-thalassa-nekh`

- **Gather:** both hands draw inward, palms receiving, as existing water ribbons
  curl toward the chest; keep one visible bare foot and the original knee position.
- **Hold:** cup the empty receiving space near the sternum. Brief spectral
  opal-cyan shoulder fans echo her revised attack; the water then draws inward.
- **Settle:** dissolve the fans into ordinary water and reopen both arms toward idle.
- **Ember socket:** above the space between cupped palms, just forward of the chest.
- **Sting:** 0.90 s; wordless, non-syllabic submerged choir-like timbre and bubbles.
- **Avoid:** a full Seraph outfit/armor swap, extra arms or faces, a new attack
  wave, consuming a physical trophy, or a large wing spread that shrinks her.

## Artist-to-Engineer Handoff

For each approved package, record the actual Hold socket as final runtime PNG
pixel `(x,y)`. The positions above are semantic staging directions, NOT fabricated
pixel measurements. Mark approval and art/audio/line status independently.

Recommended: also record Gather/Settle socket positions if a hand or prop moves.
The engine needs an attachment path or interpolation so its wisp/glow does not
float away from a moving palm. On a left-facing mirror use `x' = 511 - x` for a
512-pixel image, then apply the same figure transform. Confirm this in a build.

Do not paint around an engine limitation or silently invent a runtime data schema.
The current attack registration/packing tools are attack-specific; do not run
them on claim art and accidentally replace an outfit's `attack` frames. Add or
extend a claim-aware pipeline under a separate implementation task.

Open engineering decisions before first integration: per-pose socket storage;
attack/claim interruption priority; one feedback package for multi-defeat actions;
and deferring the results overlay without delaying the underlying match result.
These are review points, not changes to damage, Ember ownership, or level rules.
