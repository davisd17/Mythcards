# MythCards — Godot Rules Prototype

Godot 4.7.2 project for PRD Milestone 002 (Digital Rules Prototype). Architecture: `HLD.md`; per-module specs: `LLD-*.md` at the repo root.

## Setup

1. Install Godot 4.7.x (`winget install GodotEngine.GodotEngine`).
2. Copy card data into the project: `tools/sync_game_content.ps1`.
   `data/cards/` at the repo root is the source of truth; `game/data/` is a gitignored copy. Rerun after any card edit.
3. Open `game/project.godot` in the editor.

## Tests

```powershell
tools/run_game_tests.ps1
```

Syncs card data, imports the project, and runs the GUT suites in `tests/unit/` headless. The run fails if any test fails or any script has a parse error. GUT on its own would silently skip a broken test file.

## Web build

```powershell
tools/export_web.ps1   # -> build/web/ (gitignored); add -Release for a release build
tools/serve_web.ps1    # http://localhost:8060/
```

Needs the Godot 4.7.2 export templates in `%APPDATA%\Godot\export_templates\4.7.2.stable\`. Only the `web_*` and `windows_*_x86_64*` files are required, not the full 1.28 GB package. The `Web (test)` preset is single-threaded, so it needs no special server headers. It also carries the `test_bridge` feature tag, which switches on `TestBridge`. `import_etc2_astc` is enabled because mobile browsers need ETC2/ASTC textures, and the export refuses to run without it.

## Layout

| Path | Contents |
| --- | --- |
| `scripts/autoloads/` | Singletons, in load order: `ContentDB` first (everything else assumes content is loaded) |
| `scripts/data_model/` | Card data classes, board tile and placed-object types |
| `scripts/systems/` | Plain classes owned by the autoloads (`BoardModel`, …) |
| `scenes/` | `main.tscn`: placeholder board until the presentation layer lands |
| `tests/unit/` | GUT tests, one file per module |
| `addons/gut/` | Vendored GUT 9.7.1 (the Godot 4.7 release) |

## Build status (HLD Section 13)

- [x] 1–2. Godot installed; autoloads scaffolded (all but `ContentDB` are empty stubs)
- [x] 3. Web export verified 2026-09-26: exported, served locally, and booted in headless Chrome (WebGL 2, single-threaded, all 28 cards loaded, no console errors)
- [x] 4. `ContentDB` + validation, GUT-covered
- [x] 5. `BoardModel`: legal moves, line of sight, range, placed objects, GUT-covered
- [x] 6–7. Match state model, `SetupFlow` (culture pick, back-row deployment), `GameState`, `TurnManager` (AP refresh with the 2-AP opening turn, status-effect expiry, capture check before handoff), GUT-covered
- [x] 8. `RulesEngine`: single action gate (move, attack, ability, mount, dismount, end turn, reactive bonus), legality previews for the UI, GUT-covered. Combat, mounting, and abilities are placeholders with the final signatures
- [x] 9. `CombatResolver` (marks, reduction, penetration, newest-first shields, lethal interception, defeat incl. mounted pairs, push) + `MountSystem` (mount, dismount, inherited MOVE), with an integration suite driving real matches through `RulesEngine`
- [ ] 10. `AbilitySystem`, the 14 character abilities: next (LLD-ability-system.md, needs remapping to the Closed City / Flood Survivors roster)
