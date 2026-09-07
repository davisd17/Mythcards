# HLD Writer

## Trigger
Activate on "write an HLD", "create a high-level design", "high level design", "technical design document", "TDD for [feature]", "architecture for [feature]", "design the architecture", or "system design for [feature]".

## Context

The HLD is the architecture layer of the SDLC, sitting downstream of the BRD:

```
PRD (why + what, prose, 2-3 pages, alignment doc)
  ↓ derives
BRD (complete enumerated requirements: business rules, functional, non-functional, data)
  ↓ derives
HLD (system architecture: modules, data model, core flows, engine-specific structure)
  ↓ derives
LLD (per-module implementation spec: class/function signatures, algorithms, test plan)
  ↓ derives
Backlog / sprint plan (sprint-planner skill, implementation)
```

Where the BRD enumerates *what* the system must do, the HLD's job is *how it's structured* to do it: module boundaries, data model, core flows, and — for this project — concrete Godot architecture (scenes, autoloads, signals, resources) a solo developer can scaffold directly from. Every module in the HLD should trace back to a BRD requirement ID; the HLD does not invent scope the BRD doesn't call for.

This is a solo-developer-scale HLD, not an enterprise one: no infra diagrams, no cloud-cost tables, no microservice topology, no multi-team RACI — unless the user is explicitly working at that scale.

**This project's standing scope pattern:** design for the current milestone (usually the prototype tier), but always include an explicit Extension Points section marking where the architecture is deliberately built to grow into the next tier (MVP) without a rewrite. Prototype-scoped does not mean throwaway.

## Behavior

### Step 1: Confirm Source, Scope Tier, and Depth

Before writing, confirm:
- **Source document.** Prefer the BRD if one exists (it has FR/NFR/DR IDs to trace against) — fall back to the PRD only if no BRD exists, and say so. If neither exists, recommend running `prd-writer` then `brd-writer` first rather than inventing architecture from nothing.
- **Fresh HLD vs. update.** If an HLD already exists for this scope tier, ask whether this is a full resync (source changed significantly — rewrite affected sections) or a patch (a specific new decision or resolved `[NEED:...]` needs to propagate through). For a patch: apply the decision at its point of origin first (PRD/BRD, if the decision belongs there — see this project's "update the source doc, not just the derivative" convention), then thread it through every HLD section it touches — module description, data model, flows, risks table (mark resolved, don't delete), traceability, and next steps. A resolved risk/`[NEED]` is never silently dropped from the risks table; it's marked `*(Resolved [date])*` and kept for traceability, matching how PRD/BRD open questions are handled in this project. Bump the Document Control version and note what changed.
- **Scope tier.** Which milestone/tier is this HLD for (e.g., Digital Rules Prototype vs. full MVP)? Match the source document's own scope tiers — don't invent new ones. Default to the current/next milestone unless told otherwise.
- **Extension planning.** Confirm whether the next tier up (MVP, or whatever tier follows) needs explicit extension points called out now, so the architecture doesn't need a rewrite later. Default to yes for this project.
- **Target stack.** Confirm the engine/language (this project: Godot + GDScript, per PRD's Technical Direction section) unless the user names something else.
- **Technical depth.** Concrete engine-specific architecture (node/scene structure, autoloads, signals, resource classes — something to scaffold directly from) vs. engine-agnostic logical design (state model, rules engine, data flow, no engine commitments yet). Ask if unclear; don't assume.

Do not proceed to drafting until scope tier and depth are confirmed — an HLD written at the wrong depth (too abstract to build from, or too concrete for a design that isn't locked yet) has to be redone.

### Step 2: Extract Architecture Drivers, Don't Invent Systems

Read the full source BRD/PRD before drafting. For each requirement, identify what it constrains architecturally:
- **Functional Requirements** → module responsibilities and their boundaries.
- **Non-Functional Requirements** → architecture qualities (a 100ms highlight-response NFR implies the rules/query layer can't block on I/O; a "data-driven, editable without rewriting logic" FR implies a content-loader module separate from the rules engine).
- **Data Requirements** → the core state/data model.
- **Business Rules** → invariants the architecture must enforce or make impossible to violate (e.g., "a mounted pair occupies one tile" is a data-model constraint, not just a rule to check at runtime).

If the source is ambiguous or silent on something the architecture needs to decide (e.g., save format, exact event-bus pattern), flag it with `[NEED: ...]` rather than silently deciding — architectural decisions are expensive to unwind once code is written, more so than prose gaps in a PRD.

### Step 3: Generate the HLD

Use this structure. Every module/flow should cite the BRD FR/NFR/DR/BR IDs it satisfies where applicable.

---

**# [Product] High-Level Design — [Scope Tier]**

**Document Control**
| Field | Value |
| --- | --- |
| Source document(s) | [BRD.md and/or PRD.md, version/date] |
| Scope tier | [e.g., Digital Rules Prototype — PRD-MILESTONE-002] |
| Target stack | [e.g., Godot 4.x, GDScript] |
| Version | [n] |
| Date | [today] |
| Status | Draft / In Review / Approved |
| Prepared by | [user] |

**1. Purpose & Scope** — one paragraph: what this HLD covers, what it explicitly excludes at this tier, which BRD/PRD sections it derives from.

**2. Architecture Goals & Constraints** — pulled from the source's NFRs and explicit constraints (solo-dev capacity, no networking yet, mobile-first, data-driven content, offline-only). State each as a design driver, not a generic value statement.

**3. System Context** — a simple diagram (ASCII or Mermaid) showing the system's outer boundary: player device, the game client, local data files, and anything explicitly out of scope (backend, networking) shown as absent/future, not built.

**4. Module Breakdown** — one subsection per subsystem (e.g., Board/Grid, Turn Manager, Rules Engine, Combat Resolution, Character Leveling, Relic/Event Deck, Mounted Pairs, Victory Conditions, Content Loader, UI/Presentation Layer). For each: responsibility (one paragraph), the data it owns, its dependencies on other modules, and the BRD FR IDs it satisfies. Keep boundaries narrow — no "manager" module that owns everything (see Anti-Patterns).

**5. Engine-Specific Structure** *(only if concrete depth was chosen in Step 1)* — scene/node tree overview, autoload/singleton list with responsibilities, the signal map (event names, emitters, listeners) if using a signal/event-bus pattern, and resource/class definitions that mirror the actual content data files (e.g., matching `characters.json` fields to a `CharacterData` resource).

**6. Data Model** — core state objects (e.g., Match, Player, Character, BoardTile, RelicEventCard, StatusEffect) as class/resource sketches with key fields, mapped to the BRD's Data Requirements section.

**7. Core Flows** — numbered step-by-step or Mermaid sequence diagrams for the flows that matter most (e.g., turn start → action → turn end; attack resolution including line-of-sight check; end-of-turn Hero-capture legal-move check; level-up trigger; relic/event draw and replacement). Each flow should reference the business rules it enforces.

**8. State Management & Persistence** — how match state lives in memory during a session, and what (if anything) persists between sessions at this tier. If persistence isn't needed yet, say so explicitly rather than omitting the topic — a documented "not needed yet" is different from a silent gap.

**9. Extension Points For [Next Tier]** — the section that keeps this from being a throwaway prototype design. For each major growth vector the source's later scope tier calls for (multi-culture content, networking/PvP, AI opponent, analytics, save/profile data, ranked mode, additional boards), state: what the prototype architecture does now (stub, local-only, hardcoded), and what specifically would need to change to support the next tier — not a full redesign, just the seam. If a module from Section 4 has no natural seam for a known future need, flag that as a risk in Section 11, don't paper over it.

**10. Non-Functional Considerations** — how the architecture satisfies the NFRs pulled in Step 2 (performance, mobile-first, testability/debug visibility, maintainability).

**11. Risks & Technical Open Questions** — table: ID, risk, impact, mitigation. Architecture-specific risks (state consistency across multi-step actions like mount/dismount, performance of line-of-sight calculation, save-format lock-in) plus any `[NEED: ...]` items from Step 2.

**12. Traceability** — compact table mapping HLD sections back to BRD FR/NFR/DR/BR IDs (continuing the BRD's own traceability chain rather than starting a new one).

**13. Next Steps** — concrete, ordered build sequence (what to scaffold first, second, third) — not a generic project-management list.

---

### Step 4: Self-Review

After generating, check:
- [ ] Every module in Section 4 traces to at least one BRD requirement ID
- [ ] Section 9 (Extension Points) exists and is specific — not "this will scale later" without saying how
- [ ] No component is designed for a scale the project doesn't have yet (networking, cloud infra, multi-team ownership) outside of Section 9's explicitly-flagged future seams
- [ ] Engine-specific names (autoloads, signals, resource classes) are consistent throughout — someone could grep the doc and start creating matching files
- [ ] No module has unbounded responsibility ("GameManager does everything")
- [ ] Flagged gaps use `[NEED: ...]`, not silent architectural guesses presented as decided

### Step 5: Offer Review

After generating, offer: "Want me to review this as an engineer (feasibility, missing edge cases, technical risk) or a skeptic (over-engineering, premature abstraction)?" — using this project's Sub-Agent Roles from CLAUDE.md.

## Anti-Patterns

**Building the MVP architecture when only the prototype was asked for.** Networking layers, save/profile systems, or AI-opponent interfaces fully designed now — when the BRD scope tier is prototype-only — is over-engineering. Those belong in Section 9 as extension points, not built out in Section 4.

**Skipping Section 9 entirely.** If the project has a known next tier (MVP) and the HLD doesn't say where the seams are, the next dev pass (even if it's the same person in three months) has to reverse-engineer where to extend. This defeats the reason the section exists.

**A God-object module.** "RulesEngine handles combat, movement, leveling, relics, and victory conditions" is not a module breakdown — it's a refusal to make boundary decisions. Split by the actual subsystems the BRD describes.

**Architecture that doesn't trace to requirements.** If a module or data field can't be tied to a BRD/PRD line, ask whether it's actually needed at this tier, or flag it as a deliberate forward-looking addition (and say so) rather than silently including it.

**Pixel-level UI design.** Layout, spacing, and visual hierarchy belong to a UX/mobile-prototype pass, not the HLD. The HLD covers what data the UI layer needs and what events it emits/listens for — not how it looks.

**Vague engine detail.** "Use signals for communication" without naming which signals, their payloads, and who emits/listens is not concrete enough to build from when concrete depth was requested.

## Rules
- Derive from the BRD (or PRD if no BRD exists) — don't invent scope the source doesn't support.
- Match the scope tier the user confirmed; don't silently expand into the next tier's full build, only its extension points.
- Default to concrete engine-specific detail for this project (Godot/GDScript) unless the user asks for engine-agnostic design.
- Trace every module and data object back to a source requirement ID where one exists.
- Flag technical unknowns with `[NEED: ...]`; never present an undecided architecture choice as settled.
- Solo-dev scale: no infra/cloud/microservice complexity, no multi-team process, unless explicitly asked for.
