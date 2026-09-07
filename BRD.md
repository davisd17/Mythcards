# MythCards Business Requirements Document

## Document Control

| Field | Value |
| --- | --- |
| Source document | PRD.md (current version, including the 2026-08-14 rule decisions: player-chosen back-row deployment, line-of-sight scope resolved for non-damage abilities, explicit mount/dismount AP cost, chess-checkmate-style Hero capture, and the 3-relic/4-event-per-player shared deck) |
| Version | 3 (resync with the 2026-08-14 GitHub pull — Closed City narrative content, `data/cards/characters.json` / `relic_events.json` — plus new business-rule decisions from this session; supersedes the v1 BRD and the interrupted v2 draft) |
| Date | 2026-08-14 |
| Status | Draft |
| Prepared by | Drew Davis (solo developer/designer, acting as own PM) |

## 1. Document Purpose

This Business Requirements Document enumerates the business goals, scope, stakeholders, business rules, functional requirements, non-functional requirements, data requirements, risks, dependencies, and acceptance criteria for MythCards.

This BRD is derived entirely from the current MythCards PRD (`PRD.md`) and the current prototype card data (`data/cards/characters.json`, `data/cards/relic_events.json`) and adds nothing those sources do not already support. Its job is completeness and traceability: every rule and requirement implied by the PRD gets a stable ID here, so nothing is silently dropped when work moves from paper prototype to the Godot rules prototype and beyond. See Section 17 (Traceability) for how each section maps back to its PRD source.

## 2. Product Summary

MythCards is a mobile-first, turn-based tactical card-and-board game played on a 7x7 chess-like grid with one center tile. Players command a fixed squad of character cards — exactly one of each of the 7 base character types (Leader, Hero, Mount, Specialist, Warrior, Common, Mystic) — using positioning, culture identity, and tactical abilities to outplay an opponent. Players win by capturing the enemy Hero (a positional, checkmate-style condition — see BR-034) or by defeating the entire opposing army.

The story premise centers on a 1980s Soviet closed-city nuclear accident: a scientist's unconscious mind becomes a convergence point where realities, myths, and occult forces play out as tactical battles. The setting leans into fiction and abstraction — real-world eras, professions, imagery, geography, and technology appear as recognizable hints, not as literal named historical figures or documented incidents.

The first prototype implements two cultures:
- **Russian-inspired** — endurance, frost control, disciplined tactics, fortification, ranged pressure.
- **Atlantean** — divine spirit leadership, quartz technology, hive-mind coordination, spiritual shields, resonance, board manipulation.

Each culture is designed around three future story sub-areas (21 character cards per culture long-term), though the first prototype implements only a representative 14-card roster (one character per type per culture). A third sub-area's relic/event set (Closed City) is already drafted as narrative-backed content but is explicitly out of prototype scope until it clears review (BR-043A). Mobile-first design constraints apply from this first prototype onward, not only starting at the Mobile UX milestone (BR-044). The chosen technical framework is Godot.

## 3. Business Objectives

| ID | Objective |
| --- | --- |
| BO-001 | Create a polished mobile tactical game with clear rules, readable turns, and satisfying strategic depth. |
| BO-002 | Build a card and character system supporting 7 character types, with multiple culture-specific versions of each type. |
| BO-003 | Keep matches short enough for mobile play while still rewarding mastery. |
| BO-004 | Establish a flexible rules foundation that supports future cards, cultures, modes, and events. |
| BO-005 | Establish a story and content framework where each culture contains multiple hidden sub-areas, each with its own style, mechanics, relics, events, and narrative identity. |
| BO-006 | Design the game to eventually support both solo play and PvP. |

## 4. Success Metrics

| ID | Metric | Target |
| --- | --- | --- |
| SM-001 | Rule comprehension | New playtesters understand legal movement, basic attacks, turn flow, and Hero capture — enough to start having fun — within 2 minutes. Mastering individual card nuances is expected to take longer and is not part of this metric. |
| SM-002 | Prototype match length | Paper prototype matches finish within 10-20 minutes. |
| SM-003 | Mobile match target | Standard mobile matches trend toward 5-12 minutes after UX and balance tuning. |
| SM-004 | Decision density | Each turn presents at least one meaningful tactical choice. |
| SM-005 | Culture distinction | Playtesters can describe how Russian-inspired and Atlantean playstyles differ after one match. |
| SM-006 | Replay pull | At least half of early playtesters want to replay, switch culture, or try a different strategy after a match. |
| SM-007 | Mobile readability | Testers can inspect unit state, legal actions, relic/event state, and victory threats without repeated menu hunting. |
| SM-008 | Balance health | Neither prototype culture should win more than 60 percent of comparable-skill paper tests after initial tuning. |
| SM-009 | Engagement (anti-turtling) | Paper matches do not stall into passive, non-engaging play under the new checkmate-style Hero capture rule (BR-034); playtest notes explicitly flag turtling if observed. |

## 5. Stakeholders

| Stakeholder | Interest |
| --- | --- |
| Game Designer | Defines rules, characters, cultures, balance, and progression. (Currently the same person as Developer and Product Owner.) |
| Developer | Implements the Godot prototype and future mobile systems. |
| Artist/UI Designer | Creates card frames, board visuals, icons, culture identity, and mobile screens. |
| Narrative/Content Designer | Story premise, culture framing, sub-area identity, relics, events, and tone — currently producing the Closed City narrative backlog (`NARRATIVE_CARD_BACKLOG.md`) ahead of prototype implementation. |
| Playtesters | Validate fun, clarity, balance, and pacing. |
| Future Players | Need fair, readable, rewarding tactical gameplay. |
| Business/Product Owner | Decides scope, monetization model, roadmap, and release priorities. |

## 6. Scope

### 6.1 Prototype Scope

- 7x7 board with one visually marked center tile.
- Two playable cultures: Russian-inspired and Atlantean.
- 14 total character cards (one of each of the 7 types per culture), sourced from `data/cards/characters.json` — see Section 12.
- 14 total shared relic/event cards: each player contributes 3 relics and 4 events from their own culture into one shared match deck (BR-027A) — see Section 13.
- No fixed starting formation: each player deploys their own 7 characters onto their own back row, in an arrangement of their own choosing (BR-007A).
- Three character levels per character; Level 2 via reaching the opponent's edge, Level 3 via Spirit Ember collection and center-square delivery.
- Turn-level AP pool: 2 AP on a player's first turn, 4 AP every turn after; each character has its own AP stat (default 1).
- Movement, attack, ability, mount, and dismount actions, each costing 1 pool AP and 1 of the acting character's own AP (BR-020, BR-012).
- Orthogonal movement and orthogonal line-of-sight attack as default patterns; line-of-sight blocking applies to all ranged targeting, including non-damage support/utility abilities (BR-011).
- Hero capture (positional/checkmate-style: the Hero has no legal move at the end of its own controller's turn — BR-034) and army defeat victory conditions.
- Local hotseat play or a simple AI in the first digital prototype.
- Mobile-first design constraints applied from this prototype onward (BR-044).
- Godot as the prototype engine.

### 6.2 MVP Scope

- Tutorial, AI opponent, casual PvP.
- Squad viewer or cosmetic loadout, collection screen.
- Four cultures, seven character types per culture, 28+ character cards.
- 40+ shared relic/event cards. `[NEED: at MVP scale, confirm whether the per-player contribution stays fixed at 3 relics + 4 events drawn from a larger pool, or changes — not yet decided]`
- Content architecture supporting three sub-areas per culture (seven types plus relics/events each) even though only representative content ships at MVP.
- Cosmetic and mastery progression, mobile-ready UI, analytics events, local save data, internal balancing tools.

### 6.3 Out Of Scope For Prototype And MVP

- Real-money monetization.
- Ranked ladder.
- Large campaign.
- Full live operations system.
- Complex multiplayer infrastructure.
- Large-scale card collection system.
- Pay-to-win progression, at any stage.
- The drafted Closed City relic/event set (6 relics + 8 events, `review_status: draft_for_review`) until it clears review and is promoted into the playable deck (BR-043A).

## 7. Assumptions

| ID | Assumption |
| --- | --- |
| AS-001 | The first prototype is validated on paper before Godot development begins. |
| AS-002 | The first software prototype prioritizes game rules over final art, monetization, or networking. |
| AS-003 | Players begin with all character cards placed on the board via their own back-row deployment; character cards carry no deployment cost. |
| AS-004 | Gameplay progression never requires paid unlocks or stronger cards; cosmetic progression is acceptable if it never affects match outcomes. |
| AS-005 | The first digital prototype can use placeholder art. |
| AS-006 | The default board pattern is a 7x7 grid with orthogonal movement and orthogonal line-of-sight attacks — applied to all ranged targeting, including non-damage support/utility abilities — unless a specific character, relic, event, or future card states otherwise. |
| AS-007 | Each character's own AP stat defaults to 1 (one action per turn) unless a card or effect explicitly grants more. |
| AS-008 | Sub-area content depth (21 cards per culture) is a documented future structure; only a representative 14-card roster is required for the first prototype. |
| AS-009 | Hero capture is fully decoupled from HP loss (BR-034/BR-034A): a Hero reduced to 0 HP is defeated like any other character but does not by itself end the match. This is a new-for-2026-08-14 assumption to be validated in paper testing, not a long-settled rule. |
| AS-010 | Mobile-first constraints (readability, tap targets, text density) apply starting with the paper and Godot prototypes, even though those builds run on a desktop screen for development convenience. |

## 8. Business Rules

### 8.1 Roster Composition

| ID | Rule |
| --- | --- |
| BR-001 | Each side may field only one Hero. |
| BR-002 | Each side may field only one Leader. |
| BR-003 | Each side may field up to two copies of each non-common, non-unique type: Mount, Warrior, Specialist, Mystic (future squad-building modes beyond the fixed prototype squad). |
| BR-004 | Common characters may be used in larger numbers if a future squad size requires filler units. |
| BR-005 | Each side must field exactly one copy of each of its seven character type cards for the prototype — no duplicates, no omissions — on a 7x7 board. This is a firm rule for the prototype, not a recommendation. |

### 8.2 Setup And Placement

| ID | Rule |
| --- | --- |
| BR-006 | Character cards have no deployment cost. |
| BR-007 | All character cards are placed on the board at the start of the match. |
| BR-007A | Each player deploys their own 7 characters onto their own back row — the row of 7 tiles closest to their side. There is no fixed starting formation; each player chooses the arrangement of their own units within that row. This resolves PRD-OQ-002. |
| BR-007B | Players place their own characters themselves, rather than a designer-fixed or randomized layout (see FR-007C for the corresponding system requirement and its priority). |

### 8.3 Movement And Attack Patterns

| ID | Rule |
| --- | --- |
| BR-008 | Default movement pattern is orthogonal: vertical and horizontal only. |
| BR-009 | Default attack pattern is orthogonal line-of-sight: vertical and horizontal only. |
| BR-010 | Diagonal, area, jump, teleport, or other unusual movement/attack patterns require explicit rules text on the specific card or ability. |
| BR-011 | Ranged attacks, and any ability that targets at range — including non-damage support/utility abilities such as Command, Resonance Shield, Foresight, and Pylon range boosts — cannot pass line-of-sight through an occupied tile (ally or enemy) unless the specific card or ability explicitly states an exception. This resolves PRD-OQ-011: the blocking rule applies uniformly, not only to damage-dealing effects. |
| BR-011A | A tile holding a placed object (e.g., a barricade, a quartz pylon) also blocks line-of-sight by default, the same as an occupied character tile, unless the specific card or object explicitly states otherwise (decided 2026-09-07). No current card grants its own placed object a line-of-sight exception. |

### 8.4 Mounted Pair Rules

| ID | Rule |
| --- | --- |
| BR-012 | A Hero or Leader may mount an allied Mount as an action if adjacent to that Mount, spending 1 pool AP and 1 of that character's own AP — the same cost as any other action, and gated by both being available. |
| BR-013 | Mounting moves the Hero or Leader onto the Mount's tile; the pair occupies one combined tile. |
| BR-014 | A mounted pair uses the rider's HP, ATK, RANGE, level, and abilities, but the Mount's MOVE and movement pattern. |
| BR-015 | The Mount cannot take separate actions while mounted. |
| BR-016 | Damage is applied to the mounted rider's HP; when it reaches 0, both rider and Mount are defeated. |
| BR-017 | Dismounting is an action, spending 1 pool AP and 1 of the rider's own character AP: the rider remains on the current tile and the Mount is placed on an adjacent empty tile. If no adjacent empty tile exists, the pair cannot dismount. |

### 8.5 Turn And Action Points

| ID | Rule |
| --- | --- |
| BR-018 | The active player's turn-level AP pool is 2 AP on their first turn of the match and 4 AP on every turn after. |
| BR-019 | Each character has its own AP stat (default 1) capping how many actions that character can take per turn, regardless of remaining pool AP. |
| BR-020 | Movement, attacking, activating an ability, mounting, and dismounting each cost 1 pool AP, gated by the acting character having remaining character AP. |
| BR-021 | Because pool AP is smaller than full squad size, not every character is expected to act every turn — this is an intentional tactical constraint, not an oversight. The reduced 2-AP first turn is the prototype's mitigation for first-move advantage. |

### 8.6 Character Leveling

| ID | Rule |
| --- | --- |
| BR-022 | A Level 1 character reaches Level 2 by crossing to the opponent's board edge. |
| BR-023 | A Level 2 character reaches Level 3 by collecting a Spirit Ember released by a defeated enemy, then reaching the center square. |
| BR-023A | Spirit Ember pickup is automatic and immediate: when a character defeats an enemy character, the defeating character receives the Spirit Ember at that moment. No separate action, and no requirement to move onto the defeated character's tile, is needed. The carrier must still physically reach the center square while at Level 2 to trigger Level 3. |
| BR-024 | The mechanic and its name is `Spirit Ember` — a fragment of spirit/myth released by defeat within the convergence, not a body part. No darker body-part language (scalp/ear) may appear anywhere in the product. |
| BR-025 | Level-ups are match-based and reset at the end of each match unless a future mode explicitly states otherwise. |
| BR-026 | Level 2 upgrades must read as a clear, noticeable power spike (not a minor +1 tweak); Level 3 upgrades must be transformative — a significant stat jump and/or a game-changing new ability — without making a leveled character an automatic win condition. The Section 12 character inventory below reflects the revised card text meeting this standard; this is no longer a pending revision (see R-011). |

### 8.7 Relic And Event System

| ID | Rule |
| --- | --- |
| BR-027 | Relic and event cards are mixed into one shared non-character deck used by both players. |
| BR-027A | Deck construction: each player selects 3 relic cards and 4 event cards (7 cards total) from their own culture to contribute to the match's shared deck. The two players' contributions combine into one shared 14-card deck, shuffled together. In the 2-culture prototype, each culture's full relic/event set is exactly 3 relics and 4 events (Section 13), so each player's "selection" is simply their entire culture's set; this becomes a real pre-match choice once a larger relic/event pool exists. This resolves PRD-OQ-006 at 14 cards for the paper prototype. |
| BR-028 | The active player draws one shared relic/event card each turn. |
| BR-029 | Each player may have only one active relic at a time. |
| BR-030 | When a player draws a relic while their relic slot is already full, they may choose to replace the active relic or discard/ignore the newly drawn relic. |
| BR-031 | Relic replacement choices must be handled through in-game UI, not native/browser-style page-leave popups. |
| BR-032 | Event cards do not occupy a player's relic slot; they resolve immediately or remain active for their printed duration. |
| BR-033 | The shared, unpredictable relic/event draw is a deliberate design pillar, not incidental variance to be minimized. Balance and playtesting should tune the pull (frequency, power level, active-slot rules) rather than replace it with private per-culture decks. |

### 8.8 Victory Conditions

| ID | Rule |
| --- | --- |
| BR-034 | A Hero is captured — ending the match immediately in the opponent's favor — when, at the end of a turn taken by that Hero's own controller, the Hero (or the mounted pair carrying it) has no legal move available. This is a positional, chess-checkmate-style condition, not an HP threshold. |
| BR-034A | Reducing a Hero's HP to 0 through combat defeats it the same way any character is defeated — it is removed from the board and counts toward Army Defeat — but does not, by itself, trigger the Hero-capture win condition (see AS-009). |
| BR-035 | A player also wins by defeating all opposing characters (army defeat). |

### 8.9 Fairness And Progression

| ID | Rule |
| --- | --- |
| BR-036 | Competitive progression must preserve fair, identical gameplay access to all cards and character levels. |
| BR-037 | Account unlocks must be cosmetic, mastery-based, or otherwise non-gameplay-affecting; no pay-to-win power progression at any stage. |

### 8.10 Cultural Content

| ID | Rule |
| --- | --- |
| BR-038 | Real-world-inspired cultures (e.g., Russian-inspired) must be handled with respect and research, and must avoid stereotypes. |
| BR-039 | Real-world grounding survives as recognizable hints (eras, professions, imagery, geography, technology) rather than literal named historical figures or documented incidents. |

### 8.11 Deckbuilding Direction

| ID | Rule |
| --- | --- |
| BR-040 | The paper prototype and MVP use a fixed one-of-each-type squad per side; no deckbuilding at this stage. |
| BR-041 | A future constructed-deck system may combine any mix of the 7 character types plus relics/events, governed by composition rules (e.g., max 1 Hero, max 1 Leader) rather than a mana-cost/curve system. `[NEED: squad-size and construction rules for future deckbuilding not yet defined — deferred until this system is prioritized]` |

### 8.12 Sub-Area Content Structure

| ID | Rule |
| --- | --- |
| BR-042 | Each culture is structured around three story sub-areas, each intended to eventually contain one of each of the 7 character types plus sub-area-specific relic and event cards (21 character cards per culture long-term). |
| BR-043 | Only a representative 14-card roster (one character per type per culture) is required for the first prototype; players should not need to memorize the sub-area taxonomy to play — sub-area identity should read through card names, effects, art, and synergies. |
| BR-043A | A Closed City relic/event set (6 relics + 8 events, tagged `review_status: draft_for_review` in `data/cards/review_drafts/`) is already drafted and tied to the narrative character backlog (`NARRATIVE_CARD_BACKLOG.md`). It is documented future content, not yet part of the playable prototype's 14-card shared deck (BR-027A) — tracked here so it is not silently dropped when the Closed City sub-area is prioritized. |

### 8.13 Mobile-First Directive

| ID | Rule |
| --- | --- |
| BR-044 | Mobile-first design constraints apply starting with the paper and Godot rules prototypes, not only from the Mobile UX Prototype milestone onward — board layout, card text density, and interaction patterns should assume a phone-sized target throughout development. |

## 9. Functional Requirements

### 9.1 Match Setup

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-001 | The system shall allow a player to select a playable culture. | Must |
| FR-002 | The system shall support at least two prototype cultures: Russian-inspired and Atlantean. | Must |
| FR-003 | The system shall load a fixed starting squad of exactly one of each character type for each culture. | Must |
| FR-004 | The system shall enforce one Hero per side. | Must |
| FR-005 | The system shall enforce one Leader per side. | Must |
| FR-006 | The system shall support copy limits for non-common character types in future squad-building modes. | Should |
| FR-007 | The system shall place all selected character cards on the board at match start. | Must |
| FR-007A | The system should allow each player to place their own characters onto their own back row before the match begins. | Should |
| FR-007B | The system shall restrict player-controlled placement to each player's own back row, with no fixed designer formation elsewhere on the board. | Must |
| FR-008 | The system shall support configurable board layouts for future non-standard boards. | Should |
| FR-009 | The system shall initialize a shared relic/event deck at match start. | Must |
| FR-009A | The system shall build the match's shared relic/event deck from each player's 3-relic/4-event contribution (auto-populated from the player's culture in the 2-culture prototype). | Must |

### 9.2 Board And Movement

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-010 | The system shall provide a 7x7 board for the prototype. | Must |
| FR-011 | The system shall track each character's board position. | Must |
| FR-012 | The system shall calculate legal movement based on character MOVE. | Must |
| FR-013 | The system shall support orthogonal movement as the default movement rule. | Must |
| FR-014 | The system shall prevent characters from ending movement on occupied tiles unless an ability allows it. | Must |
| FR-015 | The system shall support abilities that move through occupied tiles. | Should |
| FR-016 | The system shall support terrain or placed objects that block movement. | Should |
| FR-017 | The system shall visually highlight legal movement tiles. | Must |
| FR-018 | The system shall visually indicate occupied, blocked, and targetable tiles. | Must |
| FR-018A | The system shall identify and visually mark the center tile for paper-test and digital-test layouts. | Should |

### 9.3 Turn And Action System

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-019 | The system shall alternate turns between players. | Must |
| FR-020 | The system shall refresh the active player's pool AP at the start of their turn: 2 AP on their first turn of the match, 4 AP on every turn after. | Must |
| FR-020A | The system shall refresh each active character's own AP stat (default 1, higher via specific cards or effects) at the start of its controller's turn. | Must |
| FR-021 | The system shall spend 1 pool AP and 1 of the acting character's AP when that character moves. | Must |
| FR-022 | The system shall spend 1 pool AP and 1 of the acting character's AP when that character attacks. | Must |
| FR-023 | The system shall spend 1 pool AP and 1 of the acting character's AP when that character uses an ability. | Must |
| FR-024 | The system shall prevent an action when either the player's pool AP or the acting character's own AP is exhausted. | Must |
| FR-025 | The system shall support effects that refresh pool AP or a specific character's AP. | Should |
| FR-026 | The system shall support pass/end-turn behavior. | Must |
| FR-027 | The system shall resolve start-of-turn and end-of-turn effects. | Should |
| FR-027A | The system shall support mount and dismount actions for eligible Heroes and Leaders. | Must |

### 9.4 Combat

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-028 | The system shall store HP, ATK, MOVE, RANGE, type, culture, level, and ability data for each character. | Must |
| FR-029 | The system shall calculate valid attack targets using character RANGE. | Must |
| FR-030 | The system shall apply basic attack damage using character ATK. | Must |
| FR-031 | The system shall reduce character HP when damage is applied. | Must |
| FR-032 | The system shall defeat and remove or mark characters when HP reaches zero. | Must |
| FR-033 | The system shall support shields and damage prevention. | Should |
| FR-034 | The system shall support push, displacement, and movement-stopping effects. | Should |
| FR-035 | The system shall support range modifiers. | Should |
| FR-036 | The system shall support damage reduction and damage redirection. | Should |
| FR-036A | The system shall support orthogonal line-of-sight attacks as the default attack pattern. | Must |
| FR-036B | The system shall support special attack patterns, such as diagonal, area, or non-line attacks, when card rules define them. | Should |
| FR-036C | The system shall block all ranged targeting — attacks and any AP ability that targets at range, whether damage-dealing or non-damage support/utility — from passing through an occupied tile (ally or enemy) unless the specific card or ability explicitly states an exception. This resolves PRD-OQ-011 and supersedes the former split Must/Should requirement pending that resolution. | Must |
| FR-036D | The system shall block the same ranged targeting from passing through a tile holding a placed object, by default, unless the specific card or object explicitly states an exception (BR-011A). | Must |

### 9.5 Character Abilities

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-037 | The system shall support printed character abilities. | Must |
| FR-038 | The system shall support movement abilities such as Vault and Glide. | Must |
| FR-039 | The system shall support offensive abilities such as Chill and Pounce. | Must |
| FR-040 | The system shall support defensive abilities such as Quartz Armor and Resonance Shield. | Must |
| FR-041 | The system shall support support abilities such as Command and Link Mind, subject to the same line-of-sight rule as damage-dealing abilities (FR-036C, FR-036D). | Must |
| FR-042 | The system shall support placeable objects such as barricades and quartz pylons. | Should |
| FR-043 | The system shall support once-per-turn and once-per-match ability limits. | Should |
| FR-044 | The system shall show ability range and legal targets before confirmation. | Must |
| FR-045 | The system shall require confirmation before irreversible ability use. | Should |
| FR-045A | The system shall support stronger utility abilities on low-ATK characters so low-attack pieces remain strategically useful. | Must |
| FR-045I | The system shall distinguish passive abilities from AP-activated abilities in card text and UI. | Must |

### 9.5A Mounted Pair System

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-045B | The system shall allow an eligible Hero or Leader to mount an adjacent allied Mount by spending 1 pool AP and 1 of that character's own AP, and shall block the action when either is unavailable. | Must |
| FR-045C | The system shall represent a mounted Hero or Leader and Mount as occupying one board tile. | Must |
| FR-045D | The system shall use the rider's HP, ATK, RANGE, level, and abilities while mounted. | Must |
| FR-045E | The system shall use the Mount's MOVE and movement pattern while mounted. | Must |
| FR-045F | The system shall prevent the Mount from acting separately while mounted. | Must |
| FR-045G | The system shall defeat both rider and Mount when the mounted rider's HP reaches 0. | Must |
| FR-045H | The system shall allow dismounting as an action, spending 1 pool AP and 1 of the rider's own character AP, only when a valid adjacent empty tile exists. | Must |

### 9.6 Character Leveling

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-046 | The system shall track each character's current level from 1 to 3. | Must |
| FR-047 | The system shall detect when a character reaches the opponent's board edge. | Must |
| FR-047A | The system shall track Spirit Ember possession as a status/counter on the carrying character, not as a separate placed board object. | Must |
| FR-048 | The system shall level up a character when it reaches the opponent's board edge (Level 2) or delivers a Spirit Ember to the center square (Level 3). | Must |
| FR-049 | The system shall apply Level 2 and Level 3 upgrades to character rules. | Must |
| FR-050 | The system shall prevent character levels from exceeding 3. | Must |
| FR-051 | The system shall reset match-based levels after a match ends. | Must |
| FR-052 | The system shall visually communicate character level and upgraded rules. | Must |

### 9.7 Relic And Event System

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-053 | The system shall maintain a shared relic/event deck used by both players. | Must |
| FR-054 | The system shall draw one shared relic/event card each turn for the active player. | Must |
| FR-055 | The system shall distinguish persistent relic effects from temporary event effects. | Must |
| FR-056 | The system shall apply shared relic/event effects to the board state. | Must |
| FR-057 | The system shall display each player's active relic clearly. | Must |
| FR-058 | The system shall support previewing the next relic/event card if an ability allows it. | Should |
| FR-059 | The system shall support placing a previewed card on the bottom of the shared deck. | Should |
| FR-059A | The system shall enforce one active relic slot per player. | Must |
| FR-059B | The system shall allow the active player to choose whether to replace their current relic when drawing a new relic, via in-game UI rather than a page-leave-style popup. | Must |
| FR-059C | The system shall display the currently drawn or active event separately from player relic slots. | Must |

### 9.8 Victory And Match End

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-060 | The system shall, at the end of each turn taken by a Hero's own controller, check whether that Hero (or its mounted pair) has any legal move available. | Must |
| FR-060A | The system shall trigger the Hero-capture win condition for the opposing player when that check finds no legal move available. | Must |
| FR-061 | The system shall immediately end the match when a Hero-capture win is triggered. | Must |
| FR-061A | The system shall defeat and remove a Hero whose HP reaches 0 the same way as any other character, without independently ending the match (see BR-034A, AS-009). | Must |
| FR-062 | The system shall detect when all characters on one side are defeated. | Must |
| FR-063 | The system shall end the match when army defeat victory occurs. | Must |
| FR-064 | The system shall show victory and defeat states, distinguishing a Hero-capture win from an army-defeat win. | Must |
| FR-065 | The system shall record the winning condition for playtest notes or analytics. | Should |

### 9.9 User Interface And UX

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-066 | The system shall support tap-friendly character selection on mobile screens. | Must |
| FR-067 | The system shall support character inspection, including stats, level, ability, and status effects. | Must |
| FR-068 | The system shall highlight legal moves, attack ranges, ability ranges, and danger zones. | Must |
| FR-069 | The system shall show whose turn it is. | Must |
| FR-070 | The system shall show which characters still have action points. | Must |
| FR-071 | The system shall show active relic/event effects. | Must |
| FR-072 | The system shall provide clear end-turn controls. | Must |
| FR-073 | The system shall avoid hiding critical board state behind menus. | Must |
| FR-074 | The system shall support undo or confirmation for selected actions during prototype testing. | Should |
| FR-074A | The system shall display character status reminders (e.g., shield, temporary attack/movement bonus, Pounce mark) directly on the board via small icons or badges. | Must |

### 9.10 Progression And Fairness

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-075 | The system shall not require paid unlocks for gameplay power. | Must |
| FR-076 | The system shall keep character cards mechanically consistent for all players in competitive modes. | Must |
| FR-077 | The system shall support cosmetic progression such as skins, alternate art, titles, banners, or board skins. | Should |
| FR-078 | The system shall support culture mastery progression without changing competitive power. | Should |
| FR-079 | The system shall support ranked progression in a future mode without gameplay stat advantages. | Could |

### 9.11 Content Management

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-080 | The system shall store character data in a format that can be edited without rewriting game logic (`data/cards/characters.json`). | Must |
| FR-081 | The system shall store relic/event card data in a format that can be edited without rewriting game logic (`data/cards/relic_events.json`). | Must |
| FR-082 | The system shall support adding future cultures with seven character types each. | Should |
| FR-082A | The content system shall be structured so each future culture can support three sub-areas, each with seven character types plus sub-area-specific relics and events. | Should |
| FR-082B | The content system shall support tracking draft/review-status content (e.g., the Closed City relic/event set) separately from the playable prototype deck until promoted. | Should |
| FR-083 | The system shall support balancing stats and abilities across paper and digital prototypes. | Must |
| FR-084 | The system shall support internal debug visibility for board state, action points, HP, level, and active effects. | Should |

### 9.12 Godot Prototype

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-085 | The first software prototype shall be built in Godot. | Must |
| FR-086 | The Godot prototype shall implement the board/grid engine. | Must |
| FR-087 | The Godot prototype shall implement the turn manager, including the pool-AP/character-AP system. | Must |
| FR-088 | The Godot prototype shall implement character movement, attacks, abilities, level-ups, Spirit Ember tracking, and win/loss checks (including the no-legal-move Hero capture check). | Must |
| FR-089 | The Godot prototype shall use placeholder art until core rules are validated. | Must |
| FR-090 | The Godot prototype shall support local hotseat play before networked play. | Must |
| FR-090A | The Godot prototype shall support exporting to Web (HTML5) to enable automated browser-based testing (e.g., Playwright). | Must |

## 10. Non-Functional Requirements

### 10.1 Performance

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-001 | The mobile prototype should maintain smooth interaction on target test devices. | Must |
| NFR-002 | Board selection, movement highlighting, and target/line-of-sight highlighting should respond within 100 ms on target devices. | Should |
| NFR-003 | Turn transitions should complete without noticeable delay except for intentional animations. | Should |
| NFR-004 | The game should avoid long animations that slow repeated tactical play. | Must |

### 10.2 Usability

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-005 | The board and characters must remain readable on small mobile screens. | Must |
| NFR-006 | Card and character text must be legible without excessive zooming. | Must |
| NFR-007 | Players must be able to understand legal actions from visual feedback. | Must |
| NFR-008 | The UI must clearly distinguish movement, attack, ability, and relic/event states. | Must |
| NFR-009 | The game should minimize accidental irreversible actions through confirmation or clear input states. | Should |
| NFR-009A | Mobile-first constraints apply from the paper and Godot rules prototypes onward, not deferred to the Mobile UX Prototype milestone (BR-044). | Must |

### 10.3 Balance And Fairness

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-010 | Competitive gameplay must not depend on paid power progression. | Must |
| NFR-011 | Both prototype cultures should have viable paths to victory. | Must |
| NFR-012 | No single character should dominate the game without counterplay after tuning. | Must |
| NFR-013 | Level 2 and Level 3 upgrades should reliably feel worth pursuing — reward should justify the risk of exposing a piece to reach the enemy edge or return to center with a Spirit Ember — without making comebacks impossible. | Must |
| NFR-014 | Shared relic/event cards should create variety without deciding matches randomly. | Should |
| NFR-015 | The checkmate-style Hero capture rule (BR-034) should reward active engagement and threat creation, not reward pure turtling; event card design is an explicit lever for this (see R-004). | Must |

### 10.4 Maintainability

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-016 | Core rules should be separated from character and card data where practical. | Must |
| NFR-017 | Character stats and abilities should be easy to rebalance during playtesting. | Must |
| NFR-018 | Future cultures and sub-areas should be addable without rewriting the board or turn systems. | Should |
| NFR-019 | The codebase should support automated or scripted validation of character data where possible. | Should |

### 10.5 Reliability

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-020 | The game state must remain consistent after every action. | Must |
| NFR-021 | Invalid moves, attacks, and ability targets — including line-of-sight violations — must be rejected. | Must |
| NFR-022 | The match must always be able to reach a valid end state. | Must |
| NFR-023 | The system should log rule errors or impossible states during prototype testing. | Should |

### 10.6 Accessibility

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-024 | Important state should not be communicated by color alone. | Must |
| NFR-025 | Text, icons, and board highlights should maintain high contrast. | Must |
| NFR-026 | Tap targets should be large enough for mobile interaction. | Must |
| NFR-027 | Animations should not obscure critical state changes. | Should |

### 10.7 Platform And Technical

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-028 | The prototype shall be developed in Godot. | Must |
| NFR-029 | The game should be designed mobile-first. | Must |
| NFR-030 | The architecture should not depend on networking for the first prototype. | Must |
| NFR-031 | The prototype should be structured so AI and PvP can be added later. | Should |
| NFR-031A | The prototype should be automatable via a Web (HTML5) export target so browser-based test tooling (e.g., Playwright) can drive and verify matches without manual play. | Must |

### 10.8 Content Quality

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-032 | Real-world-inspired cultures should be treated respectfully and avoid stereotypes. | Must |
| NFR-033 | Each culture should have distinct mechanics, silhouettes, colors, and play patterns. | Should |
| NFR-034 | Character abilities should be concise enough to fit mobile card inspection UI. | Should |
| NFR-035 | Placeholder art must remain readable enough for playtesting. | Must |

## 11. Data Requirements

### 11.1 Character Data

Each character record (`data/cards/characters.json`) should include: character ID, name, faction/culture, sub-area, type, unique flag, copy limit, level, HP, ATK, MOVE, RANGE, movement pattern, attack pattern, ability text, ability timing type (passive or AP ability), ability rules data, Level 2 upgrade, Level 3 upgrade, role/flavor summary, art reference, icon reference.

### 11.2 Match Data

Each match record should track: player cultures, starting board layout (including each player's chosen back-row arrangement), character positions, character HP, character levels, Spirit Ember possession status per character, mounted pair state, pool AP remaining, each character's remaining AP, active relic for each player, active or most recent event effects, shared relic/event deck order and each player's 3-relic/4-event contribution, turn number, current player, defeated characters, victory condition (Hero capture vs. army defeat).

### 11.3 Relic/Event Data

Each relic/event record (`data/cards/relic_events.json`) should include: card ID, name, faction/culture, sub-area, kind (relic or event), duration, trigger timing, effect rules, note/flavor text, visual/audio references, review status (playable vs. `draft_for_review`, per BR-043A).

### 11.4 Analytics And Playtest Reporting Data

Each match record should, where feasible, also capture: match length, victory condition and which side won, turn count and action counts by action type, character level-up and Spirit Ember delivery events, relic/event draws and replacements, and observed turtling/stalling behavior (SM-009). Playtest reporting should capture comprehension time, replay interest, confusing rules, and perceived culture distinction (SM-001 through SM-009).

## 12. Initial Character Card Inventory

Source of truth: `data/cards/characters.json`, which matches the current PRD Section 8 tables exactly. Level 2 upgrades read as a clear power spike and Level 3 upgrades are transformative, per BR-026 — this inventory reflects the revised (2026-07-18, resynced 2026-08-14) card text, not the earlier pending-revision placeholder.

### 12.1 Russian-Inspired

| Character | Type | HP | ATK | MOVE | RANGE | Level 1 Ability | Level 2 Upgrade | Level 3 Upgrade |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| Gymnast | Common | 2 | 1 | 3 | 1 | Passive: Vault may move through 1 adjacent allied character during movement. | +1 MOVE and Vault may pass through any one occupied tile during movement. After Vaulting, this character may move 1 extra tile. | Aurora Acrobat: +1 ATK and +1 MOVE. Once each turn after Vaulting, may make a 1-damage adjacent attack without spending AP. |
| White Siberian Tiger | Mount | 4 | 2 | 4 | 1 | Activated Pounce: only while not mounted. Marks its next attack after moving as +2 ATK. Movement and attack costs still apply. | +1 HP and +1 MOVE. Pounce also pushes the target 1 tile if possible. | Aurora Predator: +1 ATK. When Pounce defeats a target, this character may move up to 2 tiles and refresh 1 character AP once per turn. |
| Sniper | Warrior | 3 | 2 | 2 | 4 | Passive: Aim gives this character's basic attack +1 RANGE if it did not move this turn. | +1 RANGE. Piercing Shot ignores 1 shield or damage reduction, and may ignore one occupied allied tile for line-of-sight. | Dead Lane: +1 ATK. Once per turn, after damaging an enemy at range 3 or farther, mark that enemy; the next allied attack against it deals +1 damage. |
| Army General | Leader | 5 | 1 | 2 | 1 | AP Ability: Command chooses an allied character within 2 tiles. That ally gains +1 ATK on its next attack this turn or may move 1 tile without spending an action. | Command range becomes 3 and may target 2 allies. Each target chooses +1 ATK on its next attack or 1 free tile of movement. | Tactical Mastery: +1 HP. Once per turn when a Commanded ally defeats an enemy or delivers a Spirit Ember, refresh 1 character AP on an allied character within 2 tiles. |
| Bogatyr Champion | Hero | 6 | 2 | 2 | 1 | Passive: Stand Firm gives +1 maximum and current HP while this character is on or adjacent to the center tile. | Heroic Guard: +2 maximum and current HP while on or adjacent to the center tile. Adjacent allies take -1 damage from attacks. | Last Oath: +1 ATK and +2 maximum HP. The first time this character would be defeated, it remains at 2 HP and adjacent enemies take 1 damage. |
| Winter Engineer | Specialist | 3 | 1 | 2 | 1 | AP Ability: Barricade creates 1 barricade on an adjacent empty tile, or repairs an adjacent barricade or placed object by 1 HP. Barricades block movement and have 2 HP. | Fortified Works: Barricades have 3 HP. When using Barricade, create or repair up to 2 adjacent barricades or placed objects. | Frozen Redoubt: +1 HP. Once per turn, place a barricade or frost tile within 2 tiles. Allies adjacent to placed objects take -1 damage from ranged attacks. |
| Frost Seer | Mystic | 3 | 1 | 2 | 3 | AP Ability: Chill deals 1 damage at range 3. Target's MOVE is reduced by 1 and it cannot mount or dismount on its next turn. | Winter Veil: Chill also gives one ally within 3 tiles a 1-damage shield. Shielded allies cannot be pushed this turn. | Deep Freeze: +1 RANGE. Chill also prevents the target from using reaction or bonus movement effects next turn; if the target already has a slow marker, it cannot move next turn. |

### 12.2 Atlantean

| Character | Type | HP | ATK | MOVE | RANGE | Level 1 Ability | Level 2 Upgrade | Level 3 Upgrade |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| Quartz Attendant | Common | 2 | 1 | 2 | 1 | Passive: Synchronize gives +1 ATK while adjacent to another Atlantean. | Shared Pulse: +1 HP. While adjacent to another Atlantean, gains +1 ATK and the first damage to one adjacent Atlantean each turn is reduced by 1. | Collective Node: +1 HP. Counts as a pylon and as adjacent to Atlanteans within 2 tiles for Synchronize and relay effects. |
| Manta Glider | Mount | 3 | 1 | 4 | 1 | Passive: Glide may move over occupied tiles but must end on an empty tile. If carrying a Hero or Leader, the mounted pair may also glide. | +1 MOVE. After moving over any character, this character's next attack this turn gains +1 ATK. | Phase Current: +1 HP and +1 ATK. Once per turn, ignore terrain, barricades, and occupied tiles during movement; deal 1 damage to one enemy moved over. |
| Resonance Guard | Warrior | 5 | 1 | 2 | 1 | Passive: Quartz Armor reduces ranged attack damage by 1. | Redirect: +1 ATK. Once per turn, may take damage for an adjacent ally; reduce that redirected damage by 1. | Resonant Bastion: Adjacent allies gain a 1-damage shield at the start of your turn. After this character reduces damage, deal 1 damage back if the attacker is within range 2. |
| Divine Conductor | Leader | 4 | 1 | 2 | 3 | AP Ability: Link Mind chooses an ally within 3 tiles. Until end of turn, that ally may use the Conductor's RANGE for its ability if valid, and may ignore one allied character for line-of-sight. | Link Mind may target 2 allies within 3 tiles. Linked allies may use the Conductor's RANGE and ignore one allied character for line-of-sight. | Perfect Chord: +1 RANGE. Once per turn, when a linked ally defeats an enemy or delivers a Spirit Ember, refresh that ally's character AP. |
| Oracle Sovereign | Hero | 5 | 1 | 2 | 3 | AP Ability: Foresight reveals the next shared relic/event card. You may place it on the bottom of the deck. Then give one adjacent ally a 1-damage shield. | Spirit Mantle: At the start of your turn, this character and one adjacent ally each gain a 1-damage shield. Foresight may instead leave the revealed card on top. | Collective Ascension: +1 HP and +1 RANGE. Once per match, all allies heal 2, gain a 1-damage shield, and gain +1 MOVE this turn. |
| Crystal Architect | Specialist | 3 | 1 | 2 | 2 | AP Ability: Pylon places a quartz pylon on an adjacent empty tile, or moves an existing allied pylon 1 tile. Allies within 2 tiles of a pylon gain +1 RANGE on abilities. | Pylon range becomes 2. Pylons have 2 HP, and allies within 2 tiles of a pylon gain +1 RANGE on attacks and abilities. | Relay Gate: +1 HP. Once per turn, teleport an ally adjacent to a pylon to an empty tile adjacent to another pylon within 4 tiles, then give that ally a 1-damage shield. |
| Astral Harmonic | Mystic | 3 | 1 | 2 | 3 | AP Ability: Resonance Shield shields an ally within 3 tiles for 1 damage prevention. If that ally is mounted, the shield prevents 2 damage instead. | Harmonic Bind: Resonance Shield prevents 2 damage and the shielded ally cannot be pushed, pulled, or displaced this turn. | Astral Echo: +1 RANGE. After shielding an ally, may deal 1 damage to an enemy within 2 tiles of that ally; the shielded ally may move 1 tile without spending AP. |

## 13. Initial Relic And Event Inventory

Source of truth: `data/cards/relic_events.json`. Relic and event cards are culture-themed but mixed into one shared non-character deck used by both players (BR-027, BR-033). Each player contributes their full culture set — 3 relics and 4 events — to build the shared 14-card deck (BR-027A). Each player may have only one active relic; drawing a new relic while one is already active allows that player to replace it or ignore the new draw (BR-029, BR-030).

### 13.1 Russian-Inspired Relics (3)

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Winter Palace Standard | Relic | Persistent | Your Hero and Leader each gain +1 maximum HP while this relic is active. |
| Iron Birch Talisman | Relic | Persistent | Your Common and Warrior each gain +1 maximum HP while this relic is active. |
| General's War Map | Relic | Persistent | Once each turn, one of your characters gains +1 RANGE on its next attack or ability. |

### 13.2 Russian-Inspired Events (4)

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Whiteout | Event | 1 round | All ranged attacks and ranged abilities have -1 RANGE, minimum 1. |
| Frozen Center | Event | 1 round | The center row and center tile count as frost. A character entering frost stops moving. |
| Rally From The Snow | Event | Immediate | The active player heals 1 HP on one damaged character. |
| Long Winter March | Event | 1 turn | The active player's first movement action this turn gains +1 MOVE. |

### 13.3 Atlantean Relics (3)

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Quartz Heart Core | Relic | Persistent | Your shields prevent +1 additional damage while this relic is active. |
| Hall Of Shared Minds | Relic | Persistent | Your adjacent characters gain +1 RANGE on abilities. |
| Tideglass Obelisk | Relic | Persistent | Your characters adjacent to a placed object gain +1 RANGE on attacks and abilities. |

### 13.4 Atlantean Events (4)

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Resonance Surge | Event | 1 turn | The active player's first ability this turn has +1 RANGE. |
| Psychic Undertow | Event | 1 turn | The active player's first attack this turn may push or pull the target 1 tile. |
| Crystal Tide | Event | 1 turn | The active player's characters have +1 RANGE on abilities this turn. |
| Dream Of The Deep City | Event | Immediate | Reveal the next shared relic/event card. The active player may leave it on top or place it on the bottom of the deck. |

### 13.5 Documented Future Content — Closed City (Not Yet In Prototype Scope)

Per BR-043A, a full Closed City relic/event set is drafted in `data/cards/review_drafts/` and tagged `draft_for_review`. It is listed here only for traceability — effect text is still subject to change and is intentionally not promoted into Section 13.1–13.4 until it clears review.

- **Relics (6 of 6):** Chintamani Fragment (Rare), Reactor Core Fragment, Cosmonaut Helmet With A Second Shadow, Lead-Sealed Notebook, Redacted Incident Tape, Karpova's Black Key.
- **Events (8 of 8):** Signal Array Turns, Dream Monitors Synchronize, Reactor Prayer, Closed City Incident, Seventeen Seconds, Elena Missing In The Signal, The First Card Appears, Semyonov Orders Silence.

## 14. Risks And Mitigations

| ID | Risk | Impact | Mitigation |
| --- | --- | --- | --- |
| R-001 | Rules become too complex. | Players may abandon the game early. | Prototype with minimal rules and simplify after playtests. |
| R-002 | Shared relic/events create too much randomness. | Strategy may feel unfair. | Keep effects tactical, symmetric, and readable; tune per BR-033 rather than removing the shared-deck pillar. |
| R-003 | Level-up by reaching the edge, or returning with a Spirit Ember, may create runaway advantages — or feel too risky to attempt at all. | Comebacks may become rare, or leveling may go untested. | Tune Level 2/3 power (BR-026, NFR-013) and track how often leveling is actually attempted during paper tests. |
| R-004 | The new checkmate-style Hero capture rule (BR-034) decouples capture from combat damage entirely, which may reward overly defensive, turtling play — walling the Hero into a safe corner rather than engaging. | Matches may stall; Army Defeat alone may not reliably pull passive players into engagement. | Confirmed and agreed (2026-08-14): event card design is an explicit countermeasure. Events should be tuned to disrupt static formations and force movement (e.g. Frozen Center, Whiteout, and future cards), not left to Army Defeat alone. Track turtling explicitly in paper playtests (SM-009). |
| R-005 | Mobile board readability may suffer. | Players may misread board state. | Test on phone-sized screens early, and apply mobile-first constraints from the paper prototype onward (BR-044), not only starting at the Mobile UX milestone. |
| R-006 | Cultural themes may feel shallow or stereotyped. | Brand and player trust risk. | Use respectful research and fantasy framing (BR-038, BR-039). |
| R-007 | Godot implementation may overbuild too early. | Prototype velocity may slow. | Start with rules, placeholders, and debug UI. |
| R-008 | MVP scope (4 cultures, 28+ character cards, 40+ relic/event cards, AI opponent, full mobile UI) may exceed solo-developer capacity. | Timeline slips or burnout. | Define a sequencing/scope-cut plan (fewer cultures at MVP, smaller relic/event pool, outsourced art) before committing to MVP planning. |
| R-009 | Soviet/Cold War nuclear-accident setting may draw extra app-store or platform content-review scrutiny. | Possible platform rejection or required rework late in development. | Partially mitigated by the fiction/abstraction direction (BR-039); recommend a platform policy review before major production investment. |
| R-010 | *(Resolved 2026-08-14)* Line-of-sight scope for non-damage support/utility abilities was previously unresolved (PRD-OQ-011). | Would have left ambiguous rules-engine behavior for cards like Command, Resonance Shield, Foresight, Pylon range boost. | Resolved: line-of-sight blocking applies to all ranged targeting, including non-damage abilities (BR-011, FR-036C). Retained here for traceability only. |
| R-011 | *(Resolved 2026-08-14)* Level 2/3 upgrade text across the Section 12 character roster was previously not yet rewritten to the power-spike/transformative standard. | Was driving continued playtest feedback that leveling isn't worth the risk. | Resolved: the revision pass is complete (BR-026, Section 12). Recommend confirming the rewrite lands well in the next round of paper tests rather than treating this as a pending task. |
| R-012 | Player-chosen back-row deployment (BR-007A) could let a player accidentally box in their own Hero, or let both players independently misjudge legal starting positions. | Confusing first turns, or an accidental self-inflicted Hero-capture loss under BR-034. | Playtest specifically for this failure mode; consider a setup-time warning or legality check before the match begins (FR-007A/FR-007B implementation detail). |
| R-013 | Placed objects now blocking line-of-sight by default (BR-011A) is a new mechanical implication no paper test has exercised yet — e.g., a Crystal Architect Pylon could unexpectedly block a Sniper's line, which may read as counter-intuitive since pylons are framed as tech/range-boost pieces, not cover. | Could feel surprising or unfun until playtested; could also meaningfully change Specialist positioning value. | Call this out specifically in the next paper-test pass; revisit BR-011A if it plays worse than expected rather than treating it as permanently settled. |

## 15. Dependencies

| ID | Dependency | Blocks |
| --- | --- | --- |
| D-001 | *(Resolved 2026-08-14)* No fixed 7x7 starting formation is needed — each player deploys their own units on their own back row in their own chosen arrangement. | BR-007A, FR-007A/FR-007B (PRD-OQ-002) |
| D-002 | Portrait vs. landscape orientation not yet decided. | NFR-005, FR-066 (PRD-OQ-001) |
| D-003 | Whether defeated units are permanently removed, revived, or returned to hand is not yet decided. | FR-032 (PRD-OQ-003) |
| D-004 | *(Resolved 2026-08-14)* Line-of-sight scope for non-damage support/utility abilities applies to all ranged targeting. | FR-036C, BR-011 (PRD-OQ-011) |
| D-005 | *(Resolved 2026-08-14)* Shared relic/event card count for the first paper prototype is 14 cards, formed by each player contributing 3 relics + 4 events from their culture. | FR-009A, BR-027A (PRD-OQ-006) |
| D-006 | The Closed City scientist's exact story role (protagonist, narrator, gate, victim, antagonist, or a mix) is undecided. | Narrative framing, tutorial voice (PRD-OQ-007) |
| D-007 | Per-turn or per-match timer length for the future Timer-based/Blitz PvP mode is not set. | Future mode FRs (PRD-OQ-010) |
| D-008 | Paper prototype materials or spreadsheet, and a configured Godot environment. | FR-085 through FR-090 |
| D-009 | Placeholder art or simple readable tokens. | NFR-035, AS-005 |
| D-010 | Playtest feedback from at least 3-5 matches, specifically tracking leveling frequency, AP-pool first-move mitigation, turtling under the new Hero capture rule (R-004), and per-card rules overload. | NFR-013, BR-021, R-003, R-004 |
| D-011 | MVP-scale relic/event contribution model (still 3+4 per player from a larger pool, or something else) is undecided. | Section 6.2 MVP Scope `[NEED]` |

## 16. Acceptance Criteria

The first paper prototype is acceptable when:
- Both cultures can complete a match using the documented rules.
- Both players can self-deploy their 7 characters onto their own back row without confusion, and the digital rules prototype rejects placement outside that row.
- Players can identify legal movement, attack targets, and line-of-sight blocking — including for non-damage support abilities.
- Hero capture (no-legal-move condition, BR-034) and army defeat victories can both occur, and playtest notes record whether the checkmate-style capture rule reads clearly to new players.
- At least one character reaches Level 2, and playtest notes record whether Level 3 was attempted and why or why not (R-003).
- Shared relic/event draws (built from each player's 3 relics + 4 events) affect decisions without dominating the match.
- Playtest notes explicitly flag whether matches trend toward turtling under the new Hero capture rule (R-004, SM-009).
- Playtest notes identify balance issues for revision, including whether the 2-AP first turn meaningfully offset first-move advantage.

The first Godot prototype is acceptable when:
- A local match can be completed from setup to victory, including player-controlled back-row deployment.
- All 14 character cards are represented with their stats, sourced from `data/cards/characters.json`.
- Movement, attacks, line-of-sight (including non-damage abilities), action points (pool and per-character), mount/dismount (with correct AP cost), level-ups, Spirit Ember tracking, the no-legal-move Hero capture check, and army-defeat checks all work.
- A shared relic/event draw happens each turn, from a deck built out of each player's 3-relic/4-event contribution.
- The UI communicates turn, selected character, legal actions, HP, level, Spirit Ember status, and active relic/event effects, and clearly distinguishes a Hero-capture win from an army-defeat win.
- Placeholder art is clear enough to test the game, on a mobile-first layout.

## 17. Traceability

| BRD Section | PRD Source |
| --- | --- |
| 3. Business Objectives (BO-001–006) | PRD §2 Product Goals |
| 4. Success Metrics (SM-001–009) | PRD §20 Success Metrics |
| 6. Scope | PRD §20 Prototype Scope, §21 MVP Scope |
| 8.1–8.2 Business Rules (BR-001–007B) | PRD §5 Initial Board Concept, §8 Prototype Character Roster |
| 8.3 Business Rules (BR-008–011) | PRD §8 Prototype Character Cards (balance assumptions, line-of-sight) |
| 8.4 Business Rules (BR-012–017) | PRD §8 Mounted Character Rules |
| 8.5 Business Rules (BR-018–021) | PRD §11 Turn System, §12 Resources |
| 8.6 Business Rules (BR-022–026) | PRD §9 Spirit Ember Leveling |
| 8.7 Business Rules (BR-027–033) | PRD §9 Relic Cards, Event Cards, Prototype Relic And Event Cards |
| 8.8 Business Rules (BR-034–035) | PRD §13 Victory Conditions |
| 8.9 Business Rules (BR-036–037) | PRD §14 Progression, §22 Monetization Considerations |
| 8.10 Business Rules (BR-038–039) | PRD §8 Story Premise And Tone |
| 8.11 Business Rules (BR-040–041) | PRD §9 Character Cards (Deckbuilding direction) |
| 8.12 Business Rules (BR-042–043A) | PRD §8 Faction Sub-Area Structure |
| 8.13 Business Rules (BR-044) | PRD §16 Mobile UX Requirements |
| 9. Functional Requirements | PRD §20 Product-Level Requirements (PRD-FR-001–010), elaborated against PRD §5–13 |
| 10. Non-Functional Requirements | PRD §20 Product-Level Requirements (PRD-NFR-001–004), elaborated against PRD §16–19, §23 |
| 12–13. Content Inventory | `data/cards/characters.json`, `data/cards/relic_events.json`, `data/cards/review_drafts/` |
| 14. Risks | PRD §23 Risks (PRD-RISK-001–012) |
| 15. Dependencies | PRD §24 Open Questions (PRD-OQ-001–011) |
| 18. Next Steps | PRD §26 Immediate Next Steps |

## 18. Next Steps

1. Playtest the player-chosen back-row deployment and the checkmate-style Hero capture rule specifically — confirm both create good decisions rather than confusion, accidental self-trapping, or stalling.
2. Draft the first version of the Closed City accident story and the scientist's role in the convergence.
3. Write short style and mechanic notes for each of the six sub-areas.
4. Move the Closed City relic/event drafts (`draft_for_review`) through review toward promotion, once the core 14-card prototype deck is validated (BR-043A).
5. Paper test the 14 character cards and 14 shared relic/event cards, and record which pieces feel too strong, too weak, or too confusing.
6. Revise stats, Level 2 upgrades, and Level 3 Spirit Ember rules after 3-5 paper matches if further tuning is needed, now that the power-spike/transformative revision pass is complete (BR-026).
7. During paper testing, specifically track: how often Level 2/3 is actually reached (R-003 leveling-worth-it check), whether the 2-AP first turn meaningfully reduces first-move advantage, whether turtling emerges under the new Hero capture rule (R-004, SM-009), and how many turns pass before players stop feeling overwhelmed by per-card rules.
8. Build the first Godot rules prototype.
