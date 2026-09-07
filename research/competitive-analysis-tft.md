# Competitive Analysis: Teamfight Tactics (TFT)

**Author:** Claude (competitive-analysis skill)
**Date:** 2026-07-18
**Status:** Draft
**Comparison product:** MythCards (PRD.md)
**Scope:** Full product, broad pass

---

## 1. What They Built

- **Core loop:** 8-player free-for-all auto-battler. Players draft champions/items and position them on a small board during a planning phase; combat then resolves automatically with no player input during the fight itself.
- **Target user:** League of Legends players first — PC-native, later ported to mobile as a secondary surface, not designed mobile-first.
- **Key differentiator:** A large champion/trait pool that fully rotates every "set" (~every 3-4 months), keeping synergy discovery fresh without paid expansions.

## 2. What's Smart

1. **Draft-then-auto-resolve separates planning from execution.** No mechanical/dexterity skill is required during combat — only positioning and economy decisions matter. This broadens the audience beyond action-game players, directly relevant to MythCards' "tactical clarity for a broad mobile audience" pillar (PRD Section 4).
2. **Full free set rotations drive retention without power monetization.** Every 3-4 months the whole trait/champion roster resets — the game reinvents itself for existing players at no cost, generating repeat-play pull (PRD-SM-006) without needing paid expansions.
3. **Cosmetic-only monetization** (Little Legends, arenas, tacticians, season pass) is fully decoupled from power. This matches MythCards' own no-pay-to-win guardrail (PRD-NFR-003) and appears to be working commercially — `[NEED: verify the ~$620M/2025 revenue figure from a primary source like Sensor Tower or Riot's own disclosures; the search result sourcing it wasn't a primary outlet]`.

## 3. What's Weak

1. **Standard-mode match length (27-40 min) doesn't fit mobile sessions.** Riot's own fix was to ship an entirely separate "Hyper Roll" mode to get games down to ~10-20 min — the flagship mode itself never solved this, it just got a spinoff. Retrofitting session length after launch is expensive.
2. **Mobile is treated as a port, not a first-class platform.** App Store reviews specifically cite iPad UI not using full-screen (black bars) and lag relative to PC.
3. **Onboarding fails despite a "simple" core loop.** Reviews report receiving no in-game direction and needing to study external wikis to identify viable trait comps. A large overlapping-synergy trait pool means the real rules take far longer to learn than the pitch suggests.

**Context notes:**
- Rating: 4.5/5 across ~828K aggregated App Store reviews `[NEED: confirm against Apple's own review count — source was a third-party aggregator]`.
- Mobile reported as ~60% of player base; MAU estimates vary widely across sources (33M–100M) — treat both as directional, not precise `[NEED: primary Riot/Sensor Tower MAU figure]`.

## 4. Implications for MythCards

**Copy:**
- Cosmetic-only monetization, validated against PRD-NFR-003.
- Season-scale content refreshes (rotating sub-area focus) to sustain replay pull without expansion purchases.

**Avoid:**
- Don't let mobile be an afterthought. TFT's iPad/full-screen and lag complaints are exactly what PRD-NFR-002 (mobile readability) is meant to prevent — test on phone-sized screens from the first digital prototype, not after.
- Avoid TFT's session-length trap: design the core mode inside the 5-12 min target (PRD-NFR-001) from day one rather than shipping a slow mode and patching with a "fast mode" later.

**Differentiate:**
- TFT's onboarding failure is a direct warning for PRD-SM-001 (2-minute comprehension target). With 7 character types × 2+ cultures × relics/events, MythCards has similar combinatorial surface area to TFT's trait system — the UI needs to actively teach legal moves/threats in-match, not rely on players reading external guides.
- TFT removes direct control during combat (a recurring review complaint is that fights feel like "watching a spreadsheet fight itself"). MythCards keeps manual, chess-like control of every attack — a legitimate differentiation angle against auto-battler fatigue: *"the tactics game where your positioning actually fights."*

## 5. Open Questions / Follow-ups

| Question | Owner | Due Date |
|----------|-------|----------|
| Verify TFT revenue and MAU figures against a primary source (Sensor Tower, Riot disclosures) | — | — |
| Run a second competitor pass (Marvel Snap for mobile monetization/session length, or Gwent/Hearthstone for faction-identity design) | — | — |

## Sources

- [Teamfight Tactics Live Player Count And Statistics 2026](https://rec0ded88.com/live-player-count/teamfight-tactics/)
- [TFT Player Count: Current Stats and Trends | Turbosmurfs](https://turbosmurfs.gg/article/tft-player-count)
- [How Long Do TFT Matches Last | TGG](https://theglobalgaming.com/lol/how-long-are-tft-games)
- [Competitive Teamfight Tactics on X (aimed avg 27-35 min)](https://x.com/CompetitiveTFT/status/1140646056977453058?lang=en)
- [TFT Reviews (2026) | justuseapp](https://justuseapp.com/en/app/1480616748/tft-teamfight-tactics/reviews)
- [TFT: Teamfight Tactics — Review 2026: Sentiment & Intel](https://marlvel.ai/intel-report/games/com-riotgames-league-teamfighttactics)

---

*Generated via the `competitive-analysis` skill.*
