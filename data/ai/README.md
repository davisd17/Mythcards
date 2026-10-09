# AI personalities

Each file here is one AI level or personality: the weights `AIEvaluator` scores actions with (LLD-ai-opponent.md 3-4). `tools/sync_game_content.ps1` copies them into the game.

- `basic.json`: the first level (2026-10-09). It uses every action type with simple heuristics and protects its Hero from capture. `patience` controls how soon it stops playing cautiously.

To add a level, copy `basic.json`, change the numbers, and load it with `AIPersonality.load_named("<file name>")`.
