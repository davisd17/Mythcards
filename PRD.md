# MythCards Product Requirements Document

## 1. Vision

MythCards is a mobile-first, turn-based tactical card game played on a chess-like board. Players command a small roster of characters represented by cards, using positioning, faction identity, and tactical abilities to outplay an opponent over short strategic matches.

The game should feel like a blend of chess, collectible card games, mythic civilization strategy, occult secret history, and dreamlike alternate realities: easy to understand at the surface, but deep enough that every move, card choice, and board position matters.

The core story begins in a Soviet closed city in the 1980s. After a strange nuclear accident, a scientist passes out and his unconscious mind becomes a convergence point where realities, myths, histories, and occult forces play out as tactical battles. The battles may be dreams, transmissions, ancestral memories, or real worlds pressing through one damaged human mind.

## 2. Product Goals

- Create a polished mobile tactical game with clear rules, readable turns, and satisfying strategic depth.
- Build a card and character system that supports 7 character types, with multiple cultural or civilization-based versions of each type.
- Make matches short enough for mobile play while still rewarding mastery.
- Establish a flexible rules foundation that can support future cards, cultures, modes, events, and expansions.
- Establish a story and content framework where each faction contains multiple hidden sub-areas, each with its own style, mechanics, relics, events, and narrative identity.
- Design the game so it can eventually support both solo play and PvP.

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
- Diagonal, area, jump, teleport, or unusual patterns are special-case rules printed on characters, relics, events, or future cards.
- Movement, basic attacks, and abilities each cost that character's 1 action point.
- Level 2 and Level 3 upgrades should make pieces more interesting without making a leveled character automatically win the game.
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
- Level 3 is earned after a Level 2 character collects a defeat trophy, such as a scalp or ear, from a defeated enemy and carries it to the center square.
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

### Defeat Trophy Leveling

The current level-up rule has two stages:

| Level | Requirement | Design Purpose |
| --- | --- | --- |
| Level 2 | A Level 1 character crosses to the opponent's board edge. | Rewards penetration, risk, and reaching enemy territory. |
| Level 3 | A Level 2 character collects a defeat trophy from a defeated enemy, then reaches the center square. | Forces a second tactical objective and pulls upgraded pieces back toward the contested middle. |

Prototype terminology:
- The story flavor may call the trophy a scalp, ear, token, or defeat trophy.
- The product and UI should use a flexible term such as `defeat trophy` unless the final tone intentionally supports darker language.
- The center square becomes important for Level 3 progression in addition to positioning and relic/event effects.

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
- The center tile must support Level 3 advancement when a Level 2 character carrying a defeat trophy reaches it.
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
2. Each character refreshes to 1 action point.
3. The active player draws 1 shared relic or event card for the turn.
4. Player takes actions in any order:
   - Move a character by spending that character's action point.
   - Attack with a character by spending that character's action point.
   - Activate an ability by spending that character's action point.
   - Pick up, carry, or deliver a defeat trophy if the final prototype implementation treats trophies as explicit board objects or status markers.
   - Resolve any active relic or event effects.
5. Player ends turn.
6. End of turn effects resolve.

Recommendation:
Start with each character receiving 1 action point per turn. This creates chess-like clarity: each piece can usually do one meaningful thing before the turn passes.

## 12. Resources

Possible resource systems:

| System | Pros | Cons |
| --- | --- | --- |
| Mana-style resource | Familiar to card players | Can feel detached from board tactics |
| Action points | Strong tactical clarity | May limit card variety |
| Culture-specific resources | Strong identity | Harder to balance |
| Hybrid action + mana | Flexible | More complex for new players |

Prototype recommendation:
- Each character refreshes to 1 action point at the start of its controller's turn.
- Movement is an action and consumes that character's action point.
- Attacking is an action and consumes that character's action point.
- Using an ability is an action and consumes that character's action point.
- Some cards may allow bonus movement, reaction actions, or action point recovery.
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
- Characters reach Level 3 by collecting a defeat trophy from a defeated enemy and taking it to the center square.
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
- Asynchronous PvP
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

| Risk | Mitigation |
| --- | --- |
| Rules become too complex | Prototype with minimal mechanics first |
| Card balance becomes unmanageable | Build internal card data tools early |
| Board plus cards overwhelms mobile UI | Test on phone-sized screens from the start |
| Cultures feel cosmetic only | Give each culture a mechanical identity |
| Sub-areas feel cosmetic only | Give each sub-area its own style, mechanics, relics, events, and narrative function |
| Level 3 trophy objective feels too dark or confusing | Test terminology and UI; use `defeat trophy` as the neutral rules term until tone is final |
| Multiplayer is expensive and slow | Start with local and AI matches |
| Scope grows too quickly | Lock prototype scope before production |

## 24. Open Questions

- Is the game portrait, landscape, or both?
- What exact 7x7 starting formation should the 14 characters use?
- Are units permanently defeated, revived, or returned to hand?
- Should cultures be historically named, myth-inspired, or fully fictional?
- Is the tone serious, stylized, heroic, dark, or family-friendly?
- How many shared relic/event cards should be in the first paper prototype?
- What exact story role does the Closed City scientist play: protagonist, narrator, gate, victim, antagonist, or all of these at different times?
- Should the Level 3 trophy be represented as a physical board marker, a character status, or an abstract achievement?
- How explicit should darker trophy language such as scalp or ear be in the final product versus prototype notes?

## 25. First Development Milestones

### Milestone 1: Paper Prototype

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

### Milestone 2: Digital Rules Prototype

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
- Defeat trophy tracking for Level 3 progression
- Win/loss condition
- Debug UI

### Milestone 3: Mobile UX Prototype

Goal:
Test whether the game works on a phone.

Deliverables:
- Touch controls
- Relic/event display UI
- Board camera/layout
- Unit inspection
- Legal move highlights
- Basic animations

### Milestone 4: Content Prototype

Goal:
Test culture identity and replayability.

Deliverables:
- 2 cultures
- 14 units
- 20+ shared relic/event cards
- Simple balancing pass
- Playtest survey

### Milestone 5: MVP Planning

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
6. Revise stats, Level 2 upgrades, and Level 3 trophy rules after 3-5 paper matches.
7. Build the first Godot rules prototype.
