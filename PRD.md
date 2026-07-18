# MythCards Product Requirements Document

## 1. Vision

MythCards is a mobile-first, turn-based tactical card game played on a chess-like board. Players command a small roster of characters represented by cards, using positioning, faction identity, and tactical abilities to outplay an opponent over short strategic matches.

The game should feel like a blend of chess, collectible card games, mythic civilization strategy, occult secret history, and dreamlike alternate realities: easy to understand at the surface, but deep enough that every move, card choice, and board position matters.

The core story begins in a Soviet closed city in the 1980s. After a strange nuclear accident, a scientist passes out and his unconscious mind becomes a convergence point where realities, myths, histories, and occult forces play out as tactical battles. The battles may be dreams, transmissions, ancestral memories, or real worlds pressing through one damaged human mind.

## 2. Product Goals

| ID | Goal |
| --- | --- |
| PRD-GOAL-001 | Create a polished mobile tactical game with clear rules, readable turns, and satisfying strategic depth. |
| PRD-GOAL-002 | Build a card and character system that supports 7 character types, with multiple cultural or civilization-based versions of each type. |
| PRD-GOAL-003 | Make matches short enough for mobile play while still rewarding mastery. |
| PRD-GOAL-004 | Establish a flexible rules foundation that can support future cards, cultures, modes, events, and expansions. |
| PRD-GOAL-005 | Establish a story and content framework where each faction contains multiple hidden sub-areas, each with its own style, mechanics, relics, events, and narrative identity. |
| PRD-GOAL-006 | Design the game so it can eventually support both solo play and PvP. |

## 3. Target Audience

Primary players:
- Mobile strategy players who enjoy chess, tactics games, collectible card games, and turn-based combat.
- Players who like building rosters, discovering synergies, and mastering factions.

Secondary players:
- Fans of mythology, history-inspired civilizations, and fantasy tactics.
- Competitive players looking for asynchronous or ranked strategy matches.

## 4. Core Game Pillars

### Tactical Clarity

Players should always understand the board state, legal moves, threat zones, and likely consequences of an action.

### Card-Driven Identity

Cards are not just random effects. They represent characters, abilities, culture, and strategy.

### Civilization Flavor

Each culture or civilization should meaningfully change how familiar character types play.

### Mythic Convergence

The world should combine real history, true mythology, esoteric and occult ideas, and original fantasy. Fantasy characters should fill out emotional story gaps, connect incompatible eras, and help the setting feel playable rather than documentary.

### Sub-Area Identity

Each faction is made of three story sub-areas. These sub-areas are not necessarily overtly marked in-game, but they should guide card mechanics, art direction, relics, events, and story arcs.

### Short, Meaningful Matches

Every turn should create interesting decisions without making mobile sessions feel exhausting.

### Expandable Systems

The rules should allow new cultures, characters, boards, and mechanics without redesigning the game from scratch.

## 5. Game Overview

### Match Structure

- Two players face each other on a grid-based board.
- Each player brings a fixed squad of character cards that begins on the board.
- Players alternate turns.
- On a turn, a player may move characters, attack, activate character abilities, resolve relic/event effects, or pass depending on the board state.
- Victory comes from capturing the enemy Hero or defeating every opposing character.

### Initial Board Concept

Recommended starting prototype:
- Board size: 7x7, creating a single center tile and a tighter tactical space.
- Units start on opposite sides.
- Each side starts with one character of each type: Common, Mount, Warrior, Leader, Hero, Specialist, and Mystic.
- Some spaces may later contain terrain, objectives, temples, relics, or civilization-specific structures.

### Initial Match Length Target

- First prototype: 10-20 minutes.
- Mobile production target: 5-12 minutes for standard matches.

## 6. Core Gameplay Loop

1. Player selects a culture and fixed starting squad.
2. Player enters a match.
3. Units are deployed to the board.
4. Players alternate turns.
5. Each turn creates decisions around movement, attacks, character abilities, relic/event effects, and positioning.
6. A player wins by completing the victory condition.
7. Player earns fair progression such as cosmetics, mastery, rank progress, or non-gameplay rewards.
8. Player adjusts strategy and plays again.

## 7. Character Types

The game has 7 base character types. These function like strategic archetypes. Each culture has a distinct version of each type.

Current character type direction:

| Type | Role | Tactical Identity |
| --- | --- | --- |
| Leader | Primary objective piece | Powerful, limited, must be protected |
| Hero | Elite tactical piece | Strong signature abilities, high impact, limited availability |
| Mount | Mobile piece | Fast movement, flanking, charge attacks, repositioning |
| Specialist | Utility piece | Unique rules, support effects, traps, terrain, or culture mechanics |
| Warrior | Core combat piece | Reliable attacks, board control, frontline pressure |
| Common | Basic unit | Cheap, simple, expandable, useful for blocking and setup |
| Mystic | Magic/support piece | Frost, tide, curses, blessings, protection, or board-state manipulation |

Prototype note:
The Hero is currently the most important capturable piece, while the Leader is a powerful command unit that supports the faction's strategy.

## 8. Cultures And Civilizations

Each civilization provides a different interpretation of the 7 character types. The culture should affect mechanics, art direction, naming, and playstyle.

Prototype cultures:

| Culture | Playstyle Theme | Example Mechanics |
| --- | --- | --- |
| Russian-inspired | Endurance, cold, defense, disciplined counterattacks | Frost zones, fortified units, winter attrition, resilient commons |
| Atlantean | Divine spirit leadership, quartz technology, hive-mind coordination, spiritual power | Resonance links, crystal relays, shared senses, spiritual shields, teleportation, board manipulation |

Important note:
Real-world-inspired cultures should be handled with respect and research. The Russian-inspired faction should avoid stereotypes and should draw from a thoughtful mix of folklore, geography, architecture, military history, and mythic fantasy. Atlanteans are mythic and speculative: their fantasy identity centers on divine spirit leaders, advanced quartz technology, hive-mind coordination, and spiritual capabilities far beyond the modern world.

### Story Premise And Tone

The first major story arc begins in the Russian closed city sub-area. In the 1980s, a scientist working near nuclear, cosmonaut, industrial, and consciousness experiments is caught in a strange reactor accident. He loses consciousness, and within that unconscious state entire worlds begin to unfold.

The scientist's mind is not necessarily inventing these worlds. It may be receiving them, remembering them, or acting as a gate. Russian war memory, northern myth, Soviet forbidden science, Atlantean cosmic knowledge, crystal technology, and post-flood survival all collide inside the convergence.

The tone should support:
- Real historical echoes without becoming a literal historical simulation.
- Mythological and occult material treated as meaningful within the world.
- Fantasy characters who complete the narrative and make the factions playable.
- Uncertainty about whether the battles are dreams, alternate realities, ancestral memories, or actual worlds.

Direction (decided): lean further into fiction and abstraction rather than depicting real people, units, or events directly. Real-world grounding should survive as recognizable hints — eras, professions, imagery, geography, technology — rather than as literal named figures or documented incidents. This resolves part of PRD-OQ-004 in favor of myth-inspired/fictional framing over historical naming.

### Faction Sub-Area Structure

Each faction has three sub-areas. Each sub-area is intended to eventually contain one of each character type, plus its own relics and events.

Per sub-area target content:
- 1 Common
- 1 Mount
- 1 Warrior
- 1 Leader
- 1 Hero
- 1 Specialist
- 1 Mystic
- Sub-area-specific relic cards
- Sub-area-specific event cards

This creates a long-term structure of 21 character cards per faction, before variants or expansions.

Russian-inspired sub-areas:

| Sub-Area | Story Identity | Style | Mechanical Identity |
| --- | --- | --- | --- |
| Winter Front | Army setting around World War II, siege warfare, frozen battlefields, sacred banners, battlefield ghosts | Military coats, snow, icons, war maps, trenches, ruined cities | Endurance, defensive positioning, last stands, formation buffs, attrition |
| Far North | Remote northern wilderness, hidden villages, white animals, shamans, exiles, circus survivors, aurora gates | Ice forests, iron birch, northern lights, animal spirits, traveling performers | Mobility, frost, ambush, spirit bonds, evasive movement |
| Closed City | 1980s Soviet science and industry, nuclear power, leaks, cosmonauts, forbidden programs, consciousness experiments | Concrete, reactor glow, warning lights, lead glass, telemetry, occult diagrams hidden in technical systems | Risk/reward effects, radiation or leak markers, placed objects, overloads, signals, delayed effects |

Atlantean sub-areas:

| Sub-Area | Story Identity | Style | Mechanical Identity |
| --- | --- | --- | --- |
| First Mind | Early Atlantis at the height of mental, spiritual, and cosmic knowledge | Star maps, dream architecture, psychic councils, living geometry | Prediction, card manipulation, shared actions, telepathy, range through linked minds |
| Crystal Dominion | Later Atlantis with great crystals, power grids, resonance engines, pylons, and empire before collapse | Quartz armor, obelisks, harmonic weapons, energy channels, luminous cities | Pylons, shields, range boosts, resonance networks, board control through structures |
| Flood Survivors | Post-flood Atlanteans who survived underwater, underground, or migrated into Egypt and mystery traditions | Drowned temples, sealed chambers, subterranean routes, Egyptian influence, memory stones | Survival, hidden movement, recursion, relic preservation, return-from-defeat effects |

Design note:
The sub-areas should have recognizable internal mechanics, but players should not need to memorize the sub-area taxonomy to play. The cards should communicate their identity through names, effects, art, and synergies.

### Prototype Character Roster

Prototype squad composition:
- Each side may field only 1 Hero.
- Each side may field only 1 Leader.
- Each side may field up to 2 copies of each non-common, non-unique type: Mount, Warrior, Specialist, and Mystic.
- Common characters are the flexible filler type and may be used in larger numbers if the final squad size requires it.
- For the first paper prototype, use 1 copy of each of the 7 character cards per side.
- Current paper-test recommendation: use exactly one of each character type per side on a 7x7 board.

Russian-inspired starting roster:

| Type | Character | Initial Gameplay Idea |
| --- | --- | --- |
| Common | Gymnast | Agile low-cost unit that can vault over adjacent allies or obstacles |
| Mount | White Siberian Tiger | Fast, dangerous mount with an activated Pounce that can mark a later attack for +2 ATK while the Tiger is not mounted |
| Warrior | Sniper | Long-range attacker that threatens lanes but is vulnerable up close |
| Leader | Army General | Command unit that buffs nearby allies or grants a bonus action to one unit |
| Hero | Bogatyr Champion | Durable mythic hero designed to hold the center and survive capture attempts |
| Specialist | Winter Engineer | Creates barricades, frost traps, or fortified tiles to control enemy movement |
| Mystic | Frost Seer | Uses winter magic to slow enemies, shield allies, or reveal hidden threats |

Atlantean starting roster:

| Type | Character | Initial Gameplay Idea |
| --- | --- | --- |
| Common | Quartz Attendant | Basic hive-mind unit that becomes stronger when adjacent to other Atlanteans |
| Mount | Manta Glider | Mobile crystalline flyer that can move over occupied spaces and water-like terrain |
| Warrior | Resonance Guard | Core defender that uses quartz armor to redirect or reduce incoming damage |
| Leader | Divine Conductor | Spirit leader who coordinates linked allies and shares action bonuses through the hive mind |
| Hero | Oracle Sovereign | Capturable spiritual ruler who channels the civilization's collective consciousness |
| Specialist | Crystal Architect | Builds quartz pylons, relay nodes, or energy bridges that reshape movement and range |
| Mystic | Astral Harmonic | Advanced spiritual caster who shields allies, disrupts enemies, and manipulates resonance links |

### Prototype Character Cards

First-pass balance assumptions:
- `HP` is the damage a character can take before being defeated.
- `ATK` is the damage dealt by a basic attack.
- `MOVE` is the number of tiles a character can move with 1 action.
- `RANGE` is basic attack range in tiles.
- Default movement pattern is orthogonal: vertical and horizontal movement only.
- Default attack pattern is orthogonal line-of-sight: vertical and horizontal only.
- Line-of-sight rule (clarified): ranged attacks, and any AP ability that deals damage or targets at range, cannot pass through an occupied tile — ally or enemy — unless the specific card or ability explicitly states it can. Divine Conductor's Link Mind is the first card to use this exception (its target may ignore one allied character when checking line-of-sight). `[NEED: confirm whether non-damage support/utility abilities (e.g. Command, Resonance Shield, Foresight, Pylon range boost) are also subject to line-of-sight, or are exempt by default — see PRD-OQ-011]`
- Diagonal, area, jump, teleport, or unusual patterns are special-case rules printed on characters, relics, events, or future cards.
- Movement, basic attacks, and abilities each cost 1 AP from the player's turn pool, gated by that character having remaining character AP (see Section 11-12).
- Level 2 upgrades should land as a clear, noticeable power spike (not a minor +1 tweak); Level 3 upgrades should be transformative — a significant stat jump and/or a game-changing new ability — without making a leveled character automatically win the game outright. (Design directive added 2026-07-18; see Section 9's Open balance task. The Level 2/3 upgrade text in the character tables below has not yet been rewritten to this standard — flagged as a follow-up revision pass.)
- Low-ATK characters should have stronger utility abilities so they remain fun even when their basic attacks are weak.

Mounted character rules:
- A Hero or Leader may mount an allied Mount character as an action if adjacent to that Mount.
- Mounting moves the Hero or Leader onto the Mount's tile. They occupy the same space as one combined mounted pair.
- A mounted pair uses the Hero or Leader's HP, ATK, RANGE, level, and abilities, but uses the Mount's MOVE and movement pattern.
- The Mount cannot take separate actions while mounted.
- Damage is applied to the mounted Hero or Leader's HP. When that HP reaches 0, both the rider and Mount are defeated.
- Dismounting is an action. The rider remains on the current tile and the Mount is placed on an adjacent empty tile. If no adjacent empty tile exists, the pair cannot dismount.

Russian-inspired cards:

| Character | Type | HP | ATK | MOVE | RANGE | Level 1 Ability | Level 2 Upgrade | Level 3 Upgrade |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| Gymnast | Common | 2 | 1 | 3 | 1 | Passive: Vault may move through 1 adjacent allied character during movement. | +1 MOVE. Vault may pass through enemies but cannot end on their tile. | After Vaulting, may make a 1-damage attack against an adjacent enemy. |
| White Siberian Tiger | Mount | 4 | 2 | 4 | 1 | Activated: Pounce may be activated only while the Tiger is not mounted. It marks the Tiger's next attack after moving as +2 ATK. Movement and attack costs are still paid normally by the available AP/action rules. | +1 HP. Pounce also pushes the target 1 tile if possible. | Snow Stalker: Once per turn, ignores the first 1 damage it would take after moving. |
| Sniper | Warrior | 3 | 2 | 2 | 4 | Passive: Aim gives this character's basic attack +1 RANGE if it did not move this turn. | Piercing Shot: Attacks ignore 1 shield or damage reduction. | Mark Target: After damaging an enemy, the next allied attack against that enemy deals +1 damage. |
| Army General | Leader | 5 | 1 | 2 | 1 | AP Ability: Command chooses an allied character within 2 tiles. That ally gains +1 ATK on its next attack this turn or may move 1 tile without spending an action. | Command range becomes 3. | Tactical Order: Once per turn, Command may instead refresh an adjacent ally's action point. |
| Bogatyr Champion | Hero | 6 | 2 | 2 | 1 | Passive: Stand Firm gives +1 maximum and current HP while this character is on or adjacent to the center tile. | Heroic Guard: Adjacent allies take -1 damage from attacks. | Last Oath: The first time this character would be defeated, it remains at 1 HP instead. |
| Winter Engineer | Specialist | 3 | 1 | 2 | 1 | AP Ability: Barricade creates 1 barricade on an adjacent empty tile, or repairs an adjacent barricade or placed object by 1 HP. Barricades block movement and have 2 HP. | Barricades have 3 HP and adjacent allies gain +1 defense against ranged attacks. | Frozen Works: Once per turn, may place a frost tile instead of a barricade. Enemies entering frost stop moving. |
| Frost Seer | Mystic | 3 | 1 | 2 | 3 | AP Ability: Chill deals 1 damage at range 3. Target's MOVE is reduced by 1 and it cannot mount or dismount on its next turn. | Winter Veil: May shield an ally within 3 tiles for 1 damage prevention. | Deep Freeze: Chill also prevents the target from using reaction or bonus movement effects next turn. |

Atlantean cards:

| Character | Type | HP | ATK | MOVE | RANGE | Level 1 Ability | Level 2 Upgrade | Level 3 Upgrade |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| Quartz Attendant | Common | 2 | 1 | 2 | 1 | Passive: Synchronize gives +1 ATK while adjacent to another Atlantean. | Shared Pulse: Adjacent Atlanteans gain +1 defense against the first attack each turn. | Collective Step: If adjacent to another Atlantean, may move 1 extra tile. |
| Manta Glider | Mount | 3 | 1 | 4 | 1 | Passive: Glide may move over occupied tiles but must end on an empty tile. If carrying a Hero or Leader, the mounted pair may also glide. | +1 ATK after moving over any character this turn. | Phase Current: Once per turn, may ignore terrain and barricades during movement. |
| Resonance Guard | Warrior | 5 | 1 | 2 | 1 | Passive: Quartz Armor reduces ranged attack damage by 1. | Redirect: Once per turn, may take damage for an adjacent ally. | Resonant Counter: After reducing damage, deals 1 damage back to the attacker if within range 2. |
| Divine Conductor | Leader | 4 | 1 | 2 | 3 | AP Ability: Link Mind chooses an ally within 3 tiles. Until end of turn, that ally may use the Conductor's RANGE for its ability if valid, and may ignore one allied character when checking line-of-sight. | Link Mind may target 2 allies if both are within 2 tiles of each other. | Perfect Chord: Once per turn, when a linked ally defeats an enemy, refresh that ally's action point. |
| Oracle Sovereign | Hero | 5 | 1 | 2 | 3 | AP Ability: Foresight reveals the next shared relic/event card. You may place it on the bottom of the deck. Then give one adjacent ally a 1-damage shield. | Spirit Mantle: Gains a 1-damage shield at the start of your turn. | Collective Ascension: Once per match, all adjacent allies heal 1 and gain +1 MOVE this turn. |
| Crystal Architect | Specialist | 3 | 1 | 2 | 2 | AP Ability: Pylon places a quartz pylon on an adjacent empty tile, or moves an existing allied pylon 1 tile. Allies within 2 tiles of a pylon gain +1 RANGE on abilities. | Pylons also count as adjacent Atlanteans for Synchronize effects. | Relay Gate: Once per turn, an ally adjacent to a pylon may teleport to another pylon within 4 tiles. |
| Astral Harmonic | Mystic | 3 | 1 | 2 | 3 | AP Ability: Resonance Shield shields an ally within 3 tiles for 1 damage prevention. If that ally is mounted, the shield prevents 2 damage instead. | Harmonic Bind: Shielded allies also cannot be pushed or displaced this turn. | Astral Echo: After shielding an ally, may deal 1 damage to an enemy within 2 tiles of that ally. |

Future culture examples:

| Culture | Playstyle Theme | Example Mechanics |
| --- | --- | --- |
| Greek-inspired | Heroic combos and divine favor | Blessings, heroic duels, fate tokens |
| Egyptian-inspired | Resurrection and monuments | Tombs, afterlife effects, structure control |
| Norse-inspired | Aggression and sacrifice | Rage, last-stand bonuses, doom counters |
| Japanese-inspired | Precision and tempo | Stances, honor, reactive counters |
| Aztec-inspired | Ritual and resource conversion | Sacrifice, sun counters, blood offerings |
| Celtic-inspired | Nature and transformation | Growth, terrain, shapeshifting |
| Mesopotamian-inspired | Law, kingship, and omens | Edicts, tablets, prophecy effects |

## 9. Card Categories

### Character Cards

Represent units placed on the board.

Prototype placement rule:
- Character cards do not have a cost.
- All character cards are placed on the board at the beginning of the match.
- Players win by capturing the enemy Hero or defeating all opposing characters.

Deckbuilding direction (decided): the paper prototype and MVP keep the fixed 1-of-each-type squad described in Section 20. Deckbuilding is a planned post-prototype system, once the fixed-squad core loop is validated: a deck may combine any mix of the 7 character types plus relics/events, with no cost/mana stat on character cards — legality is governed by composition rules only (e.g. max 1 Hero, max 1 Leader, per Section 8's roster-composition limits), not a mana curve. Scope and squad-size rules for constructed decks are not yet defined and should be drafted when this system is prioritized.

Properties may include:
- Type
- Culture
- Health
- Attack
- Movement pattern
- Range
- Ability text
- Upgrade path

Upgrade path:
- Each character has 3 levels.
- Level 1 is the starting version.
- Level 2 is earned by crossing all the way to the opponent's edge of the board.
- Level 3 is earned after a Level 2 character collects a Spirit Ember released by a defeated enemy and carries it to the center square.
- Levels 2 and 3 improve that character's existing identity without changing the card into a different character.
- Card levels are part of match gameplay, not account progression or paid unlocks.

### Character Abilities

Character abilities are printed on character cards and are used as actions during the match. They are not separately drawn or purchased.

Ability timing labels:
- `Passive:` means the ability is always on or modifies another action. It does not require spending AP by itself.
- `AP Ability:` means the ability is activated by spending that character's action point.
- `Activated:` means the ability is intentionally turned on or declared by the player. It may spend AP, mark a future action, or require another cost as printed.

Examples:
- Move a character again.
- Deal damage in a line.
- Shield an ally.
- Swap two characters.
- Summon terrain.
- Trigger a culture-specific mechanic.

### Relic Cards

Persistent effects that change strategy over multiple turns.

Prototype draw rule:
- Relic cards are mixed into a shared non-character deck used by both players.
- The active player draws one relic or event card each turn from this shared deck.
- Each player may have only 1 active relic at a time.
- When a player draws a relic while they already have an active relic, they may choose to replace the current relic or discard/ignore the newly drawn relic.
- Relic replacement choices should be handled in the game UI rather than through browser/native page-leave style popups.

Examples:
- A temple that empowers nearby units.
- A relic that modifies draw rules.
- A banner that boosts a character type.

### Event Cards

Temporary global effects.

Prototype draw rule:
- Event cards are mixed into the same shared non-character deck as relic cards.
- One shared relic or event draw happens each turn for the active player, creating a board condition both players must adapt to.
- Events do not occupy a player's relic slot. They resolve immediately or remain active for their printed duration.

Examples:
- Eclipse: ranged attacks are weakened this round.
- Festival: both players draw extra cards.
- Sandstorm: movement is reduced in certain lanes.

### Prototype Relic And Event Cards

Relic and event cards are faction-themed, but they are still mixed into one shared deck used by both players. This means either player can benefit from or suffer from either faction's mythic forces, which keeps the paper prototype unpredictable without giving one faction a private card deck. Each player tracks one active relic slot. If a player draws a relic while their relic slot is already full, they choose whether to replace their active relic.

Design intent (decided): the shared draw is not incidental variance to be minimized — it is a deliberate pillar. Both players adapting to the same unpredictable pull, regardless of faction, is meant to add randomness and forced tactical thinking each turn. Balance and playtesting should tune this pull (frequency, power level, active-slot rules), not replace it with private per-culture decks.

Russian-inspired relics:

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Winter Palace Standard | Relic | Persistent | Your Hero and Leader each gain +1 maximum HP while this relic is active. |
| Iron Birch Talisman | Relic | Persistent | Your Common and Warrior each gain +1 maximum HP while this relic is active. |
| General's War Map | Relic | Persistent | Once each turn, one of your characters gains +1 RANGE on its next attack or ability. |

Russian-inspired events:

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Whiteout | Event | 1 round | All ranged attacks and ranged abilities have -1 RANGE, minimum 1. |
| Frozen Center | Event | 1 round | The center row and center tile count as frost. A character entering frost stops moving. |
| Rally From The Snow | Event | Immediate | The active player heals 1 HP on one damaged character. |
| Long Winter March | Event | 1 turn | The active player's first movement action this turn gains +1 MOVE. |

Atlantean relics:

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Quartz Heart Core | Relic | Persistent | Your shields prevent +1 additional damage while this relic is active. |
| Hall Of Shared Minds | Relic | Persistent | Your adjacent characters gain +1 RANGE on abilities. |
| Tideglass Obelisk | Relic | Persistent | Your characters adjacent to a placed object gain +1 RANGE on attacks and abilities. |

Atlantean events:

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Resonance Surge | Event | 1 turn | The active player's first ability this turn has +1 RANGE. |
| Psychic Undertow | Event | 1 turn | The active player's first attack this turn may push or pull the target 1 tile. |
| Crystal Tide | Event | 1 turn | The active player's characters have +1 RANGE on abilities this turn. |
| Dream Of The Deep City | Event | Immediate | Reveal the next shared relic/event card. The active player may leave it on top or place it on the bottom of the deck. |

### Spirit Ember Leveling

The current level-up rule has two stages:

| Level | Requirement | Design Purpose |
| --- | --- | --- |
| Level 2 | A Level 1 character crosses to the opponent's board edge. | Rewards penetration, risk, and reaching enemy territory. |
| Level 3 | A Level 2 character collects a Spirit Ember from a defeated enemy, then reaches the center square. | Forces a second tactical objective and pulls upgraded pieces back toward the contested middle. |

Terminology (decided):
- The mechanic and its rules/UI name is `Spirit Ember` — a fragment of spirit/myth released when an enemy is defeated within the convergence, not a literal body part. This replaces the earlier "defeat trophy / scalp / ear" language and resolves PRD-RISK-006 and PRD-OQ-009.
- The center square becomes important for Level 3 progression in addition to positioning and relic/event effects.

Open balance task: leveling should reliably be worth pursuing, not just theoretically available. Given the small 7-unit squads and instant-loss-on-Hero-capture, the risk of exposing a piece to reach the enemy edge (Level 2) or return to center with a Spirit Ember (Level 3) needs explicit playtesting to confirm the reward justifies the exposure — tune HP/ability power at Level 2/3, or the risk of the crossing itself, if early paper matches show players never attempt it.

Design directive (decided, 2026-07-18): early paper-test feedback is that leveling feels hard to justify — most current Level 2 upgrades are incremental (+1 to a stat, a minor rider effect), so the risk of the crossing rarely feels worth it. Going forward, Level 2 upgrades should read as an obvious, noticeable power spike, and Level 3 upgrades should be transformative: a significant stat jump, a new game-changing ability, or a real shift in how the character plays. This is a principle for the next revision pass — the Section 8 character tables have not yet been rewritten to this standard.

## 10. Board Design

### Starting Board

Prototype with a clean 7x7 grid and one center tile.

Initial requirements:
- Clear ownership and orientation for both players.
- Tap-friendly tiles.
- Highlight legal movement.
- Highlight attack ranges.
- Show danger zones.
- Support drag-and-drop and tap-to-confirm controls.
- The center tile should be visually marked during testing because it is a natural tactical focal point.
- The center tile must support Level 3 advancement when a Level 2 character carrying a Spirit Ember reaches it.
- The digital tabletop prototype should support manually placed board objects, such as pylons, barricades, or other playtest markers.

### Future Board Features

- Terrain tiles
- Objectives
- Obstacles
- Culture-specific board skins
- Ranked maps
- Puzzle/challenge maps

## 11. Turn System

Recommended prototype turn structure:

1. Start of turn effects resolve.
2. The active player's AP pool refreshes: 2 AP on that player's first turn of the match, 4 AP on every turn after.
3. Each character's own AP stat refreshes (usually 1; higher for some characters or via effects).
4. The active player draws 1 shared relic or event card for the turn.
5. Player takes actions in any order, limited by both the player's remaining pool AP and the acting character's remaining character AP:
   - Move a character by spending 1 pool AP and 1 of that character's AP.
   - Attack with a character by spending 1 pool AP and 1 of that character's AP.
   - Activate an ability by spending 1 pool AP and 1 of that character's AP.
   - Pick up, carry, or deliver a Spirit Ember if the final prototype implementation treats Spirit Embers as explicit board objects or status markers.
   - Resolve any active relic or event effects.
6. Player ends turn.
7. End of turn effects resolve.

Recommendation:
Because the pool (2 or 4 AP) is smaller than the full squad (7 characters), most turns will not see every character act — this is intentional. It forces the player to prioritize which pieces move or fight each turn rather than activating the whole board, and the smaller first-turn pool (2 AP vs. 4 AP afterward) is the prototype's mitigation for first-move advantage.

## 12. Resources

Possible resource systems:

| System | Pros | Cons |
| --- | --- | --- |
| Mana-style resource | Familiar to card players | Can feel detached from board tactics |
| Action points | Strong tactical clarity | May limit card variety |
| Culture-specific resources | Strong identity | Harder to balance |
| Hybrid action + mana | Flexible | More complex for new players |

Prototype recommendation (decided):
- The active player has a turn-level AP pool: 2 AP on their first turn of the match, 4 AP every turn after. Pool AP may be spent on any combination of the player's characters' actions.
- Independently, each character has its own AP stat — usually 1, meaning that character can act at most once per turn regardless of the pool. Some characters or effects grant a higher character AP, letting that single character take multiple actions in one turn if the pool allows it.
- Movement, attacking, and activating an ability each cost 1 pool AP, gated by the acting character having remaining character AP of its own.
- Because the pool caps total actions per turn well below the squad size, not every character acts every turn — a deliberate tactical constraint, not an oversight.
- Some cards may allow bonus movement, reaction actions, or AP recovery (to either the pool or a specific character's AP).
- Some cultures may generate special tokens later.

## 13. Victory Conditions

Prototype victory condition:

### Hero Capture

Win immediately by capturing the enemy Hero.

Pros:
- Strong chess-like clarity.
- Gives each side a clear piece to protect.
- Creates tension around positioning, sacrifice, and threat zones.

Design note:
The Hero should be powerful enough to matter, but vulnerable enough that careless positioning can lose the game.

### Army Defeat

If a player defeats all opposing characters, that player also wins.

Pros:
- Prevents awkward end states where the Hero is difficult to reach but the opponent has no meaningful pieces left.
- Rewards aggressive strategies and full-board control.

Future options:
- Objective control can be tested later as an alternate mode.
- Morale or life total can be tested later if the game needs a more card-game-like win condition.

## 14. Progression

Progression must keep the game fair. Cards stay mechanically consistent, and unlocks should not create competitive advantages.

### Match Progression

- Each character has 3 levels.
- Characters reach Level 2 during a match by crossing to the opponent's edge of the board.
- Characters reach Level 3 by collecting a Spirit Ember from a defeated enemy and taking it to the center square.
- Level-ups should improve or deepen the character's existing role.
- Level-ups reset each match unless a future mode explicitly says otherwise.

### Account Progression

Potential account progression systems:

- Player level
- Culture mastery levels
- Cosmetic skins
- Alternate card art
- Board skins
- Titles, banners, and profile frames
- Ranked ladder
- Daily quests
- Puzzle challenges
- Seasonal events

Important design constraint:
Avoid pay-to-win progression. Competitive modes should prioritize fair access, readable balance, and identical gameplay access to all cards and character levels.

## 15. Game Modes

### Prototype Mode

- Local hotseat match
- Fixed starting squads
- Shared relic/event deck
- Basic board
- No account system
- No monetization

### MVP Modes

- Tutorial
- AI match
- Casual PvP
- Squad viewer or cosmetic loadout
- Collection viewer

### Future Modes

- Ranked PvP
- Standard / Asynchronous PvP — untimed, thoughtful pacing; matches may be played over multiple days between friends, with no move timer.
- Timer-based / Blitz PvP — a turn or match timer forces faster decisions for players who want a quicker, more real-time match. Exact timer length: `[NEED: TBD, to be set during balance/playtesting]`.
- Campaign
- Draft mode
- Puzzle mode
- Limited-time events
- Guild/clan features

## 16. Mobile UX Requirements

- Portrait orientation should be considered first unless board readability requires landscape.
- Board must remain readable on small phones.
- Cards need large, legible text and icons.
- Important board state should be visible without constant menu opening.
- Character status reminders such as shield, temporary attack, temporary movement, or Pounce should be visible directly on the board through small indicators or badges.
- Players should be able to inspect cards, units, movement, and threat zones with taps or long-presses.
- Turns should have confirmations for irreversible actions.
- Animations should communicate state changes without slowing play too much.

## 17. Art Direction

Initial direction:
- Mythic, readable, high-contrast tactical fantasy.
- Each culture should have distinct silhouettes, color accents, iconography, and board motifs.
- Unit designs should be readable at small mobile sizes.
- Card art should be expressive but not visually noisy.

Production needs:
- Logo
- Card frame system
- 7 character type icons
- Culture icons
- Board tiles
- Unit portraits
- Unit tokens or models
- Ability icons
- UI kit
- Animation style guide

## 18. Audio Direction

Initial needs:
- Tap and confirm sounds
- Relic/event draw sounds
- Unit movement sounds
- Attack and ability sounds
- Victory/defeat stingers
- Culture-specific music themes later

## 19. Technical Direction

Chosen framework:

| Engine | Fit |
| --- | --- |
| Godot | Lightweight, open source, strong for 2D, well-suited to a grid-based mobile tactics prototype |

Recommendation:
Use Godot for the prototype and early MVP. The game is 2D-first, grid-based, and rules-heavy, which fits Godot's strengths and keeps iteration lean.

Core technical systems:
- Board/grid engine
- Turn manager
- Rules engine
- Card database
- Squad setup and board placement
- Shared relic/event deck
- Character level-up system
- AI opponent
- Animation controller
- Save/profile data
- Match replay/log system
- Networking later
- Content pipeline for adding cards and cultures

## 20. Prototype Scope

The first playable prototype should prove the core game is fun before adding collection, monetization, or many cultures.

### Prototype Content

- 7x7 board with one center tile
- 2 playable cultures: Russian-inspired and Atlantean
- 7 character types
- 1 version of each type per culture
- 14 total character cards
- 10-20 shared relic/event cards
- First-pass story framing around the Closed City accident and convergence dream
- Design notes for the six faction sub-areas, while only a representative 14-card roster is implemented for the first prototype
- Local match against another human on same device or a very simple AI
- Hero capture and army defeat victory conditions
- Basic UI
- Placeholder art

### Prototype Success Criteria

- Players understand legal moves within 2 minutes.
- Each turn presents at least one meaningful choice.
- Matches finish within 20 minutes.
- Different character types feel distinct.
- The two test cultures create different playstyles.
- Players want to immediately replay and try a different strategy.

### Product-Level Requirements

| ID | Requirement | Source Goal |
| --- | --- | --- |
| PRD-FR-001 | The prototype shall support a 7x7 tactical board with a visible center tile and two opposing player sides. | PRD-GOAL-001 |
| PRD-FR-002 | The prototype shall support two playable cultures, Russian-inspired and Atlantean, each with one character for each of the seven base character types. | PRD-GOAL-002 |
| PRD-FR-003 | The prototype shall support turn-based movement, attacks, character abilities, mount/dismount actions, and pass/end-turn flow. | PRD-GOAL-001 |
| PRD-FR-004 | The prototype shall support Hero capture and army defeat victory conditions. | PRD-GOAL-001 |
| PRD-FR-005 | The prototype shall support a shared relic/event deck with one draw for the active player each turn. | PRD-GOAL-004 |
| PRD-FR-006 | The prototype shall support in-match character progression from Level 1 to Level 2 by reaching the opponent's edge. | PRD-GOAL-001 |
| PRD-FR-007 | The prototype shall support Level 3 progression by having a Level 2 character collect a Spirit Ember and deliver it to the center square. | PRD-GOAL-001 |
| PRD-FR-008 | The prototype shall expose enough debug or inspection UI for playtesters to understand HP, AP, level, status effects, relics, events, and legal actions. | PRD-GOAL-001 |
| PRD-FR-009 | The content system shall be structured so future factions can support three sub-areas with seven character types plus relics and events. | PRD-GOAL-005 |
| PRD-FR-010 | The MVP shall include tutorial, AI match, casual PvP, squad or cosmetic view, collection view, analytics events, local save data, and internal balancing tools. | PRD-GOAL-006 |
| PRD-NFR-001 | The first paper prototype should complete in 10-20 minutes and the eventual mobile standard match should target 5-12 minutes. | PRD-GOAL-003 |
| PRD-NFR-002 | The mobile UX shall keep board state, legal actions, status reminders, active relics/events, and irreversible-action confirmations readable on phone-sized screens. | PRD-GOAL-001 |
| PRD-NFR-003 | Competitive progression shall avoid pay-to-win power advantages and keep gameplay access fair. | PRD-GOAL-001 |
| PRD-NFR-004 | Real-world-inspired cultures shall be handled with respect, research, and fantasy framing that avoids stereotypes. | PRD-GOAL-005 |

### Success Metrics

| ID | Metric | Target | Validation Method |
| --- | --- | --- | --- |
| PRD-SM-001 | Rule comprehension | New playtesters understand legal movement, basic attacks, turn flow, and Hero capture — enough to start having fun — within 2 minutes. Mastering the nuances of individual character/relic/event cards is expected to take longer and is not part of this metric. | Observe first-session paper or digital playtests. |
| PRD-SM-002 | Prototype match length | Paper prototype matches finish within 10-20 minutes. | Time 3-5 comparable-skill test matches. |
| PRD-SM-003 | Mobile match target | Standard mobile matches trend toward 5-12 minutes after UX and balance tuning. | Measure digital prototype and MVP session analytics. |
| PRD-SM-004 | Decision density | Each turn presents at least one meaningful tactical choice. | Playtest survey plus designer review of turn logs. |
| PRD-SM-005 | Faction distinction | Playtesters can describe how Russian-inspired and Atlantean playstyles differ after one match. | Post-match interview or survey. |
| PRD-SM-006 | Replay pull | At least half of early playtesters want to replay, switch faction, or try a different strategy after a match. | Post-match survey. |
| PRD-SM-007 | Mobile readability | Testers can inspect unit state, legal actions, relic/event state, and victory threats without repeated menu hunting. | Mobile UX prototype observation. |

## 21. MVP Scope

The MVP is the first version that could be tested with external users.

### MVP Features

- Tutorial
- AI opponent
- Squad viewer and cosmetic loadout
- Collection screen
- 4 cultures
- 7 character types per culture
- 28+ character cards
- 40+ shared relic/event cards
- Content architecture that can later support three sub-areas per faction, each with seven character types plus relics and events
- Cosmetic and mastery progression
- Mobile-ready UI
- Analytics events
- Local save data
- Internal balancing tools

### MVP Exclusions

- Real-money monetization
- Ranked ladder
- Large campaign
- Full live ops system
- Complex multiplayer infrastructure
- Large-scale card collection

## 22. Monetization Considerations

Potential options:
- Premium paid game
- Cosmetic purchases
- Battle pass with cosmetics and progression rewards
- Expansion packs
- Optional single-player campaigns

Avoid for early planning:
- Power-selling card packs
- Randomized paid progression that affects competitive fairness
- Aggressive timers or energy systems

Recommended early direction:
Design as fair-to-play first. Decide monetization after the core game is fun.

## 23. Risks

| ID | Risk | Mitigation |
| --- | --- | --- |
| PRD-RISK-001 | Rules become too complex. | Prototype with minimal mechanics first. |
| PRD-RISK-002 | Card balance becomes unmanageable. | Build internal card data tools early. |
| PRD-RISK-003 | Board plus cards overwhelms mobile UI. | Test on phone-sized screens from the start. |
| PRD-RISK-004 | Cultures feel cosmetic only. | Give each culture a mechanical identity. |
| PRD-RISK-005 | Sub-areas feel cosmetic only. | Give each sub-area its own style, mechanics, relics, events, and narrative function. |
| PRD-RISK-006 | Level 3 trophy objective feels too dark or confusing. | Resolved: renamed to `Spirit Ember`, framed as a fragment of spirit/myth released by defeat rather than a body part. Still worth confirming in playtests that the framing reads as intended. |
| PRD-RISK-007 | Multiplayer is expensive and slow. | Start with local and AI matches. |
| PRD-RISK-008 | Scope grows too quickly. | Lock prototype scope before production. |
| PRD-RISK-009 | MVP scope (4 cultures, 28+ character cards, 40+ relic/event cards, AI opponent, full mobile UI) exceeds solo-developer capacity/timeline. | Agreed as an active risk to mitigate. Mitigation approach not yet defined — needs a sequencing/scope-cut plan (e.g. fewer cultures at MVP, smaller relic/event pool, contractor/outsourced art) before committing to Milestone 005 (MVP Planning). |
| PRD-RISK-010 | Soviet/Cold War nuclear-accident setting draws extra app-store or platform content-review scrutiny given real-world political sensitivity. | Partially mitigated by the fiction/abstraction direction (real-world grounding as hints, not literal named figures or documented incidents). Platform policy review still recommended before major production investment. |
| PRD-RISK-011 | Level 2/3 upgrades are currently too incremental (mostly +1 stat tweaks), so playtesters rarely find leveling worth the risk. | New design directive (Section 9): Level 2 = clear power spike, Level 3 = transformative. Character tables in Section 8 need a revision pass to meet this bar — not yet done. |

## 24. Open Questions

| ID | Question | Decision Impact |
| --- | --- | --- |
| PRD-OQ-001 | Is the game portrait, landscape, or both? | Determines board layout, card inspection, and mobile UI constraints. |
| PRD-OQ-002 | What exact 7x7 starting formation should the 14 characters use? | Blocks stable paper prototype setup and first digital board presets. |
| PRD-OQ-003 | Are units permanently defeated, revived, or returned to hand? | Affects victory pacing, comeback mechanics, and event/relic design. |
| PRD-OQ-004 | Should cultures be historically named, myth-inspired, or fully fictional? | Affects naming, research burden, audience expectations, and sensitivity review. |
| PRD-OQ-005 | Is the tone serious, stylized, heroic, dark, or family-friendly? | Affects art direction, Spirit Ember framing, story presentation, and content rating. |
| PRD-OQ-006 | How many shared relic/event cards should be in the first paper prototype? | Determines prototype content workload and event frequency. |
| PRD-OQ-007 | What exact story role does the Closed City scientist play: protagonist, narrator, gate, victim, antagonist, or all of these at different times? | Determines campaign framing, tutorial voice, and long-term narrative structure. |
| PRD-OQ-008 | Resolved: represented as a status/counter on the carrying character (icon such as a wisp, spark, or fractured-glass mark), not a separate physical board object. | Simplifies UI; avoids adding another placed-object type alongside barricades/pylons/frost tiles. |
| PRD-OQ-009 | Resolved: no darker body-part language (scalp/ear) in any version of the product, including prototype notes. `Spirit Ember` is the only name used. | Removes the sensitivity risk in PRD-RISK-006 outright rather than deferring it to a later tone decision. |
| PRD-OQ-010 | What is the per-turn or per-match timer length for the future Timer-based/Blitz PvP mode? | Determines competitive pacing and whether timing is turn-based or match-based. |
| PRD-OQ-011 | Does the new line-of-sight blocking rule apply to non-damage support/utility abilities (Command, Resonance Shield, Foresight, Pylon range boost) that target at range, or only to attacks and damage-dealing abilities? | Affects several existing character abilities' rules text and the digital rules engine's targeting logic. |

## 25. First Development Milestones

### PRD-MILESTONE-001: Paper Prototype

Goal:
Validate basic rules with physical cards or a spreadsheet.

Deliverables:
- Board sketch
- 14 character cards
- 10 shared relic/event cards
- 1-page rules sheet
- Draft story premise for the Closed City accident and convergence
- Sub-area design notes for Russian-inspired and Atlantean factions
- Playtest notes

### PRD-MILESTONE-002: Digital Rules Prototype

Goal:
Build the game logic without final art.

Deliverables:
- Grid board
- Turn system
- Movement
- Attacks
- Character abilities
- Shared relic/event draw
- Character level-up trigger
- Spirit Ember tracking for Level 3 progression
- Win/loss condition
- Debug UI

### PRD-MILESTONE-003: Mobile UX Prototype

Goal:
Test whether the game works on a phone.

Deliverables:
- Touch controls
- Relic/event display UI
- Board camera/layout
- Unit inspection
- Legal move highlights
- Basic animations

### PRD-MILESTONE-004: Content Prototype

Goal:
Test culture identity and replayability.

Deliverables:
- 2 cultures
- 14 units
- 20+ shared relic/event cards
- Simple balancing pass
- Playtest survey

### PRD-MILESTONE-005: MVP Planning

Goal:
Decide whether the game is strong enough to scale.

Deliverables:
- Updated PRD
- Technical design document
- Art bible
- Production backlog
- MVP estimate

## 26. Immediate Next Steps

1. Choose the exact 7x7 starting formation.
2. Draft the first version of the Closed City accident story and the scientist's role in the convergence.
3. Write short style and mechanic notes for each of the six sub-areas.
4. Write 10-20 starter shared relic/event cards.
5. Paper test the 14 character cards and record which pieces feel too strong, too weak, or too confusing.
6. Revise stats, Level 2 upgrades, and Level 3 Spirit Ember rules after 3-5 paper matches, applying the new directive that Level 2 upgrades should be a clear power spike and Level 3 upgrades should be transformative (see Section 9).
7. During paper testing, specifically track: how often Level 2/3 is actually reached (leveling-worth-it check), whether the 2-AP first turn meaningfully reduces first-move advantage, and how many turns pass before players stop feeling overwhelmed by per-card rules.
8. Build the first Godot rules prototype.
