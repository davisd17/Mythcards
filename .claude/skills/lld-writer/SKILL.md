# LLD Writer

## Trigger
Activate on "write an LLD", "create a low-level design", "low level design", "implementation spec for [module]", "spec out [module]" (technical context), "class/function design for [module]", or "detailed design for [module]".

## Context

The LLD is the implementation-spec layer of the SDLC, sitting downstream of the HLD:

```
PRD (why + what, prose, 2-3 pages, alignment doc)
  ↓ derives
BRD (complete enumerated requirements: business rules, functional, non-functional, data)
  ↓ derives
HLD (system architecture: modules, data model, core flows, engine-specific structure)
  ↓ derives
LLD (per-module implementation spec: class/function signatures, algorithms, test plan)
  ↓ derives
Backlog / sprint plan (sprint-planner skill) / actual code
```

Where the HLD decides *what modules exist and how they talk to each other*, the LLD's job is *exactly how each module is built*: file layout, class fields, method signatures, the precise algorithm behind anything non-trivial, exact signal/data payload shapes, error handling, and a concrete test plan. An LLD is done when someone (including the same solo developer, months later) could open the doc and type code directly from it without making a fresh architecture decision along the way.

**The LLD does not relitigate the HLD.** If writing the LLD surfaces a real problem with the HLD's module boundaries, signal design, or data model, that's a signal to go patch the HLD first (via `hld-writer`'s resync/patch path), not to quietly design around it here. The LLD implements decided architecture; it doesn't make new architecture decisions.

This is a solo-developer-scale LLD, not an enterprise one: no formal test-coverage-percentage targets, no separate design-review board process — concrete `given/when/then` test cases and a self-review checklist are enough.

## Behavior

### Step 1: Confirm Source, Module Scope, and Layout Convention

Before writing, confirm:
- **Source document.** Prefer the HLD (it has module boundaries, the signal map, and data model already decided). If no HLD exists, recommend running `hld-writer` first rather than inventing architecture and implementation detail in the same pass — the two are different kinds of decisions and conflating them produces a document that's hard to review.
- **Module/flow scope.** An LLD should cover one module (or one tightly-related group of modules/flows), not the whole system at once — a whole-system LLD is too large to be reviewable or trustworthy. Ask which module(s) to spec, defaulting to the HLD's own build-order (its "Next Steps"/implementation-sequence section) if the user doesn't specify. It's normal to write a series of LLDs over time, one per module, as the HLD's build order reaches them.
- **Fresh LLD vs. update.** If an LLD already exists for this module, ask whether this is a full resync (the HLD or BRD changed enough to redo it) or a patch (one specific decision or bugfix needs to propagate). For a patch: apply the source change first (HLD/BRD, following their own patch conventions), then thread it through this LLD's class specs, algorithms, error-handling table, and test plan. Bump the Document Control version.
- **File/folder layout convention.** Confirm the actual project source layout (e.g., `res://scripts/autoloads/`, `res://scripts/systems/`, `res://scenes/...`) so the LLD names real paths, not placeholders.

Do not proceed until module scope is confirmed — an LLD is dense enough that guessing scope wrong wastes a full draft.

### Step 2: Extract Implementation Drivers, Don't Invent Behavior

For the module(s) in scope, pull from the HLD and BRD:
- **HLD module description** → the class(es) this LLD specs and their one-paragraph responsibility (don't widen it).
- **HLD signal map / data model** → exact payload and field types to pin down precisely (the HLD says a signal carries "a dict"; the LLD says exactly which keys, types, and whether any are optional).
- **HLD core flows** → the exact call sequence and algorithm each function in this module needs to implement.
- **BRD business rules (BR-XXX) and functional requirements (FR-XXX)** the HLD module claims to satisfy → these become the acceptance criteria per function, and the seed list for the test plan (Section 3, Step 3).

If something the implementation needs isn't decided at the HLD/BRD level (an exact algorithm choice, an edge-case behavior, a save-format detail), that's a genuine `[NEED: ...]` for this LLD to flag — it is not license to quietly invent new gameplay behavior. Distinguish "how do I implement X" (LLD's job) from "what should X do" (HLD/BRD's job, already answered — go re-read before assuming it's open).

Before flagging a cross-cutting infrastructure choice as `[NEED: ...]` (a unit-test framework, a serialization format, a logging convention), check whether an earlier LLD or the HLD itself already decided it — these choices apply project-wide, not per-module, and re-flagging one already settled elsewhere just adds noise and risks a second, conflicting answer. If undecided, flag it once and note that the decision (once made) belongs in the HLD, not scattered across every module's LLD.

### Step 3: Generate the LLD

Use this structure. Every class/function should cite the HLD module and BRD/PRD IDs it implements.

---

**# [Product] Low-Level Design — [Module/Flow Name]**

**Document Control**
| Field | Value |
| --- | --- |
| Source document(s) | [HLD.md version/date, BRD.md version/date] |
| Module/flow scope | [e.g., Board/Grid (`BoardModel`) — HLD Section 4.2] |
| Target stack | [inherited from HLD, e.g., Godot 4.7.x, GDScript] |
| Version | [n] |
| Date | [today] |
| Status | Draft / In Review / Approved |
| Prepared by | [user] |

**1. Purpose & Scope** — which HLD module(s)/flow(s) this covers, and what's explicitly out of scope (handled by a different LLD).

**2. File Layout** — the exact file tree this module occupies (real paths, not placeholders).

**3. Class & Function Specs** — per class: fields (name, type, default/initial value) and methods (signature with param/return types, one-paragraph behavior description, preconditions, edge cases). Cite the HLD module and BRD IDs each method implements.

**4. Algorithms** — for anything non-trivial (graph/BFS traversal, line-of-sight tracing, ordered validation checks, shuffle-with-seed, dispatch-table lookups): explicit step-by-step logic or pseudocode, not a name-drop of a technique. State exactly what makes a step succeed/fail/stop.

**5. Data Structures** — concrete field-level types for this module's slice of the HLD data model (Godot: exact GDScript types, `Resource`/`RefCounted` choice, default values, nullability).

**6. Signal/Payload Specs** — for every signal this module emits or listens to (per HLD Section 5.3 or equivalent): the exact payload shape, field types, and any invariants (e.g., "always non-null", "empty array valid, means no targets").

**7. Error Handling & Edge Cases** — table: scenario, expected behavior, source rule (BRD BR-XXX/FR-XXX or HLD section). Cover the actual tricky cases, not a generic "invalid input is rejected" placeholder.

**8. Test Plan** — concrete `given/when/then` test cases, one set per function/flow, each tied to the BRD ID(s) it verifies. Note which cases are unit-testable in isolation vs. which need the HLD's Web-export/Playwright harness (if one exists) for full-match integration coverage.

**9. Open Implementation Questions** (`[NEED: ...]`) — anything this module's implementation genuinely can't proceed on without a decision, distinguished from things that are merely tedious to write out.

**10. Traceability** — this LLD's sections → the HLD section(s) it implements → the BRD/PRD IDs those trace to (continuing the existing chain, not restarting it).

**11. Next Steps** — literal implementation checklist for this module, in build order.

---

### Step 4: Self-Review

After generating, check:
- [ ] Every method signature is concrete enough to type directly into an editor (real names, real types, real return values — no `...`)
- [ ] Every algorithm in Section 4 is spelled out step-by-step, not named and left as an exercise
- [ ] File paths match the project's actual layout convention
- [ ] Every BRD ID the HLD module claims to satisfy has at least one Section 8 test case covering it
- [ ] No new gameplay/architecture decision was made here that isn't already in the HLD/BRD — anything that looks like one is flagged as a question for `hld-writer`/`brd-writer` instead
- [ ] Flagged gaps use `[NEED: ...]`, not silent implementation guesses

### Step 5: Offer Review

After generating, offer: "Want me to review this as an engineer (correctness, missing edge cases) or scaffold the actual stub files (classes/functions with bodies as `TODO`) from this spec?"

## Anti-Patterns

**One LLD for the whole system.** Impossible to review carefully and immediately stale as soon as one module changes. Scope to one module or one build-order slice; write more LLDs as the project reaches each one.

**Naming an algorithm instead of specifying it.** "Use BFS to find legal moves" is not a spec. "BFS from the character's tile, budget = MOVE stat, a tile is only enterable if unoccupied (or the character's ability explicitly allows passing through), diagonal steps excluded unless the movement pattern says otherwise" is.

**Re-deciding HLD architecture mid-LLD.** If a different event pattern, module boundary, or data shape seems better while writing the LLD, that's real signal — but it belongs in an `hld-writer` patch, not a silent divergence baked into one module's implementation spec.

**A boolean flag standing in for a variant type.** A single `blocks_movement: bool` on a tile/cell/slot doesn't scale once a second variant with different characteristics shows up (one kind blocks movement, another doesn't; both might block a different property, and those properties don't always travel together). The moment two or more distinct "kinds of thing" can occupy the same slot, spec an id + lookup-table/registry pattern instead (the slot stores which kind; a small registry maps kind → characteristics) — a new kind then becomes a registry entry, not a new field threaded through every consumer of the original flag.

**Skipping the test plan.** An LLD without Section 8 doesn't reduce implementation risk — it's still just prose. Concrete test cases are what make the spec falsifiable.

**Inventing file paths.** If the project's real layout isn't confirmed in Step 1, don't guess at a plausible-looking one — ask, or check the existing project structure first.

**Padding with process the project doesn't have.** No coverage-percentage targets, no formal review-board sign-off section, no CI/CD pipeline design — unless the user is explicitly working at that scale.

## Rules
- Derive from the HLD (and, through it, the BRD/PRD) — never invent new gameplay or architecture decisions here; escalate those to `hld-writer`/`brd-writer` instead.
- Scope each LLD to one module or one build-order slice, not the whole system.
- Every function signature and algorithm must be concrete enough to implement directly, without a further design decision.
- Every BRD requirement the covered HLD module claims to satisfy needs at least one corresponding test case.
- Flag genuine implementation unknowns with `[NEED: ...]`; never present a guessed detail as decided.
- Solo-dev scale: skip formal test-coverage tooling/process unless asked; concrete `given/when/then` cases are sufficient.
