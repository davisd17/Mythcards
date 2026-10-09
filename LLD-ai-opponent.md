# MythCards Low-Level Design — Opponent AI

**Document Control**

| Field | Value |
| --- | --- |
| Source | Designer request 2026-10-09 ("basic right now but built to scale into the actual game"); PRD Sections 15 (AI match, MVP), 19 (AI opponent system), 21 |
| Scope | A computer opponent for local matches: how it sees the game, chooses actions, and plugs into the game screen. One basic level now; an architecture that later supports harder levels, personalities, and lookahead search. |
| Builds on | RulesEngine (actions and legality), AbilityHandler.next_step and RelicEventDeck choice/power specs (the same targeting the screen uses), GameController (screen flow) |
| Date | 2026-10-09 |
| Status | Phase 1 implemented and tested (`test_ai_opponent.gd`, `test_game_screen.gd`, browser `screen.spec.ts`) |

## 1. Decisions (designer, 2026-10-09)

- **Match setup:** a new match offers *vs AI, you play Closed City*, *vs AI, you play Flood Survivors*, or *Hotseat* (both sides human).
- **One basic level that uses everything**: moves, attacks, abilities, free bonuses, mounting, relic powers, and drawn-card choices.

## 2. Principles (what makes it scale)

1. **It plays by the rules a player plays by.** Every AI action goes through `RulesEngine.request_action`, with the same validation, AP costs, and events as a tap. The AI never edits match state. It doesn't read hidden information: the shared deck's order stays unseen unless a card reveals it.
2. **It discovers actions generically.** Candidates come from the same queries the screen uses: legal moves and attack targets, usable abilities expanded through `AbilityHandler.next_step`, offered bonuses through `bonus_step`, and card choices through `choice_spec`/`power_spec`. A new card is playable by the AI the moment it is playable by a person.
3. **Judgment is layered and replaceable.**
   - `ActionGenerator` lists legal candidates.
   - `AIEvaluator` scores them.
   - `AIPlayer` picks one.
   - Weights live in data (`data/ai/basic.json`), so a new level or personality is a new file, not new code.
4. **Cards can teach the AI.** `AbilityHandler.ai_value(...)` lets a card estimate what one use is worth. The default works for any card; the 14 playtest cards give better estimates. Relic/event handlers can do the same for their choices (`ai_choice_value`).
5. **Deterministic.** A seeded RNG breaks ties, so a given seed replays exactly (tests, bug reports).

## 3. Components (`game/scripts/ai/`)

| Class | Responsibility |
| --- | --- |
| `AIPlayer` | Owns one side. `next_action()` returns the chosen action ({action_type, actor_id, payload, score, why}), or `end_turn`. `take_turn()` loops until the turn ends (headless, tests). `place_squad(setup)` deploys its back row. |
| `ActionGenerator` | Enumerates every legal candidate for the side to act: moves, attacks (characters and objects), abilities (each full payload, found by walking `next_step`, capped per ability), free bonuses, mount/dismount, relic powers, a pending drawn-card choice, or a required return to the board. |
| `AIEvaluator` | Scores a candidate from board features, with weights from the personality file (Section 4). Uses `CombatResolver.preview_damage`, a side-effect-free copy of the damage pipeline, for attacks. Checks moves against a cheap board probe (occupancy swapped and restored) for Hero safety. |
| `AIPersonality` | Loads `data/ai/<name>.json`: feature weights, the end-turn threshold, and the randomness. |

## 4. Phase 1 scoring (basic level)

Each candidate gets a score; the best one above `end_turn_threshold` is taken, and the AI re-plans after every action (state changes). Features, all weighted in `basic.json`:

- **Attacks:** expected damage (`preview_damage`), plus a defeat bonus scaled by the target's value (Hero, Leader, and Specialist highest), plus a Spirit Ember bonus when the attacker is Level 2.
- **Moves:** change in the mover's position value:
  - getting into attack range of the weakest reachable enemy;
  - danger: how many enemies could attack the tile next turn, scaled by how fragile the mover is;
  - reaching the opponent's edge at Level 1 (→ Level 2), and the center carrying a Spirit Ember at Level 2 (→ Level 3);
  - not ending on a Leak (unless Leak-immune).
- **Hero safety** (the capture rule): any action that would leave its own Hero with no legal move at the end of the turn is vetoed. Fewer escape tiles for the Hero cost points. Shrinking the enemy Hero's escape tiles earns points.
- **Abilities:** the card's `ai_value` estimate (damage dealt, shields or Memory where enemies threaten, Leaks and Stones near enemies, pulls, levels of control), plus the generic Hero-safety check.
- **Free bonuses** score like the action they grant (free moves as moves, free attacks as attacks).
- **Drawn-card and relic choices:** the handler's `ai_choice_value` if it has one, otherwise the first option. Revealed cards stay on top if they're from the AI's own culture, else they go to the bottom.
- **Ending the turn:** when nothing scores above the threshold, or no AP is left.

## 5. Screen integration

- The Menu's **New match** opens the three choices. The AI deploys its row instantly; the human deploys theirs as before.
- On the AI's turn, `GameScreen` asks `AIPlayer.next_action()` every 0.6 s and sends it through `GameController`, so the board animates step by step. Taps are ignored until the AI ends its turn. Cards the AI draws still pop up, for information only.
- The action log records AI actions like any other, so "why did it do that" is answerable.
- Hotseat is unchanged.

## 6. Test plan

- `test_ai_opponent.gd`:
  - every action the AI proposes is accepted by RulesEngine;
  - it takes a defeat when one is available;
  - it never ends its turn with its own Hero trapped;
  - it answers drawn-card choices and off-board returns;
  - two AIs (Closed City vs Flood Survivors) finish seeded matches without a single rejected action.
- `test_game_screen.gd`: a vs-AI match where the AI plays its turn and hands back to the human.
- Browser click test: start *vs AI* from the menu and see the AI's turn complete.

## 6A. Phase 1 findings (2026-10-09)

The AI-vs-AI test (4 seeded matches) found three AI bugs before any human played it:
- **The AI walled in its own Hero.** It answered The Causeway Breathes with a Stone that left its Hero no move, then had no AP to clear a path (a Hero capture on turn 1). Fix: every ability, bonus, or card choice that places something is probed by placing temporary blockers and recounting the Hero's moves. A choice that would trap the Hero is vetoed.
- **Two cautious Heroes stalled for 120 turns.** Danger was weighted by value ÷ HP, uncapped, so a 2-HP Hero would never step into range. Fix: fragility is capped at 2. A boldness term, set by `patience` in `basic.json` (default turn 20), lowers fear of danger and raises the urge to close in as a match drags on.
- **Pointless Leaks.** Orlov scored every Leak at least 0.25, so he littered his own back row. Fix: a Leak is worth only enemies nearby, minus allies nearby.

After the fixes, all 4 matches finish in 16–31 turns. Flood Survivors won 3 of 4. That isn't balance evidence yet: the scoring is basic, and Player 1 starts with 2 AP. It's worth watching in the planned AI-vs-AI balance runs.

## 7. Roadmap (not built yet)

- **Phase 2 — lookahead.** Score actions by simulating them and evaluating the resulting board. This needs a simulation sandbox:
  - move `RelicEventDeck`'s per-match state into `MatchState`;
  - add a deep copy of `MatchState`;
  - silence presentation listeners (screen, MatchLog) while simulating.
  Then a `SearchStrategy` can evaluate full-turn sequences and the opponent's best reply.
- **Levels and personalities** as data: aggressive, defensive, objective-focused (leveling), and an Easy level with more randomness.
- **Time budget** per decision for mobile.
- **AI vs AI watch / balance runs:** two `AIPlayer`s headless over many seeds, reporting win rates, match length, and how often Level 2/3 is reached. These are PRD Section 26 playtest questions.
- **Telemetry hooks:** log each decision's top candidates and scores for tuning.
