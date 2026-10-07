# MythCards Low-Level Design — Closed City vs Flood Survivors Roster

**Document Control**

| Field | Value |
| --- | --- |
| Source | `data/cards/review_drafts/closed_city_characters.json`, `flood_survivor_characters.json` (card text), `digital_tabletop.html` (the 14 chosen), designer answers 2026-10-07 |
| Scope | The 14 characters for the next playtest: a full Closed City team vs a full Flood Survivors team. Teams, per-card rules, and the engine additions they need. |
| Builds on | LLD-ability-system.md (handler framework), LLD-relic-event-deck.md 9B (Leak, Memory, Stone), LLD-combat-mount.md, LLD-presentation.md |
| Date | 2026-10-07 |
| Status | Implemented and tested (`test_closed_city_roster.gd`, `test_flood_survivors_roster.gd`, `test_teams.gd`); defaults marked `[NEED: confirm]` await designer review |

## 1. Decisions (designer, 2026-10-07)

- **Playtest matchup:** Closed City (Player 1) vs Flood Survivors (Player 2). The game offers only this matchup.
- **The original 14 are hidden, not retired.** Their data, handlers, and tests stay intact and remain the fixture for the engine tests; they will come back as selectable teams later.
- **Once-per-match Level 3 abilities cost 1 AP** (pool + character), like every activated ability.
- **Dream Link can move Memory** as well as combat markers.
- **Reactor Worker never triggers Leaks**, and its Level 3 AP gain has no per-turn limit (the 4-AP pool still caps it).

## 2. Teams

`data/cards/teams.json` (new) names each team's 7 card ids and the matchup the game plays:

| Team id | Name | Culture | Characters |
| --- | --- | --- | --- |
| `closed-city` | Closed City | Russian-inspired | Reactor Worker, VERA-7, Major Yuri Volkov, Dr. Mikhail Orlov (Hero), Irina Vasilievna Karpova (Leader), Dr. Elena Morozova, Zoya Miranova |
| `flood-survivors` | Flood Survivors | Atlantean | Stone-Line Laborer, Ahesu, Naia, Sahu-Ren (Hero), Queen Meret-Anu (Leader), Iset-Nara, Thalassa-Nekh |
| `original-russian` / `original-atlantean` | Original prototype | — | the original 14 (hidden: `"offered": false`) |

- Card text stays in the review-draft files, so there is one source per card. A card listed in a team is playable even though its file says `draft_for_review`; alternates in those files (Hospital Orderly, Colonel Semyonov, Anya Lebedeva) stay drafts.
- `ContentDB.get_team(id)` / `get_team_characters(id)` / `get_matchup()`. `SetupFlow.select_team(player, team_id)` builds the squad (`select_culture` remains for the original 14). `PlayerState.team_id` and the team name are shown on the screen.
- The relic/event deck is unchanged: each player contributes their culture's set (Closed City relics/events for Russian-inspired, Flood Survivors for Atlantean).
- Board figures (`game/assets/figures/`) and card art (`card_art.json`) are keyed by the new ids. Reactor Worker has no card art yet, so it shows a text card. `[NEED: confirm art picks]` For Closed City characters with several versions, the tarot-titled version was used: Elena, The High Priestess; Orlov, The Magician; Karpova, The Empress; Yuri, Strength; Zoya, The Moon (corrected); VERA-7, Queen of Pentacles.

## 3. Engine additions

| Addition | Where | Used by |
| --- | --- | --- |
| **Off-board characters**: `AbilitySystem.remove_from_board(c, return_rule)`. The character leaves the board (untargetable; not counted for Hero capture), and at its owner's next turn start must return via the `return` bonus before any other action (`"return your character to the board first"`). A rider leaving the board leaves its Mount on the tile. | AbilitySystem, RulesEngine | Orlov L3, Elena L3 |
| **Memory counts**: `give_memory(target, max = 1)` stacks up to `max` (Sahu-Ren: 3). Memory still spends 1 per damage instance, after shields. | AbilitySystem, CombatResolver | Sahu-Ren, Meret-Anu, Thalassa-Nekh, Dream Link |
| **Damage hooks**: `on_character_damaged(sys, instance, damaged, attacker, incoming, final)` after every damage instance (including fully prevented ones), and `on_memory_spent(sys, instance, holder, attacker)`. | AbilityHandler, CombatResolver | Naia L1, Sahu-Ren L1, Thalassa-Nekh L2 |
| **Lethal intercept with Memory context**: `intercept_lethal_damage(defender, combat, had_memory)`. After the defender's own intercept, a `tide_sealed` player flag (cleared at that player's next turn start) saves a teammate that had Memory when hit. `CombatResolver.current_attacker` tells intercepts who hit. | AbilitySystem, CombatResolver | Meret-Anu L3, Naia L3 |
| **Leak immunity**: `ignores_leaks(sys, instance)` hook, plus the `ignore_leak_move` status (spent by the holder's next move). An immune character doesn't trigger the Leak, which stays. | AbilityHandler, AbilitySystem | Reactor Worker, Karpova L2 |
| **Rider HP from the Mount**: `get_rider_max_hp_bonus(sys, mount, rider)` folds into conditional max HP; resynced on mount/dismount. | AbilityHandler, AbilitySystem | VERA-7 L1 |
| **Dynamic free bonuses**: `offered_bonuses(sys, instance)` adds offers that depend on live state (no stored flag). | AbilityHandler, RulesEngine | Sahu-Ren L2, VERA-7 L3 |
| **`vault` placed object**: 3 HP, blocks movement and line of sight, owned by its builder. Its start-of-turn Shields belong to the board (`AbilitySystem._vault_shields`), so they continue after Iset-Nara falls. | PlacedObjectRegistry, AbilitySystem | Iset-Nara L3 |
| **Separate character-pass cap**: `get_movement_max_char_passes` and `BoardModel.get_legal_moves(..., max_char_passes)`. | AbilityHandler, BoardModel | Ahesu L2 |
| **Board tags**: `teams.json` `abbreviations` (the tabletop's RW, V7, YV, MO, IK, EM, ZM, SL, AH, NA, SR, MA, IN, TN). Initials would have collided (Stone-Line Laborer and Sahu-Ren both "SL"). | ContentDB, DebugPanel | board and debug view |

## 4. Per-card rules

Conventions from the existing engine apply: "within N" uses the ability's reach (`ability_reach`, so RANGE bonuses and Link-style effects extend it) along orthogonal lines with line of sight; "adjacent" is orthogonal; "ally" excludes the character itself unless noted; Marked gives the next allied attack or damaging ability +1, then is removed; "Shield" is a 1-damage shield until the start of its holder's next turn.

### Closed City

| Card | Stats (HP/ATK/MOVE/RANGE) | Implementation |
| --- | --- | --- |
| **Reactor Worker** (Common) | 3/1/2/1 | L1: never triggers Leaks (no damage, Leak stays), so it can stand on one. L2: +1 MOVE. L3: each time it ends a move on a Leak, +1 character AP (no per-turn limit). |
| **VERA-7** (Mount) | 4/1/3/1 | L1: its rider has +1 max HP (and +1 current on mounting; trimmed on dismount). L2: +1 MOVE; may pass through 1 placed object or allied character per move. L3: free bonus once per turn: an adjacent ally moves to another empty tile adjacent to VERA-7. On this grid, any two tiles next to VERA-7 are diagonal to each other, so the printed "1 tile" step can never qualify. Not usable while carrying a rider (PRD: a ridden Mount takes no separate actions). `[NEED: confirm both readings]` |
| **Major Yuri Volkov** (Warrior) | 4/2/2/2 | L1 Containment Shot (AP): 1 damage to an enemy within 3; if the target is adjacent to a Leak, it becomes Marked. L2: +1 HP. L3: +1 ATK; Containment Shot may also target along diagonals (within 3, diagonal line of sight). |
| **Dr. Mikhail Orlov** (Hero) | 5/1/2/3 | L1 Reactor Leak (AP): a Leak on an empty tile within 2. L2: +1 RANGE; 2 Leaks on different tiles. L3 Slumber: +1 HP; once per match (AP), leaves the board until your next turn, then returns to an empty tile within 2 of where he left and places 1 Leak on an adjacent empty tile (skippable if none). If no tile within 2 is empty, any empty tile. `[NEED: confirm fallback]` |
| **Irina Karpova** (Leader) | 4/1/2/3 | L1 Access Granted (AP): an ally within 3 gets +1 ATK for the rest of this turn (every attack). L2: 2 allies; each also ignores Leaks on its next move this turn. L3 The Door Was Always There: +1 HP; once per match (AP), up to 2 allies within 3 each get a free 1-tile move. |
| **Dr. Elena Morozova** (Specialist) | 3/1/2/3 | L1 Dream Link (AP): an ally within 3, then another ally within 2 of it; move one marker either way between them. Markers: Shield, Memory, Marked, +ATK, MOVE changes (incl. Slow), +RANGE, Pounce. Never Spirit Ember; a receiver already at its Memory max can't take Memory. L2: range 4, any two characters within 4 of Elena; moving a harmful marker (Marked, a negative MOVE/ATK change) onto an enemy gives Elena a Shield. L3 Missing In The Signal: +1 RANGE; once per match (AP), leaves the board until your next turn, returns to an empty tile adjacent to an ally, then may move one marker between two characters within 4 of her. |
| **Zoya Miranova** (Mystic) | 3/1/2/3 | L1 Voice Under Static (AP): an enemy within 3 is pulled 1 tile toward Zoya if that tile can be entered: no character or movement-blocking object. A Leak there doesn't stop the pull and is triggered, so Zoya can pull enemies into Orlov's Leaks. "Can't be moved" effects stop it. `[NEED: confirm]` The card says "if the destination is empty", and elsewhere a Leak tile isn't empty. L2: +1 RANGE; the moved enemy becomes Marked. L3: +1 HP; once per match, after Voice Under Static moves an enemy, a free second use (`too_many_names` bonus). |

### Flood Survivors

| Card | Stats | Implementation |
| --- | --- | --- |
| **Stone-Line Laborer** (Common) | 2/1/2/1 | L1 Stone Line (AP): a Stone (own, 1 HP, blocks movement) on an adjacent empty tile. L2: +1 HP; up to 2 Stones. L3: +1 MOVE; may move through Stones; once per turn, after a move that passed a Stone, gains Shield. |
| **Ahesu** (Mount) | 4/1/4/1 | L1: may move through allied Stones (the mounted pair too). L2: +1 MOVE; when it starts a move adjacent to any Stone, it may also pass 1 allied character. L3: +2 ATK, +1 HP. |
| **Naia** (Warrior) | 4/2/3/1 | L1 Tomb Sentinel: while adjacent to a placed object (any, including Leaks), the first damage she takes each turn (each player's turn counts) is reduced by 1. L2: +1 HP; while adjacent to a placed object, her basic attacks Mark enemies they damage. L3: +1 ATK; once per match, when she'd be defeated she stays at 1 HP; if then adjacent to a placed object, an adjacent enemy becomes Marked: the attacker if adjacent, otherwise the adjacent enemy with the lowest HP (chosen automatically, since it can happen on the opponent's turn). `[NEED: confirm auto-choice]` |
| **Sahu-Ren** (Hero) | 5/1/2/3 | L1 Living Archive: the first time each turn an ally within 2 takes damage, he gains 1 Memory (max 3). His Memory also blocks damage to him as normal. L2: +1 RANGE; once per turn, free: spend 1 Memory to Mark an enemy within 3. L3 Last Memory Released: +1 HP; once per match (AP), spend up to 3 Memory, 1 damage to a Marked enemy within 3 for each (targets chosen up front; the same enemy may be picked more than once). |
| **Queen Meret-Anu** (Leader) | 4/1/2/3 | L1 Memory Discipline (AP): any ally anywhere gains Memory (max 1); if she has none, she gains 1 too. L2: 2 allies. L3 Tide-Sealed Archive: +1 HP; once per match (AP), until the start of your next turn, a character on her team (her included) that had Memory when hit and would be defeated instead loses its Memory and stays at 1 HP. |
| **Iset-Nara** (Specialist) | 3/1/2/2 | L1 Hidden Geometry (AP): an adjacent placed object (any owner, including Leaks) moves up to 2 tiles in a straight line to an empty tile (stops at characters and objects). L2: +1 RANGE; the object may be within 2. L3 The Hidden Vault Opens: +1 HP; once per match (AP), a Hidden Vault (3 HP, blocks movement and line of sight) on an empty tile adjacent to a Stone; at the start of your turn, allies adjacent to it gain Shield. |
| **Thalassa-Nekh** (Mystic) | 4/1/2/2 | L1 Black-Water Communion (AP): an ally within 3 gains Memory (max 1). L2: +1 RANGE; when an ally within her RANGE (distance, no line of sight needed) spends Memory to prevent damage from an enemy character, that enemy becomes Marked. L3 The Drowned Seraph Takes Form: +1 HP; once per match (AP), Seraph Form for the rest of the match: +2 ATK, +1 RANGE. |

## 5. Screen changes

- Setup and turn labels name the team ("Player 1 (Closed City)").
- An off-board character's return is a required prompt at its owner's turn start, like a drawn-card choice.
- Free bonuses that depend on state (Forbidden Testimony, Passenger Signal) appear as buttons when available.
- The debug match uses the same matchup.

## 6. Test plan

`test_closed_city_roster.gd` and `test_flood_survivors_roster.gd` cover every card's levels through `RulesEngine` (a team fixture, `Fixture.start_teams_match()`). The engine additions in Section 3 are each covered there. `test_teams.gd` covers loading, squad building, and that the original 14 are hidden but still playable. The browser click test plays the new matchup.

## 7. Open items

- `[NEED: confirm]` The defaults marked above: VERA-7 L3 (destination and while ridden), Zoya pulling onto a Leak, Orlov's return fallback, Naia L3's automatic choice, and the art picks.
- Leak tiles and "empty": a Leak tile is not empty for placing things (objects, Leaks, the Vault, teleport and return tiles), but it can be entered by moving, pushing, and pulling, which triggers it (except for the Reactor Worker and characters with Access Granted L2).
- Once-per-match free follow-ups (Zoya's Too Many Names) are offered for the rest of that turn only; if unused, they're lost.
- The engine tests' greedy bot (e2e `full-match.spec.ts`) now also attacks enemy objects. Flood Survivors Stones walled a Closed City Warrior off from every target, which stalled the bots, and only those bots, at seed 7.
- Reactor Worker card art doesn't exist yet; the Thalassa-Nekh `drowned-seraph` figure and Zoya `aurora-rite` figure exist but aren't in `wardrobe.json`.
