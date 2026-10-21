# Ember Claim: Contributor Spec

| Field | Value |
| --- | --- |
| Status | Draft for designer review, 2026-10-21 |
| For | Character artists, sound designers, writers. Section 7 is for whoever wires it into Godot. |
| Builds on | `LLD-figure-animation.md` (canvas, registration, attack art pipeline), `LLD-board-fx.md` (current Ember burst), `game/scripts/ui/sfx.gd` |

## 1. What we're making

When a character defeats an enemy and takes its Spirit Ember, that character gets a **signature claim moment** that lasts about a second. Each of the 14 roster characters has its own version, made of three things:

1. **A claim animation**: 3 new poses of the character's figure.
2. **A sound sting**: one short, non-voice sound in the character's style.
3. **A text line**: a speech line of 6 words or fewer that pops up beside the figure. There's a second line for big claims.

Every character is built as its own package, so contributors can take one character each and they ship one at a time. A character with no package yet keeps today's generic Ember burst.

**Why (Sam's lens, "the most fun version"):** right now a defeat looks the same whoever lands it. A claim moment makes every kill a small payoff that belongs to that character, gives Ember carriers presence on the board, and shows each character's personality during play instead of only in the guidebook. Text plus sting works on muted phones and needs no voice cast.

## 2. When it plays

| Situation | What plays |
| --- | --- |
| A character defeats an enemy (attack or ability) and gains 1 Ember | Claim animation, sting, **claim line** |
| The claimer gains 2 or more Embers at once (it defeated a carrier or a mounted pair) | The same animation and sting, with the **big-claim line** and a larger Ember burst |
| The claim also takes the character to Level 3 | The claim plays first, and the existing Level 3 flourish starts on the settle pose |
| The claimer is a mounted pair | The rider claims. The Mount doesn't animate. |
| A Leak or hazard defeat (no Ember is gained) | No claim moment. The existing defeat plays. |
| The defeat ends the match | The claim plays, then the victory screen |
| A second claim starts before the first finishes (fast AI turns) | The first is cut and the second plays |

It plays for both players, including the AI. Like every other board effect, it never blocks input and never delays or changes the rules: the rules have already resolved before it starts.

## 3. Timing

Times are measured from the attack's impact frame, when the defeat ghost starts.

| Time (ms) | Beat |
| --- | --- |
| 0–500 | The fallen enemy topples and fades (existing) |
| 150–500 | An Ember wisp arcs from the fallen tile to the claimer. Travel time is capped at 350 ms, so ranged kills take no longer. |
| 500 | The wisp lands: the **sting** plays, the **line** appears, and the claim animation starts |
| 500–1100 | Claim poses: gather 120 → hold 360 → settle 120, then the figure returns to idle |
| 500–1900 | The line holds for 1.2 s, then fades out over 200 ms |

The total board motion is about 1.1 s, and the line is gone by 1.9 s.

## 4. Deliverables per character

### 4A. Art: 3 claim poses

| File | Pose | Hold |
| --- | --- | --- |
| `claim-1-gather.png` | Reaches for or draws in the Ember (the wisp arrives here) | 120 ms |
| `claim-2-hold.png` | The signature beat: the character's most "them" stance with the Ember | 360 ms |
| `claim-3-settle.png` | Eases back toward the idle stance | 120 ms |

- These are the **same registration rules as the attack art**: a 512×768 transparent PNG on the same canvas as `default.png`, lowest pixel at y = 756 ± 4, and nothing within the 24 px side and 18 px top margins.
- Default outfit only. The pose must read at about 0.95 tile on a phone, so it needs a strong silhouette change from idle. Keep fine detail out.
- **The Ember isn't painted in.** The game draws the wisp and glow, so leave a clear area where the Ember will sit and mark it in the delivery notes (pixel x,y on the hold pose).
- Show a Spirit Ember as spirit or light. Never show it as a body part, trophy or gore (PRD-OQ-009).
- Deliver the same way as attack art: master sources, prompts, a layered `.ora`, a contact sheet and a review GIF in `docs/art-specs/ember-claim/<character-id>/`. Runtime PNGs go in `game/assets/figures/<character-id>/`.

### 4B. Audio: 1 sting

- `claim.wav`: 0.4–0.9 s, mono, 44.1 kHz, 16-bit, peak no higher than −1 dBFS. Start the attack within 10 ms and fade the tail cleanly to silence.
- **No voice or words.** Breaths, textures and instruments are fine. The text carries the words.
- It has to sit above the board ambience and current sounds, at about the loudness of today's hit sound. Match it against a build rather than solo.
- The sting must be original, or come with a licence that allows commercial use. Record its source in `docs/art-specs/ember-claim/<character-id>/AUDIO_SOURCE.md`.
- Runtime file: `game/assets/sfx/<character-id>/claim.wav`.

### 4C. Text: 2 lines

- **Claim line** and **big-claim line**, each 6 words or fewer.
- Written in the character's voice, drawn from their narrative in `data/cards/review_drafts/*.json`.
- No accent spelling, fake-Cyrillic letters or stock "comrade" clichés. No gore, and no body-part language for Embers.
- A creature or machine can use a non-verbal line in its own style (a telemetry readout or a stage direction).

## 5. Character sheet

The lines below are **drafts for designer approval**. Writers may replace them. The sound direction is a starting brief, not a requirement.

| Character | Claim hold-pose idea | Sting direction | Claim line (draft) | Big-claim line (draft) |
| --- | --- | --- | --- | --- |
| Reactor Worker | Pockets the Ember like a token, glances back | Wrench tap on pipe, steam hiss | "One more shift survived." | "That's overtime, then." |
| VERA-7 | Sample arm stows the Ember in its hull | Telemetry chirp, servo whir | "SAMPLE ACQUIRED." | "PAYLOAD UP. ROUTE CONTINUES." |
| Major Yuri Volkov | Seals the Ember in a gauntlet, visor glints | Pressure-seal clunk, Geiger click | "Contained." | "Area secured. Moving on." |
| Irina Karpova | Lifts it between two fingers, appraising | Pen click, low brass note | "Consider it a favor." | "You'll owe me for that." |
| Dr. Mikhail Orlov | Holds it up like a reading, reactor glow | Reactor hum swell, needle tick | "Not my fault. Not this time." | "The readings were right." |
| Dr. Elena Morozova | Cups it close, eyes half-closed | Detuned radio, soft chime | "Not random. Never random." | "The symbol answered." |
| Zoya Miranova | The Ember drifts to her temple | Static burst into whisper-texture (no words) | "I saw you coming." | "The voices go quiet." |
| Stone-Line Laborer | Sets it like a stone in a path | Stone knock, grit pour | "Another stone set." | "The road's clearer now." |
| Ahesu | The coils tighten around the Ember | Deep stone rumble, water rush | *(the stone-current hisses)* | *(the deep routes open)* |
| Naia | Lays it on the sarcophagus lid | Heavy lid scrape, low drum | "The vault keeps you now." | "Rest. I'll guard what remains." |
| Queen Meret-Anu | Closes it into the Tide-Sealed Archive | Tide swell, casket latch | "Preserved." | "Mercy can wait." |
| Sahu-Ren | Presses it to his chest, eyes shut | Reed tone, layered echo | "I will remember you." | "Another memory to carry." |
| Iset-Nara | Measures it against her divider, then seals it | Ratio chime (fifth interval), stone slide | "Measured. Sealed." | "Exactly as designed." |
| Thalassa-Nekh | The Ember sinks into her as black water glows | Underwater choir pad (no words), bubble rise | "The deep receives you." | "We drink your light." |

## 6. Review and done

1. **Per character, in this order:** art review (contact sheet and GIF), then sound review in a build, then line approval by the designer.
2. **Done** means it's registered and the Godot art-contract tests pass. Then it gets **seen in the exported web and Windows builds** on a real defeat, at a normal claim and a big claim, with sound on and sound off. Passing tests alone doesn't count as done.
3. Track progress in a queue table in `docs/art-specs/ember-claim/README.md`, the same way as the attack-art queue.

## 7. Engineering notes (for the Godot side)

- **Trigger:** `EventBus.spirit_ember_picked_up(character_id)`. It needs a `gained: int` parameter to tell a claim from a big claim (`leveling_system.gd` knows `1 + carried`).
- **Data:** claim frames go in a `"claim"` list on each outfit in `wardrobe.json`, beside `"attack"`, because art belongs to the outfit. Lines go in a new `data/ember_lines.json` (`{character_id: {claim, big}}`), synced by `sync_game_content.ps1`. The sting loads from `game/assets/sfx/<id>/claim.wav`. This is the first shipped SFX file, because `sfx.gd` synthesizes everything today.
- **Fallbacks, per piece:** with no frames, use a procedural stretch. With no sting, play the existing synth `"ember"` sound. With no line, show no line. Any subset can ship.
- **Timing:** the claim waits for the attack's impact frame, the same as the existing Ember burst (`impact_for`).
- **Settings:** the sting follows Sound. Add a **Character lines** on/off toggle. Add a 40 ms `claim` haptic.
- **Tests:** extend `test_attack_art_contract.gd` to claim frames (3 poses, the same canvas and registration). Add unit tests for the Section 2 table: Leak means no claim, a mounted pair means a big claim, and Level 3 goes after the claim.

## 8. Open questions

- [NEED: who takes art, audio and writing, and the target date]
- [NEED: designer approval of the 28 draft lines, plus a sensitivity read of the Closed City lines (CLAUDE.md guardrail)]
- Sam's stretch goal: **rival lines**, a special line when one specific character defeats another. Leave it out of v1, since the current roster has no cross-faction rivalries written yet.
- Should a later outfit (Zoya's Aurora Rite, Thalassa-Nekh's Seraph) need its own claim poses, or reuse the default's? The attack-art rule says outfits never borrow, which means every outfit needs its own claim poses.
- Is a claim moment of about 1.1 s every defeat too long for the 5–12 minute mobile match target? Time it in playtests. The hold pose (360 ms) is the first thing to trim.
