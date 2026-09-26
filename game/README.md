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
- [~] 3. Web export preset defined (`Web (test)`, no threads, `test_bridge` feature tag); **not yet exported**, because export templates aren't installed
- [x] 4. `ContentDB` + validation, GUT-covered
- [x] 5. `BoardModel`: legal moves, line of sight, range, placed objects, GUT-covered
- [ ] 6. `MatchState` / `SetupFlow`: next
