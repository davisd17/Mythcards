# MythCards Business Requirements Document

## 1. Document Purpose

This Business Requirements Document converts the current MythCards Product Requirements Document into business-ready requirements for planning, stakeholder review, prototype validation, backlog decomposition, and acceptance testing.

This BRD is derived from `PRD.md` and preserves traceability to the PRD's stable IDs where available. Requirements marked with `Inference:` are reasonable business expansions of the PRD, not explicit PRD commitments.

## 2. Product Summary

MythCards is a mobile-first, turn-based tactical card-and-board game. Players command a small roster of civilization-themed character cards on a 7x7 board with a center tile, using positioning, action points, abilities, relics, events, and in-match level progression to outplay an opponent.

The first playable promise is a short, readable, strategic match where two prototype cultures, Russian-inspired and Atlantean, feel mechanically distinct. The prototype should prove that the board, cards, turn structure, character abilities, shared relic/event deck, Hero capture, army defeat, and match-based leveling create replayable tactical decisions before production expands toward MVP scope.

## 3. Business Objectives

| ID | Objective | Source |
| --- | --- | --- |
| BO-001 | Create a fair, skill-based mobile tactics game with readable turns and satisfying strategic depth. | PRD-GOAL-001 |
| BO-002 | Establish a card and character framework that supports seven base character types across multiple cultures. | PRD-GOAL-002 |
| BO-003 | Keep standard matches short enough for mobile play while preserving meaningful mastery. | PRD-GOAL-003 |
| BO-004 | Build flexible rules and content foundations that can support future cards, cultures, modes, events, boards, and expansions. | PRD-GOAL-004 |
| BO-005 | Establish a story and faction structure where cultures include sub-areas with distinct mechanics, art direction, relics, events, and narrative identity. | PRD-GOAL-005 |
| BO-006 | Support a delivery path from paper prototype to local digital prototype, AI play, casual PvP, and future ranked/asynchronous PvP. | PRD-GOAL-006 |
| BO-007 | Preserve competitive trust by avoiding pay-to-win progression and keeping gameplay access fair. | PRD-NFR-003 |

## 4. Success Metrics

| ID | Metric | Target | Validation Method | Source |
| --- | --- | --- | --- | --- |
| SM-001 | Rule comprehension | New playtesters understand legal movement, basic attacks, turn flow, and Hero capture within 2 minutes. | Observe first-session paper or digital playtests. | PRD-SM-001 |
| SM-002 | Prototype match length | Paper prototype matches finish within 10-20 minutes. | Time 3-5 comparable-skill test matches. | PRD-SM-002 |
| SM-003 | Mobile match target | Standard mobile matches trend toward 5-12 minutes after UX and balance tuning. | Measure digital prototype and MVP session analytics. | PRD-SM-003 |
| SM-004 | Decision density | Each turn presents at least one meaningful tactical choice. | Playtest survey plus designer review of turn logs. | PRD-SM-004 |
| SM-005 | Faction distinction | Playtesters can describe how Russian-inspired and Atlantean playstyles differ after one match. | Post-match interview or survey. | PRD-SM-005 |
| SM-006 | Replay pull | At least half of early playtesters want to replay, switch faction, or try a different strategy after a match. | Post-match survey. | PRD-SM-006 |
| SM-007 | Mobile readability | Testers can inspect unit state, legal actions, relic/event state, and victory threats without repeated menu hunting. | Mobile UX prototype observation. | PRD-SM-007 |
| SM-008 | Balance health | Neither prototype culture should win more than 60 percent of comparable-skill paper tests after initial tuning. | Track results from at least 3-5 paper matches, then expand the sample. | Inference from PRD risks and prototype success criteria |

## 5. Stakeholders

| ID | Stakeholder | Interest | Primary Needs |
| --- | --- | --- | --- |
| STK-001 | Product Owner | Scope, monetization direction, roadmap, and release priorities. | Traceable requirements, decision points, and milestone readiness. |
| STK-002 | Game Designer | Rules, characters, factions, balance, progression, and playtest iteration. | Atomic requirements, business rules, card data needs, and acceptance criteria. |
| STK-003 | Developer | Digital prototype and future game systems. | Clear functional scope, data requirements, technical constraints, and testable edge cases. |
| STK-004 | Artist/UI Designer | Card frames, board visuals, icons, faction identity, and mobile screens. | Art direction, UI state requirements, readability constraints, and content taxonomy. |
| STK-005 | Narrative/Content Designer | Story premise, culture framing, sub-area identity, relics, events, and tone. | Respectful culture guidance, faction structure, terminology decisions, and content requirements. |
| STK-006 | Playtesters | Validate fun, clarity, balance, and pacing. | Printable/digital materials, clear rules, survey prompts, and observable success criteria. |
| STK-007 | Future Players | Fair, readable, rewarding tactical gameplay. | Clear onboarding, fair progression, legible UI, and meaningful replay value. |

## 6. Scope

### 6.1 Prototype Scope

The first prototype must include:

- 7x7 board with one visually marked center tile.
- Two playable cultures: Russian-inspired and Atlantean.
- Seven character types per culture: Common, Mount, Warrior, Leader, Hero, Specialist, Mystic.
- Fourteen total character cards.
- One copy of each character card per side for the first paper prototype.
- Three match-based character levels.
- Level 2 progression by reaching the opponent's edge.
- Level 3 progression by collecting a Spirit Ember and delivering it to the center square.
- One action point per character per turn.
- Movement, attack, ability, mount, dismount, pass, and end-turn flow.
- Shared relic/event deck with one draw for the active player each turn.
- One active relic slot per player.
- Immediate or duration-based event resolution.
- Hero capture and army defeat victory conditions.
- Local hotseat play for paper and early digital prototypes.
- Simple AI as an early digital option if local human testing is insufficient.
- Placeholder but readable art.
- Debug or inspection UI sufficient for playtesting.

### 6.2 MVP Scope

The MVP should include:

- Tutorial.
- AI opponent.
- Casual PvP.
- Squad viewer or cosmetic loadout.
- Collection viewer.
- Four cultures.
- Seven character types per culture.
- At least 28 character cards.
- At least 40 shared relic/event cards.
- Content architecture that can later support three sub-areas per faction.
- Cosmetic and mastery progression.
- Mobile-ready UI.
- Analytics events.
- Local save data.
- Internal balancing tools.

### 6.3 Future Scope

Future scope may include:

- Ranked PvP.
- Asynchronous PvP.
- Campaign.
- Draft mode.
- Puzzle mode.
- Limited-time events.
- Guild or clan features.
- Culture-specific boards and skins.
- Larger content collection.
- Optional premium, cosmetic, expansion, or campaign monetization.

### 6.4 Out Of Scope For Prototype

- Real-money monetization.
- Ranked ladder.
- Large campaign.
- Full live operations system.
- Complex multiplayer infrastructure.
- Large-scale card collection.
- Pay-to-win progression.
- Final art, final audio, and final animation polish.

## 7. Assumptions

| ID | Assumption | Source |
| --- | --- | --- |
| AS-001 | The first prototype will be validated on paper before Godot development begins. | PRD-MILESTONE-001 |
| AS-002 | The first software prototype will prioritize rules, state clarity, and debug visibility over final art, monetization, or networking. | PRD-MILESTONE-002 |
| AS-003 | Players begin prototype matches with all selected character cards placed on the board. | PRD section 9 |
| AS-004 | Character cards do not have deployment costs in the prototype. | PRD section 9 |
| AS-005 | Gameplay progression must not require paid unlocks or stronger cards. | PRD-NFR-003 |
| AS-006 | Cosmetic progression is acceptable if it does not affect match outcomes. | PRD section 14 |
| AS-007 | The first digital prototype can use placeholder art if it remains readable enough for playtesting. | PRD section 20 |
| AS-008 | The initial board is a 7x7 grid with orthogonal movement and orthogonal line-of-sight attacks unless card rules state otherwise. | PRD section 8 |
| AS-009 | The first implementation can represent defeat trophies as a marker, status, or abstract state until PRD-OQ-008 is resolved. | PRD-OQ-008 |
| AS-010 | The Closed City story framing can guide content without requiring a full campaign in the prototype. | PRD sections 1 and 20 |

## 8. Constraints

| ID | Constraint | Source |
| --- | --- | --- |
| CON-001 | The prototype board size shall be 7x7. | PRD-FR-001 |
| CON-002 | The prototype shall include exactly two playable cultures before broader MVP expansion. | PRD-FR-002 |
| CON-003 | The prototype shall use seven base character types per culture. | PRD-GOAL-002 |
| CON-004 | The first paper prototype shall use one copy of each character type per side. | PRD section 8 |
| CON-005 | The first digital prototype shall be implemented in Godot unless a later decision explicitly changes the engine. | PRD section 19 |
| CON-006 | The prototype shall not depend on networking. | PRD sections 15 and 21 |
| CON-007 | Competitive systems shall not sell gameplay power. | PRD-NFR-003 |
| CON-008 | Real-world-inspired cultures shall use respectful research and fantasy framing. | PRD-NFR-004 |
| CON-009 | Mobile UI shall remain readable on phone-sized screens. | PRD-NFR-002 |

## 9. Business Rules

| ID | Rule | Source |
| --- | --- | --- |
| BR-001 | Each side may field only one Hero in the prototype. | PRD section 8 |
| BR-002 | Each side may field only one Leader in the prototype. | PRD section 8 |
| BR-003 | Each side may field up to two copies of each non-common, non-unique type in future squad-building rules unless changed by a later mode. | PRD section 8 |
| BR-004 | Common characters may be used in larger numbers if future squad sizes require filler units. | PRD section 8 |
| BR-005 | The first paper prototype uses one copy of each of its seven character type cards per side. | PRD section 8 |
| BR-006 | Character cards begin on the board at match start. | PRD section 9 |
| BR-007 | Character cards have no deployment cost in the prototype. | PRD section 9 |
| BR-008 | Each character refreshes to one action point at the start of its controller's turn. | PRD section 12 |
| BR-009 | Movement consumes that character's action point unless a card explicitly grants bonus movement. | PRD section 12 |
| BR-010 | Attacking consumes that character's action point unless a card explicitly states otherwise. | PRD section 12 |
| BR-011 | Using an AP Ability consumes that character's action point. | PRD section 9 |
| BR-012 | Passive abilities do not consume action points by themselves. | PRD section 9 |
| BR-013 | Activated abilities must state whether they spend AP, mark a future action, or require another cost. | PRD section 9 |
| BR-014 | A Level 1 character reaches Level 2 by crossing to the opponent's board edge. | PRD section 9 |
| BR-015 | A Level 2 character reaches Level 3 by collecting a Spirit Ember from a defeated enemy and delivering it to the center square. | PRD-FR-007 |
| BR-016 | Match-based levels reset after a match unless a future mode explicitly states otherwise. | PRD section 14 |
| BR-017 | A player wins immediately by capturing or defeating the opposing Hero. | PRD-FR-004 |
| BR-018 | A player wins by defeating all opposing characters. | PRD-FR-004 |
| BR-019 | Relic and event cards are mixed into one shared non-character deck. | PRD-FR-005 |
| BR-020 | The active player draws one shared relic/event card each turn. | PRD-FR-005 |
| BR-021 | Each player may have only one active relic at a time. | PRD section 9 |
| BR-022 | If a player draws a relic while already holding an active relic, that player may replace the active relic or ignore/discard the new relic. | PRD section 9 |
| BR-023 | Event cards do not occupy relic slots and resolve immediately or for their printed duration. | PRD section 9 |
| BR-024 | Default movement is orthogonal unless a card, relic, event, terrain, or future mode states otherwise. | PRD section 8 |
| BR-025 | Default attack pattern is orthogonal line-of-sight unless a card, relic, event, or future mode states otherwise. | PRD section 8 |
| BR-026 | Diagonal, area, jump, teleport, or unusual patterns require explicit special rules. | PRD section 8 |
| BR-027 | A Hero or Leader may mount an adjacent allied Mount by spending an action. | PRD section 8 |
| BR-028 | A mounted Hero or Leader and Mount occupy the same board tile as a combined mounted pair. | PRD section 8 |
| BR-029 | A mounted pair uses the rider's HP, ATK, RANGE, level, and abilities, but uses the Mount's MOVE and movement pattern. | PRD section 8 |
| BR-030 | A Mount cannot take separate actions while carrying a Hero or Leader. | PRD section 8 |
| BR-031 | Damage to a mounted pair is applied to the rider's HP. When that HP reaches 0, both rider and Mount are defeated. | PRD section 8 |
| BR-032 | Dismounting is an action and requires a valid adjacent empty tile. | PRD section 8 |
| BR-033 | Competitive progression must preserve fair access to gameplay power. | PRD-NFR-003 |
| BR-034 | Account unlocks should be cosmetic, mastery-based, or non-gameplay-affecting. | PRD section 14 |
| BR-035 | The rules and UI term for Level 3 progression is `Spirit Ember`; older body-part language is retired. | PRD-RISK-006 |

## 10. Functional Requirements

### 10.1 Match Setup

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-001 | The system shall allow a player to select a playable culture for prototype matches. | Must | Enables faction identity and replay testing. | PRD-FR-002 |
| FR-002 | The system shall support Russian-inspired and Atlantean cultures for the prototype. | Must | Required to test two distinct playstyles. | PRD-FR-002 |
| FR-003 | The system shall load a fixed starting squad for each prototype culture. | Must | Keeps the first prototype focused and testable. | PRD section 20 |
| FR-004 | The system shall enforce one Hero per side. | Must | Supports the Hero capture victory condition. | BR-001 |
| FR-005 | The system shall enforce one Leader per side. | Must | Preserves intended faction command structure. | BR-002 |
| FR-006 | The system should support configurable copy limits for future squad-building modes. | Should | Allows expansion without reworking roster rules. | BR-003 |
| FR-007 | The system shall place all selected character cards on the board at match start. | Must | Matches the prototype's no-deployment-cost model. | BR-006 |
| FR-008 | The system shall support configurable starting board layouts. | Must | The exact 7x7 formation remains an open decision. | PRD-OQ-002 |
| FR-009 | The system shall initialize a shared relic/event deck at match start. | Must | Enables the shared non-character draw system. | PRD-FR-005 |

### 10.2 Board And Movement

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-010 | The system shall provide a 7x7 board for the prototype. | Must | Required by the first playable scope. | PRD-FR-001 |
| FR-011 | The system shall visually identify the center tile. | Must | The center tile is used for Level 3 progression and tactical focus. | PRD-FR-001, PRD-FR-007 |
| FR-012 | The system shall track each character's board position. | Must | Required for movement, attacks, abilities, trophies, and victory. | PRD-FR-003 |
| FR-013 | The system shall calculate legal movement based on character MOVE and movement rules. | Must | Enables tactical clarity. | PRD-FR-003 |
| FR-014 | The system shall support orthogonal movement as the default movement rule. | Must | Establishes the prototype baseline. | BR-024 |
| FR-015 | The system shall prevent characters from ending movement on occupied tiles unless a card rule allows it. | Must | Preserves board state consistency. | BR-026 |
| FR-016 | The system shall support abilities that move over or through occupied tiles when printed rules allow them. | Should | Needed for Vault and Glide behavior. | PRD section 8 |
| FR-017 | The system should support terrain or placed objects that block or modify movement. | Should | Needed for barricades, frost, pylons, and future maps. | PRD sections 8 and 10 |
| FR-018 | The system shall visually highlight legal movement tiles. | Must | Supports rule comprehension and mobile usability. | PRD-NFR-002 |
| FR-019 | The system shall visually distinguish occupied, blocked, targetable, and dangerous tiles. | Must | Supports tactical clarity. | PRD-NFR-002 |

### 10.3 Turn And Action System

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-020 | The system shall alternate turns between players. | Must | Establishes the tactical match structure. | PRD-FR-003 |
| FR-021 | The system shall resolve start-of-turn effects before the active player acts. | Should | Supports relics, events, shields, and future effects. | PRD section 11 |
| FR-022 | The system shall refresh each active character to one action point at the start of its controller's turn. | Must | Implements the core action economy. | BR-008 |
| FR-023 | The system shall spend a character's action point when that character moves. | Must | Enforces action economy. | BR-009 |
| FR-024 | The system shall spend a character's action point when that character attacks. | Must | Enforces action economy. | BR-010 |
| FR-025 | The system shall spend a character's action point when that character uses an AP Ability. | Must | Enforces action economy. | BR-011 |
| FR-026 | The system shall prevent characters with zero action points from taking standard actions. | Must | Preserves turn clarity and rules consistency. | PRD-FR-003 |
| FR-027 | The system should support effects that grant bonus movement, reaction actions, or action point recovery. | Should | Supports printed card abilities and future content. | PRD section 12 |
| FR-028 | The system shall support pass and end-turn behavior. | Must | Allows turn completion when no actions remain or player chooses to stop. | PRD-FR-003 |
| FR-029 | The system should resolve end-of-turn effects after the active player ends. | Should | Supports events and future status effects. | PRD section 11 |

### 10.4 Combat

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-030 | The system shall store HP, ATK, MOVE, RANGE, type, culture, level, and ability data for each character. | Must | Required for all unit interactions. | PRD section 8 |
| FR-031 | The system shall calculate valid attack targets using character RANGE and attack pattern rules. | Must | Enables legal combat. | PRD-FR-003 |
| FR-032 | The system shall apply basic attack damage using character ATK. | Must | Implements core combat resolution. | PRD section 8 |
| FR-033 | The system shall reduce character HP when damage is applied. | Must | Implements defeat and survival state. | PRD section 8 |
| FR-034 | The system shall defeat and remove or mark characters when HP reaches zero. | Must | Required for army defeat and Spirit Ember rules. | PRD-FR-004, PRD-FR-007 |
| FR-035 | The system should support shields and damage prevention. | Should | Required by Atlantean and relic effects. | PRD section 8 |
| FR-036 | The system should support push, pull, displacement, and movement-stopping effects. | Should | Required by Pounce, Psychic Undertow, frost, and future effects. | PRD section 9 |
| FR-037 | The system should support range modifiers. | Should | Required by relics/events and support abilities. | PRD section 9 |
| FR-038 | The system should support damage reduction, redirection, and counter-damage. | Should | Required by Resonance Guard and defensive mechanics. | PRD section 8 |
| FR-039 | The system shall support orthogonal line-of-sight attacks as the default attack pattern. | Must | Establishes baseline combat readability. | BR-025 |
| FR-040 | The system should support special attack patterns when card rules define them. | Should | Enables future card variety. | BR-026 |

### 10.5 Character Abilities

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-041 | The system shall support printed character abilities. | Must | Cards are central to character identity. | PRD-FR-003 |
| FR-042 | The system shall distinguish Passive, AP Ability, and Activated timing labels in rules and UI. | Must | Prevents AP and timing confusion. | BR-012, BR-013 |
| FR-043 | The system shall support movement abilities such as Vault and Glide. | Must | Required by prototype cards. | PRD section 8 |
| FR-044 | The system shall support offensive abilities such as Chill, Pounce, and Mark Target. | Must | Required by prototype cards. | PRD section 8 |
| FR-045 | The system shall support defensive abilities such as Quartz Armor, Resonance Shield, Heroic Guard, and Last Oath. | Must | Required by prototype cards. | PRD section 8 |
| FR-046 | The system shall support support abilities such as Command, Link Mind, and Foresight. | Must | Required by prototype cards. | PRD section 8 |
| FR-047 | The system should support placeable objects such as barricades and quartz pylons. | Should | Required for Specialist identity and future boards. | PRD section 8 |
| FR-048 | The system should support once-per-turn and once-per-match limits. | Should | Required by Level 3 and special effects. | PRD section 8 |
| FR-049 | The system shall show ability range and legal targets before confirmation. | Must | Supports mobile UX and error prevention. | PRD-NFR-002 |
| FR-050 | The system should require confirmation before irreversible ability use. | Should | Reduces accidental actions. | PRD section 16 |

### 10.6 Mounted Pair System

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-051 | The system shall allow an eligible Hero or Leader to mount an adjacent allied Mount by spending an action. | Must | Required by mounted character rules. | BR-027 |
| FR-052 | The system shall represent a mounted pair as occupying one board tile. | Must | Prevents ambiguous board occupancy. | BR-028 |
| FR-053 | The system shall use the rider's HP, ATK, RANGE, level, and abilities while mounted. | Must | Implements mounted stat inheritance. | BR-029 |
| FR-054 | The system shall use the Mount's MOVE and movement pattern while mounted. | Must | Implements mounted mobility. | BR-029 |
| FR-055 | The system shall prevent a Mount from acting separately while mounted. | Must | Enforces mounted action economy. | BR-030 |
| FR-056 | The system shall defeat both rider and Mount when the mounted rider's HP reaches 0. | Must | Implements mounted defeat rule. | BR-031 |
| FR-057 | The system shall allow dismounting as an action only when a valid adjacent empty tile exists. | Must | Prevents illegal board states. | BR-032 |

### 10.7 Character Leveling And Defeat Trophies

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-058 | The system shall track each character's current level from 1 to 3. | Must | Required for match progression. | PRD-FR-006, PRD-FR-007 |
| FR-059 | The system shall detect when a Level 1 character reaches the opponent's board edge. | Must | Required for Level 2 progression. | BR-014 |
| FR-060 | The system shall level up a character to Level 2 when it reaches the opponent's board edge. | Must | Implements first progression objective. | BR-014 |
| FR-061 | The system shall support Spirit Ember acquisition by a Level 2 character. | Must | Required for Level 3 progression. | BR-015 |
| FR-062 | The system shall detect when a Level 2 character carrying a Spirit Ember reaches the center square. | Must | Required for Level 3 progression. | PRD-FR-007 |
| FR-063 | The system shall level up a qualifying character to Level 3 at the center square. | Must | Implements second progression objective. | PRD-FR-007 |
| FR-064 | The system shall apply Level 2 and Level 3 upgrades to character rules. | Must | Makes progression meaningful. | PRD section 14 |
| FR-065 | The system shall prevent character levels from exceeding 3. | Must | Preserves rules bounds. | PRD section 14 |
| FR-066 | The system shall reset match-based levels after a match ends. | Must | Preserves fair match starts. | BR-016 |
| FR-067 | The system shall visually communicate character level, Spirit Ember state, and upgraded rules. | Must | Supports comprehension and mobile readability. | PRD-NFR-002 |

### 10.8 Relic And Event System

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-068 | The system shall maintain a shared relic/event deck used by both players. | Must | Implements the shared non-character deck. | BR-019 |
| FR-069 | The system shall draw one shared relic/event card each turn for the active player. | Must | Creates turn-to-turn board variation. | BR-020 |
| FR-070 | The system shall distinguish persistent relic effects from temporary event effects. | Must | Prevents slot and duration confusion. | BR-021, BR-023 |
| FR-071 | The system shall apply shared relic/event effects to the board state. | Must | Makes draws tactically meaningful. | PRD-FR-005 |
| FR-072 | The system shall enforce one active relic slot per player. | Must | Implements relic business rule. | BR-021 |
| FR-073 | The system shall allow a player drawing a new relic to replace or ignore/discard it when their relic slot is full. | Must | Implements relic replacement choice. | BR-022 |
| FR-074 | The system shall display active relics for each player. | Must | Supports state visibility. | PRD-NFR-002 |
| FR-075 | The system shall display the current or most recent event separately from player relic slots. | Must | Prevents event/relic confusion. | BR-023 |
| FR-076 | The system should support previewing, keeping, or bottom-decking the next relic/event card when an ability allows it. | Should | Required by Foresight and Dream Of The Deep City. | PRD section 9 |

### 10.9 Victory And Match End

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-077 | The system shall detect when a Hero is captured or defeated. | Must | Required for primary victory condition. | BR-017 |
| FR-078 | The system shall immediately end the match when a Hero capture victory occurs. | Must | Supports chess-like clarity. | BR-017 |
| FR-079 | The system shall detect when all characters on one side are defeated. | Must | Required for army defeat victory. | BR-018 |
| FR-080 | The system shall end the match when army defeat victory occurs. | Must | Prevents stale end states. | BR-018 |
| FR-081 | The system shall show victory and defeat states. | Must | Required for match completion. | PRD-FR-004 |
| FR-082 | The system should record the winning condition for playtest notes or analytics. | Should | Supports success metrics and balance review. | SM-004, SM-008 |

### 10.10 User Interface And UX

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-083 | The system shall support tap-friendly character selection on mobile screens. | Must | Required for mobile-first play. | PRD-NFR-002 |
| FR-084 | The system shall support character inspection including stats, level, HP, AP, abilities, Spirit Ember state, mounted state, and status effects. | Must | Required for readable tactical decisions. | PRD-FR-008 |
| FR-085 | The system shall highlight legal moves, attack ranges, ability ranges, and danger zones. | Must | Supports tactical clarity. | PRD-NFR-002 |
| FR-086 | The system shall show whose turn it is. | Must | Required for turn comprehension. | PRD-FR-003 |
| FR-087 | The system shall show which characters still have action points. | Must | Required for action economy clarity. | PRD-FR-008 |
| FR-088 | The system shall show active relic and event effects. | Must | Prevents hidden state. | PRD-FR-008 |
| FR-089 | The system shall provide clear end-turn controls. | Must | Required for turn completion. | PRD-FR-003 |
| FR-090 | The system shall avoid hiding critical board state behind menus. | Must | Supports mobile readability. | PRD-NFR-002 |
| FR-091 | The system should support undo or confirmation for selected irreversible actions during prototype testing. | Should | Reduces accidental moves during learning. | PRD section 16 |
| FR-092 | The digital tabletop prototype should support manually placed board objects or markers for pylons, barricades, trophies, and playtest notation. | Should | Helps test rules before full implementation. | PRD section 10 |

### 10.11 Progression And Fairness

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-093 | The system shall not require paid unlocks for gameplay power. | Must | Protects competitive trust. | PRD-NFR-003 |
| FR-094 | The system shall keep character cards mechanically consistent for all players in competitive modes. | Must | Prevents pay-to-win or grind-to-win advantage. | PRD-NFR-003 |
| FR-095 | The system should support cosmetic progression such as skins, alternate art, titles, banners, or board skins. | Should | Provides non-power rewards. | PRD section 14 |
| FR-096 | The system should support culture mastery progression without changing competitive power. | Should | Supports replay and identity safely. | PRD section 14 |
| FR-097 | The system could support ranked progression in a future mode without gameplay stat advantages. | Could | Supports future competitive roadmap. | PRD section 15 |

### 10.12 Content Management And Expansion

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-098 | The system shall store character data in a format that can be edited without rewriting game logic. | Must | Enables tuning and future content. | PRD-FR-009 |
| FR-099 | The system shall store relic/event card data in a format that can be edited without rewriting game logic. | Must | Enables tuning and future content. | PRD-FR-009 |
| FR-100 | The content model shall support future cultures with seven character types each. | Should | Supports expansion path. | PRD-GOAL-002 |
| FR-101 | The content model should support three sub-areas per faction, each with seven character types plus relics and events. | Should | Supports the story/content framework. | PRD-FR-009 |
| FR-102 | The system shall support balancing stats and abilities across paper and digital prototypes. | Must | Required for iterative tuning. | PRD-RISK-002 |
| FR-103 | The system should support internal debug visibility for board state, action points, HP, levels, trophies, mounted state, and active effects. | Should | Supports playtest diagnosis. | PRD-FR-008 |

### 10.13 Godot Prototype

| ID | Requirement | Priority | Rationale | Source |
| --- | --- | --- | --- | --- |
| FR-104 | The first software prototype shall be built in Godot. | Must | Aligns technical direction with scope. | CON-005 |
| FR-105 | The Godot prototype shall implement the board/grid engine. | Must | Core digital rules requirement. | PRD-MILESTONE-002 |
| FR-106 | The Godot prototype shall implement the turn manager. | Must | Core digital rules requirement. | PRD-MILESTONE-002 |
| FR-107 | The Godot prototype shall implement character movement, attacks, abilities, level-ups, trophies, and win/loss checks. | Must | Core digital rules requirement. | PRD-MILESTONE-002 |
| FR-108 | The Godot prototype shall use placeholder art until core rules are validated. | Must | Maintains velocity. | AS-007 |
| FR-109 | The Godot prototype shall support local hotseat play before networked play. | Must | Reduces early complexity. | CON-006 |

## 11. Non-Functional Requirements

### 11.1 Performance

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| NFR-001 | The mobile prototype should maintain smooth interaction on target test devices. | Must | PRD-NFR-002 |
| NFR-002 | Board selection, movement highlighting, and target highlighting should respond within 100 ms on target devices. | Should | Inference from tactical clarity |
| NFR-003 | Turn transitions should complete without noticeable delay except for intentional animations. | Should | PRD section 16 |
| NFR-004 | The game should avoid long animations that slow repeated tactical play. | Must | PRD section 16 |

### 11.2 Usability

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| NFR-005 | The board and characters must remain readable on small mobile screens. | Must | PRD-NFR-002 |
| NFR-006 | Card and character text must be legible without excessive zooming. | Must | PRD section 16 |
| NFR-007 | Players must be able to understand legal actions from visual feedback. | Must | SM-001 |
| NFR-008 | The UI must clearly distinguish movement, attack, ability, relic, event, Spirit Ember, mounted, HP, AP, and level states. | Must | PRD-FR-008 |
| NFR-009 | The game should minimize accidental irreversible actions through confirmation or clear input states. | Should | PRD section 16 |
| NFR-010 | Important board state should remain visible without constant menu opening. | Must | PRD-NFR-002 |

### 11.3 Balance And Fairness

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| NFR-011 | Competitive gameplay must not depend on paid power progression. | Must | PRD-NFR-003 |
| NFR-012 | Both prototype cultures should have viable paths to victory. | Must | SM-008 |
| NFR-013 | No single character should dominate the game without counterplay after tuning. | Must | PRD-RISK-002 |
| NFR-014 | Level 2 and Level 3 upgrades should reward successful advancement without making comeback impossible. | Must | PRD-RISK-006 |
| NFR-015 | Shared relic/event cards should create variety without deciding matches randomly. | Should | PRD-RISK-002 |

### 11.4 Maintainability

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| NFR-016 | Core rules should be separated from character and card data where practical. | Must | PRD-FR-009 |
| NFR-017 | Character stats and abilities should be easy to rebalance during playtesting. | Must | PRD-RISK-002 |
| NFR-018 | Future cultures and sub-areas should be addable without rewriting the board or turn systems. | Should | PRD-FR-009 |
| NFR-019 | The codebase should support automated or scripted validation of character and relic/event data where possible. | Should | Inference from content expansion needs |

### 11.5 Reliability

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| NFR-020 | The game state must remain consistent after every action. | Must | PRD-FR-003 |
| NFR-021 | Invalid moves, attacks, abilities, mount/dismount actions, Spirit Ember actions, and relic choices must be rejected. | Must | PRD-FR-003 |
| NFR-022 | The match must always be able to reach a valid end state. | Must | PRD-FR-004 |
| NFR-023 | The system should log rule errors or impossible states during prototype testing. | Should | PRD-FR-008 |

### 11.6 Accessibility

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| NFR-024 | Important state should not be communicated by color alone. | Must | PRD-NFR-002 |
| NFR-025 | Text, icons, and board highlights should maintain high contrast. | Must | PRD section 17 |
| NFR-026 | Tap targets should be large enough for mobile interaction. | Must | PRD section 16 |
| NFR-027 | Animations should not obscure critical state changes. | Should | PRD section 16 |

### 11.7 Content Quality

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| NFR-028 | Real-world-inspired cultures should be treated respectfully and avoid stereotypes. | Must | PRD-NFR-004 |
| NFR-029 | Each culture should have distinct mechanics, silhouettes, colors, and play patterns. | Should | PRD section 8 |
| NFR-030 | Each sub-area should have distinct style, mechanics, relics, events, and narrative function. | Should | PRD-GOAL-005 |
| NFR-031 | Character abilities should be concise enough to fit mobile card inspection UI. | Should | PRD section 16 |
| NFR-032 | Placeholder art must remain readable enough for playtesting. | Must | PRD section 20 |

## 12. Data And Content Requirements

### 12.1 Character Data

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| DR-001 | Each character record shall include character ID, name, culture, sub-area when known, type, unique flag, and copy limit. | Must | PRD sections 7 and 8 |
| DR-002 | Each character record shall include level, HP, ATK, MOVE, RANGE, movement pattern, attack pattern, and current match state. | Must | PRD section 8 |
| DR-003 | Each character record shall include Level 1 ability text, ability timing type, rules data, Level 2 upgrade, and Level 3 upgrade. | Must | PRD section 8 |
| DR-004 | Each character record should include art reference, icon reference, animation reference, and audio reference when available. | Should | PRD sections 17 and 18 |
| DR-005 | Character data shall support mounted pair state, action point state, Spirit Ember state, defeated state, and active status effects. | Must | FR-051 through FR-067 |

### 12.2 Match Data

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| DR-006 | Each match record shall track player cultures, starting board layout, character positions, HP, levels, mounted state, Spirit Ember state, action points, and current player. | Must | PRD-FR-008 |
| DR-007 | Each match record shall track active relics, current or recent event effects, shared deck order, turn number, defeated characters, and victory condition. | Must | PRD-FR-005, PRD-FR-004 |
| DR-008 | Each match record should track playtest notes, observed confusion points, match length, and replay interest during prototype testing. | Should | SM-001 through SM-006 |

### 12.3 Relic/Event Data

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| DR-009 | Each relic/event record shall include card ID, name, culture theme, sub-area when known, type, duration, trigger timing, effect rules, and UI text. | Must | PRD section 9 |
| DR-010 | Each relic/event record should include visual and audio references when available. | Should | PRD sections 17 and 18 |
| DR-011 | Relic/event data shall support shared-deck use by both players rather than private culture decks for the prototype. | Must | BR-019 |

### 12.4 Content Requirements

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| CR-001 | The paper prototype shall include 14 character cards: seven Russian-inspired and seven Atlantean. | Must | PRD section 20 |
| CR-002 | The paper prototype shall include 10-20 starter shared relic/event cards. | Must | PRD section 20 |
| CR-003 | The first content set shall include Russian-inspired Winter Front, Far North, and Closed City sub-area notes. | Should | PRD section 8 |
| CR-004 | The first content set shall include Atlantean First Mind, Crystal Dominion, and Flood Survivors sub-area notes. | Should | PRD section 8 |
| CR-005 | Future MVP content shall support at least four cultures, 28+ character cards, and 40+ shared relic/event cards. | Should | PRD section 21 |
| CR-006 | Content naming and tone shall use `Spirit Ember` for Level 3 progression and avoid darker body-part language. | Must | PRD-RISK-006 |

## 13. Analytics And Reporting Requirements

| ID | Requirement | Priority | Source |
| --- | --- | --- | --- |
| AR-001 | The digital prototype should record match length. | Should | SM-002, SM-003 |
| AR-002 | The digital prototype should record victory condition. | Should | SM-004 |
| AR-003 | The digital prototype should record faction/culture selected. | Should | SM-005 |
| AR-004 | The digital prototype should record turn count and action counts by action type. | Should | SM-004 |
| AR-005 | The digital prototype should record character level-up events and Spirit Ember delivery events. | Should | PRD-FR-006, PRD-FR-007 |
| AR-006 | The digital prototype should record relic/event draws and replacements. | Should | PRD-FR-005 |
| AR-007 | Playtest reporting should capture comprehension time, replay interest, confusing rules, dominant cards, and perceived faction distinction. | Must | SM-001 through SM-008 |

## 14. Acceptance Criteria

| ID | Criterion | Applies To | Source |
| --- | --- | --- | --- |
| AC-001 | Both prototype cultures can complete a legal match using documented rules. | Paper Prototype | PRD-MILESTONE-001 |
| AC-002 | New playtesters can identify legal movement and attack targets within 2 minutes. | Paper Prototype | SM-001 |
| AC-003 | Hero capture and army defeat victories can both occur during testing. | Paper Prototype | PRD-FR-004 |
| AC-004 | At least one character levels to Level 2 in some test matches. | Paper Prototype | PRD-FR-006 |
| AC-005 | Level 3 Spirit Ember rules can be explained and tested, or PRD-OQ-008 is explicitly resolved before digital implementation. | Paper Prototype | PRD-FR-007 |
| AC-006 | Shared relic/event draws affect decisions without dominating the match. | Paper Prototype | PRD-FR-005 |
| AC-007 | Playtest notes identify balance issues for characters, cultures, relics, events, and Level 3 progression. | Paper Prototype | SM-008 |
| AC-008 | A local digital match can be completed from setup to victory. | Digital Rules Prototype | PRD-MILESTONE-002 |
| AC-009 | All 14 prototype character cards are represented with their stats, levels, abilities, and culture identity. | Digital Rules Prototype | PRD-FR-002 |
| AC-010 | Movement, attacks, action points, mount/dismount, level-ups, Spirit Ember flow, relic/event draws, and victory checks work. | Digital Rules Prototype | PRD-FR-003 through PRD-FR-007 |
| AC-011 | The UI communicates turn, selected character, legal actions, HP, AP, level, Spirit Ember state, mounted state, and active relic/event effects. | Digital Rules Prototype | PRD-FR-008 |
| AC-012 | Placeholder art and tokens are clear enough for playtesting. | Digital Rules Prototype | PRD section 20 |
| AC-013 | Mobile UX testing demonstrates readable board state and unit inspection on phone-sized screens. | Mobile UX Prototype | PRD-NFR-002 |
| AC-014 | Content prototype testing demonstrates that the two cultures feel meaningfully different. | Content Prototype | SM-005 |
| AC-015 | MVP planning produces an updated PRD, BRD, technical design document, art bible, production backlog, and MVP estimate. | MVP Planning | PRD-MILESTONE-005 |

## 15. Dependencies

| ID | Dependency | Blocking Area | Source |
| --- | --- | --- | --- |
| DEP-001 | Exact 7x7 starting formation. | Paper prototype, digital setup presets | PRD-OQ-002 |
| DEP-002 | Decision on portrait, landscape, or both. | Mobile UX prototype | PRD-OQ-001 |
| DEP-003 | Decision on unit defeat persistence, revival, or return behavior. | Combat, victory pacing, relic/event design | PRD-OQ-003 |
| DEP-004 | Decision on culture naming strategy. | Art, narrative, sensitivity review | PRD-OQ-004 |
| DEP-005 | Decision on final tone and content rating target. | Art, narrative, Spirit Ember framing | PRD-OQ-005 |
| DEP-006 | Starter shared relic/event card count. | Paper prototype content | PRD-OQ-006 |
| DEP-007 | Closed City scientist story role. | Narrative framing, tutorial voice | PRD-OQ-007 |
| DEP-008 | Spirit Ember representation decision. | Level 3 rules, UI, implementation | PRD-OQ-008 |
| DEP-009 | Spirit Ember language and darkness level decision. | Tone, localization, platform review | PRD-OQ-009 |
| DEP-010 | Paper prototype materials or spreadsheet. | Milestone 1 | PRD-MILESTONE-001 |
| DEP-011 | Godot installed and configured. | Digital rules prototype | PRD-MILESTONE-002 |
| DEP-012 | Placeholder art or readable tokens. | Digital rules prototype, mobile UX | PRD-MILESTONE-002 |
| DEP-013 | Playtest feedback from at least 3-5 matches. | Balance revision, MVP planning | SM-002, SM-008 |

## 16. Risks And Mitigations

| ID | Risk | Impact | Mitigation | Source |
| --- | --- | --- | --- | --- |
| R-001 | Rules become too complex. | Players may abandon the game early or fail to understand legal actions. | Prototype with minimal mechanics first and simplify after playtests. | PRD-RISK-001 |
| R-002 | Card balance becomes unmanageable. | A few cards or strategies may dominate and reduce replay value. | Build internal card data tools and track balance notes early. | PRD-RISK-002 |
| R-003 | Board plus cards overwhelms mobile UI. | Players may misread board state or make accidental actions. | Test on phone-sized screens from the start. | PRD-RISK-003 |
| R-004 | Cultures feel cosmetic only. | The core fantasy and replay promise weakens. | Give each culture mechanical identity, distinct visuals, and clear play patterns. | PRD-RISK-004 |
| R-005 | Sub-areas feel cosmetic only. | Long-term content structure may feel arbitrary. | Give each sub-area its own style, mechanics, relics, events, and narrative function. | PRD-RISK-005 |
| R-006 | Level 3 Spirit Ember objective is misunderstood. | Players may miss why defeated enemies release embers or how delivery works. | Test terminology and UI; represent Spirit Ember as a status/counter on the carrying character. | PRD-RISK-006 |
| R-007 | Multiplayer is expensive and slow. | Delivery velocity may stall before core fun is proven. | Start with local and AI matches. | PRD-RISK-007 |
| R-008 | Scope grows too quickly. | Prototype may become too large to finish or learn from. | Lock prototype scope before production. | PRD-RISK-008 |
| R-009 | Real-world-inspired content is perceived as shallow or stereotyped. | Brand and player trust risk. | Use respectful research, fantasy framing, and review culture-specific content before production. | PRD-NFR-004 |
| R-010 | Shared relic/events create too much randomness. | Strategy may feel unfair. | Keep effects tactical, readable, and bounded; track impact in playtests. | PRD-FR-005 |

## 17. Traceability Matrix

| PRD Source | BRD Mapping |
| --- | --- |
| PRD-GOAL-001 | BO-001, SM-001, SM-004, FR-010 through FR-092, NFR-001 through NFR-027 |
| PRD-GOAL-002 | BO-002, FR-001 through FR-006, FR-098 through FR-101, CR-001, CR-005 |
| PRD-GOAL-003 | BO-003, SM-002, SM-003, NFR-001 through NFR-004, AR-001 |
| PRD-GOAL-004 | BO-004, FR-068 through FR-076, FR-098 through FR-103, DR-009 through DR-011 |
| PRD-GOAL-005 | BO-005, CR-003, CR-004, NFR-028 through NFR-030, R-009 |
| PRD-GOAL-006 | BO-006, FR-093 through FR-097, FR-104 through FR-109 |
| PRD-FR-001 | CON-001, FR-010, FR-011 |
| PRD-FR-002 | CON-002, FR-001 through FR-006, CR-001 |
| PRD-FR-003 | FR-020 through FR-050, NFR-020, NFR-021 |
| PRD-FR-004 | BR-017, BR-018, FR-077 through FR-082, AC-003 |
| PRD-FR-005 | BR-019 through BR-023, FR-068 through FR-076, DR-009 through DR-011 |
| PRD-FR-006 | BR-014, FR-058 through FR-060, AC-004 |
| PRD-FR-007 | BR-015, FR-061 through FR-063, AC-005 |
| PRD-FR-008 | FR-083 through FR-092, DR-006 through DR-008, AC-011 |
| PRD-FR-009 | BO-004, BO-005, FR-098 through FR-103, CR-003 through CR-005 |
| PRD-FR-010 | FR-093 through FR-109, CR-005, AR-001 through AR-007 |
| PRD-NFR-001 | SM-002, SM-003, NFR-001 through NFR-004 |
| PRD-NFR-002 | FR-083 through FR-092, NFR-005 through NFR-010, NFR-024 through NFR-027 |
| PRD-NFR-003 | BO-007, BR-033, BR-034, FR-093 through FR-097, NFR-011 |
| PRD-NFR-004 | CON-008, NFR-028, R-009 |
| PRD-SM-001 through PRD-SM-007 | SM-001 through SM-007, AR-001 through AR-007, AC-001 through AC-015 |
| PRD-RISK-001 through PRD-RISK-008 | R-001 through R-008 |
| PRD-OQ-001 through PRD-OQ-009 | DEP-001 through DEP-009, OQ-001 through OQ-009 |
| PRD-MILESTONE-001 | AC-001 through AC-007, DEP-010 |
| PRD-MILESTONE-002 | FR-104 through FR-109, AC-008 through AC-012, DEP-011, DEP-012 |
| PRD-MILESTONE-003 | FR-083 through FR-092, AC-013 |
| PRD-MILESTONE-004 | SM-005, SM-008, AC-014 |
| PRD-MILESTONE-005 | AC-015 |

## 18. Open Questions

| ID | Question | Decision Impact | Source |
| --- | --- | --- | --- |
| OQ-001 | Is the game portrait, landscape, or both? | Determines board layout, card inspection, and mobile UI constraints. | PRD-OQ-001 |
| OQ-002 | What exact 7x7 starting formation should the 14 characters use? | Blocks stable paper prototype setup and first digital board presets. | PRD-OQ-002 |
| OQ-003 | Are units permanently defeated, revived, or returned to hand? | Affects victory pacing, comeback mechanics, and event/relic design. | PRD-OQ-003 |
| OQ-004 | Should cultures be historically named, myth-inspired, or fully fictional? | Affects naming, research burden, audience expectations, and sensitivity review. | PRD-OQ-004 |
| OQ-005 | Is the tone serious, stylized, heroic, dark, or family-friendly? | Affects art direction, Spirit Ember framing, story presentation, and content rating. | PRD-OQ-005 |
| OQ-006 | How many shared relic/event cards should be in the first paper prototype? | Determines prototype content workload and event frequency. | PRD-OQ-006 |
| OQ-007 | What exact story role does the Closed City scientist play? | Determines campaign framing, tutorial voice, and long-term narrative structure. | PRD-OQ-007 |
| OQ-008 | Resolved: Spirit Ember is represented as a status/counter on the carrying character. | Affects rules clarity, UI, and implementation complexity. | PRD-OQ-008 |
| OQ-009 | Resolved: use Spirit Ember only; do not use darker body-part language in product or prototype notes. | Affects tone, audience fit, localization, and platform/content review. | PRD-OQ-009 |

## 19. Next Steps

1. Resolve OQ-002 by choosing the exact 7x7 starting formation.
2. Resolve OQ-006 by choosing the first paper prototype shared relic/event count.
3. Resolve OQ-008 enough to paper test Level 3 progression.
4. Print or export the 14 character cards and starter shared relic/event cards.
5. Run 3-5 paper prototype matches and capture AR-007 playtest reporting.
6. Revise stats, Level 2 upgrades, Level 3 Spirit Ember rules, and shared relic/event effects from playtest results.
7. Create a technical design document for the Godot rules prototype.
8. Decompose this BRD into epics, backlog items, acceptance tests, and milestone plans.
