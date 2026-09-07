# BRD Writer

## Trigger
Activate on "write a BRD", "create a BRD", "draft a BRD", "update the BRD", "business requirements document", or "enumerate the requirements for [feature/project]".

## Context

The BRD is the enumeration layer of the SDLC, sitting downstream of the PRD:

```
PRD (why + what, prose, 2-3 pages, alignment doc)
  ↓ derives
BRD (complete enumerated requirements: business rules, functional, non-functional, data)
  ↓ derives
Backlog / sprint plan / technical design (sprint-planner skill, engineering docs)
```

Where the PRD stays short and narrative, the BRD's job is completeness: every rule, requirement, and constraint implied by the PRD gets an ID and a home, so nothing gets silently dropped when work moves to implementation. The BRD is the traceability anchor — anyone should be able to point at a line of code or a playtest bug and trace it back to a numbered requirement, and from there back to the PRD section that motivated it.

This is a solo-developer-scale BRD, not an enterprise one: no validation scripts, no infra/cloud-cost comparison tables, no separate ADR/EARS/BDD document chain. One document, enumerated thoroughly, kept in sync with its source PRD.

## Behavior

### Step 1: Confirm the Source

A BRD is derived, not invented. Before writing:
- Identify the PRD (or equivalent source doc) it derives from. If none exists or it's thin, say so — recommend running `prd-writer` first rather than inventing requirements from nothing.
- If a prior BRD already exists for this scope, ask whether this is a full resync (rewrite every section from the current source) or a patch (update only sections tied to specific source changes). Default to full resync if the source has changed significantly since the last BRD — patches drift and silently leave stale requirements in place.
- Confirm scope boundaries: is this a BRD for the whole product, or one feature/milestone slice of it? A whole-product BRD should track the source doc's own scope sections (e.g., prototype vs. MVP vs. future).

### Step 2: Extract, Don't Invent

Read the full source document(s) before drafting. For every declarative sentence in the source ("the system shall...", "players win by...", "each side may field...", "-1 RANGE, minimum 1"), decide which category it belongs to (see Step 3) and give it an ID. Nothing in the BRD should be new information the source doesn't support — the BRD's value is completeness and structure, not invention.

For anything the source leaves ambiguous or unresolved, carry it forward as a flagged gap (`[NEED: ...]`) rather than resolving it with a guess. If the source has its own open-questions list, fold relevant ones into the BRD's Dependencies or Risks section rather than dropping them.

### Step 3: Generate the BRD

Use this structure. Every ID prefix is stable across revisions — never renumber existing IDs on a resync; append new ones and mark superseded ones as `Superseded` rather than deleting, so downstream references don't silently break.

---

**# [Product] Business Requirements Document**

**Document Control**
| Field | Value |
| --- | --- |
| Source document(s) | [PRD.md and version/date, or other source] |
| Version | [n] |
| Date | [today] |
| Status | Draft / In Review / Approved |
| Prepared by | [user] |

**1. Document Purpose** — one paragraph: what this BRD covers, what it's derived from, what it's for.

**2. Product Summary** — 1-2 paragraphs, plain language, no requirement IDs.

**3. Business Objectives** (`BO-XXX`) — table: ID, objective. Pull from the source's goals/vision section.

**4. Success Metrics** (`SM-XXX`) — table: ID, metric, target. Pull from the source's success criteria.

**5. Stakeholders** — table: stakeholder, interest. Keep short for a solo project — don't invent stakeholders that don't exist.

**6. Scope** — subsections matching the source's own scope boundaries (e.g., 6.1 Prototype Scope, 6.2 MVP Scope, 6.3 Out of Scope). Bullet lists, no IDs needed.

**7. Assumptions** (`AS-XXX`) — table: ID, assumption.

**8. Business Rules** (`BR-XXX`) — table: ID, rule. This is the highest-value section: every constraint, limit, or invariant stated in the source ("each side may field only one Hero," "damage is applied to the mounted rider's HP") gets its own rule, worded as a standalone testable statement.

**9. Functional Requirements** (`FR-XXX`) — grouped into subsections by system/feature area (e.g., 9.1 Match Setup, 9.2 Board and Movement, 9.3 Turn System...). Table per subsection: ID, requirement (`The system shall...`), priority (Must/Should/Could, MoSCoW). Use `Must` for anything the source states as core/required, `Should` for stated-but-secondary, `Could` for explicitly-future.

**10. Non-Functional Requirements** (`NFR-XXX`) — grouped by quality attribute (Performance, Usability, Balance/Fairness, Maintainability, Reliability, Accessibility, Platform, Content Quality — adapt categories to what the source actually discusses; don't pad with categories it never mentions). Same table shape as FR.

**11. Data Requirements** — what records/entities the system needs to track and their key fields. Prose or bullet list per entity, no IDs.

**12. Content Inventory** (only if the source has enumerable content — cards, levels, assets) — tables listing the actual content items and their key stats, mirrored from the source.

**13. Risks and Mitigations** (`R-XXX`) — table: ID, risk, impact, mitigation. Include the source's own risk list plus any new risks the BRD process itself surfaces (e.g., ambiguity found during extraction).

**14. Dependencies** (`D-XXX`) — table: ID, dependency. Include unresolved open questions from the source that block a requirement, tagged with which requirement(s) they block.

**15. Acceptance Criteria** — bullet list per major milestone/scope tier: what "done" looks like for that tier.

**16. Traceability** — a compact table mapping this BRD's major sections back to the source document's section numbers (e.g., `BO-001–006 ← PRD §2`, `BR-001–032 ← PRD §8–9`). This is the lightweight version of a traceability matrix: enough to answer "where did this come from" without a separate matrix file or automated tooling.

**17. Next Steps** — numbered list, action-oriented, matching the source's own next-steps if present.

---

### Step 4: Self-Review

After generating, check:
- [ ] Every Business Rule is a standalone testable statement (no "etc.", no vague "handles various cases")
- [ ] Every FR uses "shall" and is independently verifiable
- [ ] No ID number reused for two different requirements
- [ ] No section invents content the source doesn't support
- [ ] Every source open-question/risk that affects scope has a home somewhere (Dependencies or Risks)
- [ ] Traceability section actually resolves — spot-check 3-4 IDs back to their source section
- [ ] Flagged gaps use `[NEED: ...]`, not silent guesses

### Step 5: Offer Review

After generating, offer: "Want me to review this as an engineer (missing edge cases, technical risk) or a skeptic (untested assumptions)?" — using this project's Sub-Agent Roles from CLAUDE.md.

## Anti-Patterns

**Renumbering on resync.** Breaks any existing reference (code comments, tickets, prior conversations) to `BR-014`. Append and supersede instead.

**Padding categories that don't apply.** An NFR Accessibility section with three generic bullets no one asked for is worse than omitting it and noting `[NEED: accessibility requirements not yet defined]`.

**Requirements that aren't testable.** "The system shall handle abilities well" is not a requirement. "The system shall support once-per-turn and once-per-match ability limits" is.

**Silently resolving an open question.** If the source PRD has an unresolved `[NEED: ...]` or open question, the BRD must carry it forward — never quietly pick an answer to make the section look complete.

**Building the enterprise version by default.** No validation scripts, no ADR/EARS/BDD chain, no cloud-cost tables, no "Platform vs Feature" classification — unless the user is explicitly working at that scale. Ask before adding process weight, don't default to it.

## Rules
- Derive, don't invent — every requirement traces to the source document.
- Stable IDs — never renumber, only append and mark superseded.
- One document, sectioned — don't split into a separate FRD/NFRD unless the user asks.
- Flag gaps with `[NEED: ...]`; never fabricate data, targets, or resolved decisions.
- Match the source's own scope tiers (prototype/MVP/future, or equivalent) rather than inventing new ones.
