# MythCards Business Requirements Document

## 1. Document Purpose

This Business Requirements Document defines the business goals, scope, stakeholders, high-level capabilities, functional requirements, non-functional requirements, constraints, risks, and acceptance criteria for MythCards.

This BRD is derived from the current MythCards PRD and is intended to support planning, paper prototyping, Godot prototype development, future backlog creation, and early MVP scoping.

## 2. Product Summary

MythCards is a mobile-first, turn-based tactical card-and-board game. Players command civilization-themed character cards on a 7x7 chess-like board with one center tile. Each character begins on the board, has one action point per turn, and can move, attack, or use an ability. Players win by capturing the opponent's Hero or defeating all opposing characters.

The first prototype focuses on two civilizations:
- Russian-inspired faction: endurance, frost control, disciplined tactics, fortification, and ranged pressure.
- Atlantean faction: divine spirit leadership, quartz technology, hive-mind coordination, spiritual shields, resonance, and board manipulation.

The chosen technical framework is Godot.

## 3. Business Objectives

| ID | Objective |
| --- | --- |
| BO-001 | Create a fair, skill-based mobile tactics game with strong replay value. |
| BO-002 | Validate the core game loop through a low-cost paper prototype before software development. |
| BO-003 | Build a Godot rules prototype that proves the board, turn, action, victory, and character systems are fun. |
| BO-004 | Establish a scalable content structure for future civilizations, character variants, cosmetics, events, and modes. |
| BO-005 | Avoid pay-to-win progression by keeping gameplay access fair and using cosmetics or mastery for account progression. |
| BO-006 | Support a design path from local prototype to AI matches, casual PvP, ranked PvP, and asynchronous PvP. |

## 4. Success Metrics

| ID | Metric | Target |
| --- | --- | --- |
| SM-001 | Rule comprehension | New playtesters understand legal movement and basic actions within 2 minutes. |
| SM-002 | Match length | Paper prototype matches finish within 10-20 minutes. |
| SM-003 | Mobile match target | Future standard mobile matches should finish within 5-12 minutes. |
| SM-004 | Replay interest | Playtesters want to replay or switch factions after a match. |
| SM-005 | Faction distinction | Players can describe how Russian-inspired and Atlantean factions feel different after one match. |
| SM-006 | Balance health | Neither prototype faction should win more than 60 percent of comparable-skill paper tests after tuning. |
| SM-007 | Decision quality | Each turn should present at least one meaningful tactical decision. |

## 5. Stakeholders

| Stakeholder | Interest |
| --- | --- |
| Game Designer | Defines rules, characters, factions, balance, and progression. |
| Developer | Implements the Godot prototype and future mobile systems. |
| Artist/UI Designer | Creates card frames, board visuals, icons, faction identity, and mobile screens. |
| Playtesters | Validate fun, clarity, balance, and pacing. |
| Future Players | Need fair, readable, rewarding tactical gameplay. |
| Business/Product Owner | Decides scope, monetization model, roadmap, and release priorities. |

## 6. Scope

### 6.1 Prototype Scope

The first prototype must include:
- 7x7 board with one center tile.
- Two playable factions.
- Fourteen character cards total.
- One copy of each character card per side for the first paper prototype.
- Three character levels per character.
- Character level-up by reaching the opponent's board edge.
- One action point per character per turn.
- Movement, attack, ability, mount, and dismount actions.
- Shared relic/event deck.
- One shared relic/event draw each turn for the active player.
- Hero capture and army defeat victory conditions.
- Local hotseat play or a simple AI in the first digital prototype.
- Godot as the prototype engine.

### 6.2 MVP Scope

The MVP should include:
- Tutorial.
- AI opponent.
- Casual PvP.
- Squad viewer or cosmetic loadout.
- Collection screen.
- Four cultures.
- Seven character types per culture.
- At least 28 character cards.
- At least 40 shared relic/event cards.
- Cosmetic and mastery progression.
- Mobile-ready UI.
- Analytics events.
- Local save data.
- Internal balancing tools.

### 6.3 Out Of Scope For Prototype

- Real-money monetization.
- Ranked ladder.
- Large campaign.
- Full live operations system.
- Complex multiplayer infrastructure.
- Large-scale collection system.
- Pay-to-win progression.

## 7. Assumptions

| ID | Assumption |
| --- | --- |
| AS-001 | The first prototype will be validated on paper before Godot development begins. |
| AS-002 | The first software prototype will prioritize game rules over final art, monetization, or networking. |
| AS-003 | Players begin with all character cards placed on the board. |
| AS-004 | Character cards do not have costs. |
| AS-005 | Gameplay progression must not require paid unlocks or stronger cards. |
| AS-006 | Cosmetic progression is acceptable if it does not affect match outcomes. |
| AS-007 | The first digital prototype can use placeholder art. |
| AS-008 | The initial board is a 7x7 grid with orthogonal movement and attack patterns unless a character, relic, event, or future card states otherwise. |

## 8. Business Rules

| ID | Rule |
| --- | --- |
| BR-001 | Each side may field only one Hero. |
| BR-002 | Each side may field only one Leader. |
| BR-003 | Each side may field up to two copies of each non-common, non-unique type: Mount, Warrior, Specialist, and Mystic. |
| BR-004 | Common characters may be used in larger numbers if future squad sizes require filler units. |
| BR-005 | For the current paper prototype, each side uses one copy of each of its seven character type cards on a 7x7 board. |
| BR-006 | Character cards begin on the board at match start. |
| BR-007 | Character cards have no deployment cost. |
| BR-008 | Each character refreshes to one action point at the start of its controller's turn. |
| BR-009 | Movement consumes that character's action point. |
| BR-010 | Attacking consumes that character's action point. |
| BR-011 | Using an ability consumes that character's action point unless the ability explicitly says otherwise. |
| BR-012 | A character levels up by reaching the opponent's edge of the board. |
| BR-013 | Each character has three levels. |
| BR-014 | Level-ups are match-based and reset unless a future mode states otherwise. |
| BR-015 | A player wins immediately by capturing the opposing Hero. |
| BR-016 | A player wins by defeating all opposing characters. |
| BR-017 | Relic and event cards are mixed into one shared non-character deck. |
| BR-018 | One shared relic/event card is drawn each turn for the active player. |
| BR-019 | Competitive progression must preserve fair access to gameplay power. |
| BR-020 | Account unlocks should be cosmetic, mastery-based, or non-gameplay-affecting. |
| BR-021 | Default movement pattern is orthogonal: vertical and horizontal movement only. |
| BR-022 | Default attack pattern is orthogonal line-of-sight: vertical and horizontal only. |
| BR-023 | Diagonal, area, jump, teleport, or unusual patterns require explicit special rules. |
| BR-024 | A Hero or Leader may mount an allied Mount as an action if adjacent to that Mount. |
| BR-025 | A mounted Hero or Leader occupies the same tile as the Mount. |
| BR-026 | A mounted pair uses the Hero or Leader's HP, ATK, RANGE, level, and abilities, but uses the Mount's MOVE and movement pattern. |
| BR-027 | A Mount cannot take separate actions while carrying a Hero or Leader. |
| BR-028 | When a mounted Hero or Leader reaches 0 HP, both the rider and Mount are defeated. |
| BR-029 | Dismounting is an action and requires an adjacent empty tile for the Mount or rider separation. |
| BR-030 | Each player may have only one active relic at a time. |
| BR-031 | If a player draws a relic while they already have an active relic, they may replace the active relic or discard/ignore the newly drawn relic. |
| BR-032 | Event cards do not occupy relic slots and resolve according to their printed duration. |

## 9. Functional Requirements

### 9.1 Match Setup

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-001 | The system shall allow a player to select a playable faction. | Must |
| FR-002 | The system shall support at least two prototype factions: Russian-inspired and Atlantean. | Must |
| FR-003 | The system shall load a fixed starting squad for each faction. | Must |
| FR-004 | The system shall enforce one Hero per side. | Must |
| FR-005 | The system shall enforce one Leader per side. | Must |
| FR-006 | The system shall support copy limits for non-common character types. | Should |
| FR-007 | The system shall place all selected character cards on the board at match start. | Must |
| FR-008 | The system shall support configurable starting board layouts. | Must |
| FR-009 | The system shall initialize a shared relic/event deck at match start. | Must |

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
| FR-020 | The system shall refresh each active character to one action point at the start of its controller's turn. | Must |
| FR-021 | The system shall spend a character's action point when that character moves. | Must |
| FR-022 | The system shall spend a character's action point when that character attacks. | Must |
| FR-023 | The system shall spend a character's action point when that character uses an ability. | Must |
| FR-024 | The system shall prevent a character with zero action points from taking standard actions. | Must |
| FR-025 | The system shall support effects that refresh action points. | Should |
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

### 9.5 Character Abilities

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-037 | The system shall support printed character abilities. | Must |
| FR-038 | The system shall support movement abilities such as Vault and Glide. | Must |
| FR-039 | The system shall support offensive abilities such as Chill and Pounce. | Must |
| FR-040 | The system shall support defensive abilities such as Quartz Armor and Resonance Shield. | Must |
| FR-041 | The system shall support support abilities such as Command and Link Mind. | Must |
| FR-042 | The system shall support placeable objects such as barricades and quartz pylons. | Should |
| FR-043 | The system shall support once-per-turn and once-per-match ability limits. | Should |
| FR-044 | The system shall show ability range and legal targets before confirmation. | Must |
| FR-045 | The system shall require confirmation before irreversible ability use. | Should |
| FR-045A | The system shall support stronger utility abilities on low-ATK characters so low-attack pieces remain strategically useful. | Must |
| FR-045I | The system shall distinguish passive abilities from AP-activated abilities in card text and UI. | Must |

### 9.5A Mounted Pair System

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-045B | The system shall allow an eligible Hero or Leader to mount an adjacent allied Mount by spending an action. | Must |
| FR-045C | The system shall represent a mounted Hero or Leader and Mount as occupying one board tile. | Must |
| FR-045D | The system shall use the rider's HP, ATK, RANGE, level, and abilities while mounted. | Must |
| FR-045E | The system shall use the Mount's MOVE and movement pattern while mounted. | Must |
| FR-045F | The system shall prevent the Mount from acting separately while mounted. | Must |
| FR-045G | The system shall defeat both rider and Mount when the mounted rider's HP reaches 0. | Must |
| FR-045H | The system shall allow dismounting as an action only when a valid adjacent empty tile exists. | Must |

### 9.6 Character Leveling

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-046 | The system shall track each character's current level from 1 to 3. | Must |
| FR-047 | The system shall detect when a character reaches the opponent's board edge. | Must |
| FR-048 | The system shall level up a character when it reaches the opponent's board edge. | Must |
| FR-049 | The system shall apply level 2 and level 3 upgrades to character rules. | Must |
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
| FR-059B | The system shall allow the active player to choose whether to replace their current relic when drawing a new relic. | Must |
| FR-059C | The system shall display the currently drawn or active event separately from player relic slots. | Must |

### 9.8 Victory And Match End

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-060 | The system shall detect when a Hero is captured or defeated. | Must |
| FR-061 | The system shall immediately end the match when a Hero capture victory occurs. | Must |
| FR-062 | The system shall detect when all characters on one side are defeated. | Must |
| FR-063 | The system shall end the match when army defeat victory occurs. | Must |
| FR-064 | The system shall show victory and defeat states. | Must |
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
| FR-080 | The system shall store character data in a format that can be edited without rewriting game logic. | Must |
| FR-081 | The system shall store relic/event card data in a format that can be edited without rewriting game logic. | Must |
| FR-082 | The system shall support adding future cultures with seven character types each. | Should |
| FR-083 | The system shall support balancing stats and abilities across paper and digital prototypes. | Must |
| FR-084 | The system shall support internal debug visibility for board state, action points, HP, and active effects. | Should |

### 9.12 Godot Prototype

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-085 | The first software prototype shall be built in Godot. | Must |
| FR-086 | The Godot prototype shall implement the board/grid engine. | Must |
| FR-087 | The Godot prototype shall implement the turn manager. | Must |
| FR-088 | The Godot prototype shall implement character movement, attacks, abilities, level-ups, and win/loss checks. | Must |
| FR-089 | The Godot prototype shall use placeholder art until core rules are validated. | Must |
| FR-090 | The Godot prototype shall support local hotseat play before networked play. | Must |

## 10. Non-Functional Requirements

### 10.1 Performance

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-001 | The mobile prototype should maintain smooth interaction on target test devices. | Must |
| NFR-002 | Board selection, movement highlighting, and target highlighting should respond within 100 ms on target devices. | Should |
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

### 10.3 Balance And Fairness

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-010 | Competitive gameplay must not depend on paid power progression. | Must |
| NFR-011 | Both prototype factions should have viable paths to victory. | Must |
| NFR-012 | No single character should dominate the game without counterplay after tuning. | Must |
| NFR-013 | Level 2 and Level 3 upgrades should reward successful advancement without making comeback impossible. | Must |
| NFR-014 | Shared relic/event cards should create variety without deciding matches randomly. | Should |

### 10.4 Maintainability

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-015 | Core rules should be separated from character and card data where practical. | Must |
| NFR-016 | Character stats and abilities should be easy to rebalance during playtesting. | Must |
| NFR-017 | Future cultures should be addable without rewriting the board or turn systems. | Should |
| NFR-018 | The codebase should support automated or scripted validation of character data where possible. | Should |

### 10.5 Reliability

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-019 | The game state must remain consistent after every action. | Must |
| NFR-020 | Invalid moves, attacks, and ability targets must be rejected. | Must |
| NFR-021 | The match must always be able to reach a valid end state. | Must |
| NFR-022 | The system should log rule errors or impossible states during prototype testing. | Should |

### 10.6 Accessibility

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-023 | Important state should not be communicated by color alone. | Must |
| NFR-024 | Text, icons, and board highlights should maintain high contrast. | Must |
| NFR-025 | Tap targets should be large enough for mobile interaction. | Must |
| NFR-026 | Animations should not obscure critical state changes. | Should |

### 10.7 Platform And Technical

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-027 | The prototype shall be developed in Godot. | Must |
| NFR-028 | The game should be designed mobile-first. | Must |
| NFR-029 | The architecture should not depend on networking for the first prototype. | Must |
| NFR-030 | The prototype should be structured so AI and PvP can be added later. | Should |

### 10.8 Content Quality

| ID | Requirement | Priority |
| --- | --- | --- |
| NFR-031 | Real-world-inspired cultures should be treated respectfully and avoid stereotypes. | Must |
| NFR-032 | Each culture should have distinct mechanics, silhouettes, colors, and play patterns. | Should |
| NFR-033 | Character abilities should be concise enough to fit mobile card inspection UI. | Should |
| NFR-034 | Placeholder art must remain readable enough for playtesting. | Must |

## 11. Data Requirements

### 11.1 Character Data

Each character record should include:
- Character ID.
- Name.
- Culture.
- Type.
- Unique flag.
- Copy limit.
- Level.
- HP.
- ATK.
- MOVE.
- RANGE.
- Movement pattern.
- Attack pattern.
- Ability text.
- Ability timing type: passive or AP ability.
- Ability rules data.
- Level 2 upgrade.
- Level 3 upgrade.
- Art reference.
- Icon reference.

### 11.2 Match Data

Each match record should track:
- Player factions.
- Starting board layout.
- Character positions.
- Character HP.
- Character levels.
- Mounted pair state.
- Action point state.
- Active relic for each player.
- Active or most recent event effects.
- Shared relic/event deck order.
- Turn number.
- Current player.
- Defeated characters.
- Victory condition.

### 11.3 Relic/Event Data

Each relic/event record should include:
- Card ID.
- Name.
- Type: relic or event.
- Duration.
- Trigger timing.
- Effect rules.
- UI text.
- Visual/audio references.

## 12. Initial Character Card Inventory

### 12.1 Russian-Inspired

| Character | Type | HP | ATK | MOVE | RANGE |
| --- | --- | ---: | ---: | ---: | ---: |
| Gymnast | Common | 2 | 1 | 3 | 1 |
| White Siberian Tiger | Mount | 4 | 2 | 4 | 1 |
| Sniper | Warrior | 3 | 2 | 2 | 4 |
| Army General | Leader | 5 | 1 | 2 | 1 |
| Bogatyr Champion | Hero | 6 | 2 | 2 | 1 |
| Winter Engineer | Specialist | 3 | 1 | 2 | 1 |
| Frost Seer | Mystic | 3 | 1 | 2 | 3 |

### 12.2 Atlantean

| Character | Type | HP | ATK | MOVE | RANGE |
| --- | --- | ---: | ---: | ---: | ---: |
| Quartz Attendant | Common | 2 | 1 | 2 | 1 |
| Manta Glider | Mount | 3 | 1 | 4 | 1 |
| Resonance Guard | Warrior | 5 | 1 | 2 | 1 |
| Divine Conductor | Leader | 4 | 1 | 2 | 3 |
| Oracle Sovereign | Hero | 5 | 1 | 2 | 3 |
| Crystal Architect | Specialist | 3 | 1 | 2 | 2 |
| Astral Harmonic | Mystic | 3 | 1 | 2 | 3 |

## 13. Initial Relic And Event Inventory

Relic and event cards are faction-themed but are mixed into one shared non-character deck used by both players. Each player may have only one active relic; drawing a new relic while one is already active allows that player to replace the old relic or ignore the new relic.

### 13.1 Russian-Inspired Relics

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Winter Palace Standard | Relic | Persistent | Your Hero and Leader each gain +1 maximum HP while this relic is active. |
| Iron Birch Talisman | Relic | Persistent | Your Common and Warrior each gain +1 maximum HP while this relic is active. |
| General's War Map | Relic | Persistent | Once each turn, one of your characters gains +1 RANGE on its next attack or ability. |

### 13.2 Russian-Inspired Events

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Whiteout | Event | 1 round | All ranged attacks and ranged abilities have -1 RANGE, minimum 1. |
| Frozen Center | Event | 1 round | The center row and center tile count as frost. A character entering frost stops moving. |
| Rally From The Snow | Event | Immediate | The active player heals 1 HP on one damaged character. |
| Long Winter March | Event | 1 turn | The active player's first movement action this turn gains +1 MOVE. |

### 13.3 Atlantean Relics

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Quartz Heart Core | Relic | Persistent | Your shields prevent +1 additional damage while this relic is active. |
| Hall Of Shared Minds | Relic | Persistent | Your adjacent characters gain +1 RANGE on abilities. |
| Tideglass Obelisk | Relic | Persistent | Your characters adjacent to a placed object gain +1 RANGE on attacks and abilities. |

### 13.4 Atlantean Events

| Card | Type | Duration | Effect |
| --- | --- | --- | --- |
| Resonance Surge | Event | 1 turn | The active player's first ability this turn has +1 RANGE. |
| Psychic Undertow | Event | 1 turn | The active player's first attack this turn may push or pull the target 1 tile. |
| Crystal Tide | Event | 1 turn | The active player's characters have +1 RANGE on abilities this turn. |
| Dream Of The Deep City | Event | Immediate | Reveal the next shared relic/event card. The active player may leave it on top or place it on the bottom of the deck. |

## 14. Risks And Mitigations

| ID | Risk | Impact | Mitigation |
| --- | --- | --- | --- |
| R-001 | Rules become too complex. | Players may abandon the game early. | Prototype with minimal rules and simplify after playtests. |
| R-002 | Shared relic/events create too much randomness. | Strategy may feel unfair. | Keep effects tactical, symmetric, and readable. |
| R-003 | Level-up by reaching the edge may create runaway advantages. | Comebacks may become rare. | Tune level bonuses and test how often level-ups occur. |
| R-004 | Hero capture may encourage overly defensive play. | Matches may stall. | Use board layout, relic/events, and army defeat victory to force engagement. |
| R-005 | Mobile board readability may suffer. | Players may misread board state. | Test on phone-sized screens early. |
| R-006 | Cultural themes may feel shallow or stereotyped. | Brand and player trust risk. | Use respectful research and fantasy framing. |
| R-007 | Godot implementation may overbuild too early. | Prototype velocity may slow. | Start with rules, placeholders, and debug UI. |

## 15. Dependencies

| ID | Dependency |
| --- | --- |
| D-001 | Final or testable starting board layout. |
| D-002 | Initial shared relic/event card list. |
| D-003 | Paper prototype materials or spreadsheet. |
| D-004 | Godot installed and configured for prototype development. |
| D-005 | Placeholder art or simple readable tokens. |
| D-006 | Playtest feedback from at least 3-5 matches. |

## 16. Acceptance Criteria

The first paper prototype is acceptable when:
- Both factions can complete a match using the documented rules.
- Players can identify legal movement and attack targets.
- Hero capture and army defeat victories can both occur.
- At least one character levels up during some matches.
- Shared relic/event draws affect decisions without dominating the match.
- Playtest notes identify balance issues for revision.

The first Godot prototype is acceptable when:
- A local match can be completed from setup to victory.
- All 14 character cards are represented with their stats.
- Movement, attacks, action points, level-ups, and victory checks work.
- A shared relic/event draw happens each turn.
- The UI communicates turn, selected character, legal actions, HP, level, and active relic/event effects.
- Placeholder art is clear enough to test the game.

## 17. Next Steps

1. Choose the exact 7x7 starting formation.
2. Print the 14 character cards and 14 shared relic/event cards.
3. Run 3-5 paper prototype matches.
4. Record balance notes for each character, faction, relic, and event.
5. Revise the character cards and requirements based on playtest results.
6. Begin the Godot rules prototype.
