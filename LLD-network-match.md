# MythCards Low-Level Design — Network Match (turn-based, friend vs friend)

**Document Control**

| Field | Value |
| --- | --- |
| Source document(s) | HLD.md v5 (Section 4.14 and Section 9, 2026-10-19), BRD.md (BO-006, FR-090, NFR-031), PRD.md Section 15 (Future Modes) |
| Module/flow scope | `NetSession` and its transport, `ActionCodec`, the online entries in the game screen, and the relay server (`server/`) |
| Target stack | Godot 4.7.2 / GDScript (client, web and Windows); TypeScript on Cloudflare Workers + one Durable Object per room (server) |
| Version | 1 |
| Date | 2026-10-19 |
| Status | Draft |
| Prepared by | Drew Davis |

Designer decisions (2026-10-19): turn-based play now, with live Blitz later. Players connect over the internet, on free-tier hosting. The client is either the web build or the Windows build.

## 1. Purpose & Scope

You create a match and get a 6-letter code; your friend joins with it, on a phone browser or Windows. You each take your turns whenever you like, over hours or days. Opening the game shows whose turn it is and brings the board up to date.

**How it works:**
- Both clients run the full rules engine. A match is a deck seed, two teams, and an ordered action log.
- The server stores and orders the log. It hides each player's deployment until both are in, and it never runs game rules.
- Each client rebuilds the match by replaying the log through `RulesEngine.request_action` (HLD 4.14). The deck shuffle is seeded and is the match's only randomness, so replay is exact.
- Every action carries a hash of the game state after it, so a divergence is caught at the first bad action.

**Out of scope:**
- **Blitz (live):** later, it adds a WebSocket push and a turn timer to the same log (Section 9).
- Accounts and matchmaking with strangers.
- Push or email notifications for "your turn" (v1: tell your friend, or open the link).
- Anti-cheat: each client knows the deck order. Friends only (Section 7).
- Spectators.

## 2. File Layout

```
game/scripts/net/
  action_codec.gd        # class_name ActionCodec: JSON-safe payloads, state hash (moved out of TestBridge)
  net_session.gd         # class_name NetSession (Node): one online match on this device
  net_transport.gd       # class_name NetTransport (RefCounted): the server API as async calls
  http_transport.gd      # class_name HttpTransport extends NetTransport: HTTPRequest to the Worker
  loopback_transport.gd  # class_name LoopbackTransport extends NetTransport: in-memory server for GUT
  net_store.gd           # class_name NetStore: saved seats in user://net_matches.cfg
game/scripts/ui/
  game_controller.gd     # + net, is_remote_turn(), is_waiting(); _send() appends when online
  game_screen.gd         # + Play a friend: create, join, your matches; waiting and out-of-sync banners
  online_menu.gd         # class_name OnlineMenu (Control): the create/join/list panel
game/tests/unit/
  test_action_codec.gd
  test_replay_determinism.gd
  test_net_session.gd
server/                  # new top-level folder, deployed with wrangler
  wrangler.toml
  package.json
  src/index.ts           # Worker entry: re-exports handle() and Room
  src/api.ts             # routing, CORS, size and token checks (9A)
  src/room_logic.ts      # RoomLogic: append, deploy hiding, expiry, over a RoomStore (9A)
  src/room.ts            # Durable Object Room: SQLite store, cleanup alarm
  test/room.test.ts      # node --test against Room with an in-memory storage stub
e2e/tests/online.spec.ts # two browser pages, one match, against `wrangler dev`
```

## 3. Class & Function Specs

### 3.1 `ActionCodec` (static, `game/scripts/net/action_codec.gd`)

This class takes over `TestBridge._to_engine` / `_to_json_safe` / `_pos` unchanged; `TestBridge` now delegates to it.

| Method | Behavior |
| --- | --- |
| `static func to_engine(value: Variant) -> Variant` | `{x, y}` dictionaries with numeric values become `Vector2i`, recursively through dictionaries and arrays. |
| `static func to_json_safe(value: Variant) -> Variant` | `Vector2i` becomes `{x, y}`, recursively. |
| `static func encode(action_type: String, actor_id: String, payload: Dictionary) -> Dictionary` | `{"action_type", "actor_id", "payload": to_json_safe(payload)}`. |
| `static func state_hash() -> String` | `JSON.stringify(TestBridge.serialize_state(), "", true)` (sorted keys), then `.sha256_text().left(16)`. `serialize_state()` is plain data and always available; only its JS hooks need the `test_bridge` feature tag. |

### 3.2 `NetTransport` (`net_transport.gd`) — the server API

Every call is a coroutine that returns `{"ok": bool, "status": int, "body": Dictionary, "error": String}`. Paths are in Section 6.

```gdscript
func create_room(team_id: String, version: String) -> Dictionary      # POST /rooms
func join_room(code: String, version: String) -> Dictionary            # POST /rooms/{code}/join
func fetch_log(code: String, token: String, since: int) -> Dictionary  # GET  /rooms/{code}/log?since=n
func append(code: String, token: String, entry: Dictionary) -> Dictionary  # POST /rooms/{code}/log
```

- `HttpTransport` holds one `HTTPRequest` child per call and the `base_url`. The URL comes from the project setting `mythcards/net/server_url`, overridable with the `--server=` command-line argument for `wrangler dev`.
- `LoopbackTransport` implements the same rules as `Room` (Section 4.4) on in-memory arrays, so GUT can test `NetSession` without a network.

### 3.3 `NetStore` (`net_store.gd`)

Saves the seats you hold in `user://net_matches.cfg` (`ConfigFile`; on the web build it persists in IndexedDB).

| Method | Behavior |
| --- | --- |
| `static func save(code: String, seat: String, token: String, team_id: String) -> void` | One section per room code. |
| `static func seats() -> Array[Dictionary]` | `[{code, seat, token, team_id}]`, newest first. |
| `static func forget(code: String) -> void` | Removes a room (after a match ends, or "Remove" in the list). |

### 3.4 `NetSession` (`net_session.gd`, `extends Node`, a child of the game screen)

| Field | Type | Meaning |
| --- | --- | --- |
| `transport` | `NetTransport` | `HttpTransport` in the game, `LoopbackTransport` in tests |
| `code` | `String` | room code |
| `seat` | `String` | `"p1"` or `"p2"`: the side this device plays |
| `token` | `String` | this seat's secret, from create/join |
| `room` | `Dictionary` | `{seed: int, teams: {p1, p2}, version: String, status}` from the server |
| `applied` | `int` | how many log entries are applied locally (the next `seq`) |
| `desynced` | `bool` | a hash mismatch was found; input stops |
| `replaying` | `bool` | true while catching up from the log; the screen skips popups, BoardFx and sounds |
| `poll_seconds` | `float` | 5.0 while the match screen is open and it isn't your turn; 0 (off) on your turn |

Signals:
- `log_applied(count: int)` fires after new entries are applied, so the screen refreshes.
- `desync(seq: int, expected: String, actual: String)`.
- `room_error(message: String)`.

| Method | Behavior | Implements |
| --- | --- | --- |
| `func create(team_id: String) -> bool` | `transport.create_room(team_id, version())`. Saves the seat with `NetStore` and loads the room. | BO-006 |
| `func join(code: String) -> bool` | `transport.join_room`. A version mismatch returns false with `room_error("Your friend is on a different version of the game (…)")`. | |
| `func open(code: String) -> bool` | Loads a saved seat, fetches the whole log (`since=0`), and calls `_rebuild(entries)`. | |
| `func submit(action_type: String, actor_id: String, payload: Dictionary) -> void` | Called by `GameController._send` after a local action succeeded. Appends `{seq: applied, kind: "action", seat, action: ActionCodec.encode(...), hash_after: ActionCodec.state_hash()}`. On `409 seq_conflict`, it calls `resync()`. On a network failure, it queues the entry and retries every `poll_seconds` (Section 7). | |
| `func submit_deploy(placements: Dictionary) -> void` | `placements`: `{instance_id: {x, y}}`. Appends `{kind: "deploy", seat, placements}`. | |
| `func poll() -> void` | `fetch_log(since=applied)`, then `_apply_entries(entries)`. | |
| `func resync() -> void` | Fetches the full log and rebuilds from scratch (the same path as `open`). | |
| `func is_my_decision() -> bool` | `RelicEventDeck.decision_player() == seat` once the match has started; during setup, "my deployment isn't in yet". | |
| `static func version() -> String` | `ProjectSettings.get_setting("application/config/version")`. The export scripts write the git short hash there (Section 4.5). | |

### 3.5 `GameController` changes

- `var net: NetSession = null`
- `func is_remote_turn() -> bool`: `net != null and setup == null and GameState.is_match_active() and not net.is_my_decision()`.
- `func is_waiting() -> bool`: `is_ai_turn() or is_remote_turn()`. It replaces `is_ai_turn()` at the input gates: `tap_tile` (line 258), `end_turn` (346), and the screen's End turn button, warning and confirm (game_screen 429, 496, 769). The AI ticker keeps using `is_ai_turn()`.
- `_send(action, actor, payload)`: after `RulesEngine.request_action` succeeds, it calls `net.submit(action, actor, payload)` if `net != null` and the action was this seat's. Failed actions are never sent.
- `func begin_online(session: NetSession) -> void`: starts setup with `room.teams` and lets this device place only `session.seat`. "Done placing" calls `net.submit_deploy(...)`, not `confirm_placement`.
- `func apply_remote_deploys(deploys: Dictionary) -> void`: `deploys` is `{seat: placements}` for both seats. It runs `setup.place_character` for every entry, then `confirm_placement(room.seed)`, which starts the match exactly as hotseat does.

### 3.6 Game screen and `OnlineMenu`

- **Chooser:** a fourth button, "Play a friend online", opens `OnlineMenu`. It holds:
  - **Create:** pick Closed City or Flood Survivors, then see the code and a "Copy invite" button. On the web, the invite is the page URL plus `?room=CODE`.
  - **Join:** enter a code (6 letters, case-insensitive). On the web, `?room=` fills it in.
  - **Your matches:** each saved seat with "Your turn" / "Their turn" / "Waiting for your friend to join" / "Ended", read with one `fetch_log` each when the menu opens.
- **Header:** when the other player is up, the turn label says "Their turn · Flood Survivors".
- **Banners:**
  - "Can't reach the server. Your move is saved and will be sent." (queued entries)
  - "Out of sync at action N. Copy the log and send it to Drew." (with a "Copy log" command; input stays off)

## 4. Algorithms

### 4.1 Rebuild from the log (`NetSession._rebuild(entries)`)

1. Set `replaying = true` and `applied = 0`. `GameState.reset()`; `MatchLog.clear()`.
2. `controller.begin_online(self)` (setup with both teams from `room.teams`).
3. Gather the `deploy` entries. The server returns the opponent's only once both are in (4.4).
   - With both present, `controller.apply_remote_deploys(...)` starts the match with `room.seed`. `applied` = index after the later deploy + 1.
   - With only this seat's deploy, show "Waiting for your friend to deploy" and stop (still replaying = false).
   - With neither, stay in setup for this seat.
4. Pass the remaining entries to `_apply_entries`.
5. Set `replaying = false`, emit `log_applied`, and run `controller.sync()`.

### 4.2 Applying entries (`NetSession._apply_entries(entries)`)

For each entry in `seq` order, skipping `seq < applied`:
1. If `seq != applied`, there's a gap: `resync()` and stop.
2. For an `action` entry:
   - If `entry.seat == seat` and this device already applied it locally (only during a live session), just compare the hash.
   - Otherwise run `RulesEngine.request_action(a.action_type, a.actor_id, ActionCodec.to_engine(a.payload))`.
3. If the result isn't `success`, or `ActionCodec.state_hash() != entry.hash_after`: set `desynced = true`, emit `desync(seq, entry.hash_after, actual)`, and stop. Don't apply further entries.
4. `applied += 1`.
5. After the loop: emit `log_applied(n)`. If the match ended, `NetStore` marks it ended (it's kept so the result can be reviewed).

### 4.3 Local action, end to end

1. You tap. The controller builds the action, and `_send` runs it through `RulesEngine` locally. Animations play as they do today.
2. If it succeeded, `net.submit` appends it with `seq = applied` and the hash after. On a `200`, `applied += 1`.
3. Your friend's client polls (every 5 s while their screen is open, and on returning to the app), gets the entry, and replays it (4.2). Their board animates it like an AI move (the AI step pacing, `AI_STEP_SECONDS`, between entries).
4. Your turn ends with your `end_turn` entry. Your client stops polling until it's waiting again. This keeps the free tier well under its request limits (Section 9).

Choices that belong to the other player (a drawn card's decision, Seraphic Burial Veil) need no special case. `RelicEventDeck.decision_player()` names them, `is_remote_turn()` follows it, and the match simply waits for that player's entry.

### 4.4 Server: append and deploy hiding (`Room`)

Tables (Durable Object SQLite):
- `room(code TEXT PRIMARY KEY, seed INTEGER, team_p1 TEXT, team_p2 TEXT, version TEXT, token_p1 TEXT, token_p2 TEXT, created_at INTEGER, updated_at INTEGER)`. Tokens are stored as SHA-256 hashes.
- `log(seq INTEGER PRIMARY KEY, seat TEXT, kind TEXT, body TEXT, at INTEGER)`

`create(team, version)`:
- 6 letters from `ABCDEFGHJKMNPQRSTUVWXYZ` (no I, L, O). The DO id is `idFromName(code)`; retry on collision.
- `seed` = a random 31-bit int. The creator is `p1` with their team, and `p2` gets the other team (`[NEED]` coin flip, Section 9).
- Returns `{code, seat: "p1", token, seed, teams, version}`.

`join(code, version)`:
- `404` if there's no room; `409 seat_taken` if `token_p2` is set; `409 version_mismatch` with both versions if they differ.
- Returns `{seat: "p2", token, seed, teams, version}`.

`append(seat, entry)`:
1. `seat` comes from the token (`401` if no match), never from the body.
2. `entry.seq != count(log)` → `409 seq_conflict {next: count}`.
3. `kind == "deploy"`: `409` if this seat already deployed. `kind == "action"`: `409 not_started` if both deploys aren't in yet.
4. Insert. `updated_at = now`. Return `{next: seq + 1}`.

`fetch_log(seat, since)`:
- Returns entries with `seq >= since`.
- An opponent `deploy` entry is replaced with `{seq, seat, kind: "deploy_hidden"}` until this seat's own deploy exists. This is what keeps your formation secret until your friend has committed theirs (playtest ruling 2026-10-13).
- Also returns `{next, status}`, where status is `"waiting_for_join" | "deploying" | "playing"`.

The server never decides whose turn it is. Order comes from `seq`; legality is checked by both clients' `RulesEngine`, and a bad entry shows up as a desync (4.2).

Cleanup: a DO alarm deletes a room 30 days after `updated_at`.

### 4.5 Version pinning

Rules change often (this week alone: four cards and the 30-card deck). A match recorded under one ruleset doesn't replay under another, so:
- `tools/export_web.ps1` and the Windows export write `git rev-parse --short HEAD` (plus `-dirty` if the tree has changes) into `application/config/version` before exporting.
- The room stores the creator's version. Join refuses a different one, and `open` refuses a saved match whose version isn't this build's: "This match was started on build X. Finish it on that build, or start a new one." The web build at one URL can only be one version, so ongoing matches must be finished before a rules update is published, or the old build kept at a second URL. `[NEED]`, Section 9.

## 5. Data Structures

- Log entry (JSON):
  - action: `{"seq": int, "seat": "p1"|"p2", "kind": "action", "action": {"action_type": String, "actor_id": String, "payload": Object}, "hash_after": String(16)}`
  - deploy: `{"seq", "seat", "kind": "deploy", "placements": {instance_id: {"x": int, "y": int}}}`
- `room` (client copy): `{"code": String, "seed": int, "teams": {"p1": team_id, "p2": team_id}, "version": String, "status": String}`
- Saved seat (`user://net_matches.cfg`): section = code; keys `seat`, `token`, `team_id`, `version`, `ended: bool`.
- Instance ids are already deterministic (`p1_r-vera-7`, minted serially; `MatchState.mint_instance_id`), so both clients name every character identically.

## 6. Signal/Payload Specs

**HTTP API.** JSON bodies. Every route but create and join needs `Authorization: Bearer <token>`. CORS allows `*`, since the token is the only credential.

| Route | Request | Success | Errors |
| --- | --- | --- | --- |
| `POST /rooms` | `{team_id, version}` | `201 {code, seat, token, seed, teams, version}` | `400` unknown team |
| `POST /rooms/{code}/join` | `{version}` | `200 {seat, token, seed, teams, version}` | `404`, `409 seat_taken`, `409 version_mismatch` |
| `GET /rooms/{code}/log?since=n` | | `200 {entries, next, status}` | `401`, `404` |
| `POST /rooms/{code}/log` | log entry (Section 5) | `200 {next}` | `401`, `409 seq_conflict {next}`, `409 already_deployed`, `409 not_started`, `413` over 8 KB |

**Client signals** (`NetSession`):
- `log_applied(count: int)`: `count >= 0`; 0 after a rebuild that applied nothing new.
- `desync(seq: int, expected: String, actual: String)`
- `room_error(message: String)`: a player-facing sentence.

## 7. Error Handling & Edge Cases

| Scenario | Behavior | Source |
| --- | --- | --- |
| No connection when you act | The action applies locally and its entry is queued (in memory and `user://net_outbox.cfg`), then retried. A banner says it's saved. No further local input is blocked: your turn continues offline. | 4.3 |
| App closed with a queued entry | `open` sends the outbox before fetching. If the server's `next` moved on (impossible for a legal turn, since the other side was waiting), `resync`. | 4.2 |
| `seq_conflict` | `resync()` (rebuild from the server's log). The local unsent action is dropped, with a message. | 4.4 |
| Hash mismatch or a failed replayed action | Stop, show the out-of-sync banner and "Copy log". The match can't continue. Usually a version or determinism bug, so it gets a test (8.2). | HLD 4.14 |
| Opening a match from a different build | Refused with the version message. | 4.5 |
| Both players try to deploy the same seat | Impossible: the seat comes from the token. | 4.4 |
| Friend never joins | The menu shows "Waiting for your friend to join" with the code. Rooms expire after 30 days. | 4.4 |
| A choice owned by the waiting player mid-turn | The active player's screen says "Waiting for <friend> to choose…"; polling resumes until that entry arrives. | 4.3 |
| Hero capture or any win | Applied the same way on both; the game-over panel shows, and the seat is marked ended. | HLD 4.10 |
| Cheating by reading the deck order or editing a client | Accepted for friend matches: the deck seed is on the client. An edited client's actions fail replay on the honest client (desync). Ranked play needs the server to run rules (Section 9). | Scope |
| Token lost (cleared browser storage) | The seat can't be recovered in v1. `[NEED]` a "Copy my seat link" backup (`?room=CODE&seat=TOKEN`). | |

## 8. Test Plan

### 8.1 `test_action_codec.gd` (GUT)
- Given a payload `{to: Vector2i(3,2), tiles: [Vector2i(1,1)]}`, when encoded then decoded, then it's equal to the original.
- Given the same match state, `state_hash()` is the same twice. After any move, it differs.

### 8.2 `test_replay_determinism.gd` (GUT, the core guarantee)
- Given seeds 7, 42 and 2026: two AIs play a full match while a recorder on `EventBus.action_requested` keeps every action and the hash after it. When `GameState.reset()` and the match is rebuilt with the same teams, placements and seed, and the recorded actions are replayed through `RulesEngine.request_action`, then every hash matches and the winner is the same.
- The same check with each recorded payload passed through `ActionCodec` (JSON round trip), so serialization can't break determinism.

### 8.3 `test_net_session.gd` (GUT with `LoopbackTransport`)
- Create, then join with another version → `room_error` and false.
- p1 deploys → the p2 fetch shows `deploy_hidden`; after p2 deploys, both full deploys are returned and the match starts with the room seed.
- p1 acts (submit) → `seq` 0 is appended with a hash. A second client view (a fresh rebuild from the loopback log) reaches the same hash.
- A forged entry with a wrong `hash_after` → `desync` is emitted and `desynced` is true.
- Append with a stale `seq` → `seq_conflict` → `resync` rebuilds.
- `is_remote_turn()` follows `RelicEventDeck.decision_player()`: true while the other seat must choose a drawn card's option.

Only one engine runs per Godot process (the autoloads are singletons), so GUT can't run two clients at once. "Two clients" here means rebuild-from-log on the same process.

### 8.4 `server/test/room.test.ts` (`node --test`)
- Code alphabet; seat from token; `401` on a bad token.
- `seq_conflict`, `already_deployed`, `not_started`.
- Deploy hiding by seat; `version_mismatch`; cleanup alarm.

### 8.5 `e2e/tests/online.spec.ts` (Playwright)
- With `wrangler dev` on localhost, two browser pages:
  - A creates (Closed City), B joins with the code.
  - Both deploy with "Auto-place the rest".
  - They play six turns by clicks through `mythcards_ui()`.
- Then both pages' `mythcards_get_state()` are equal, and B's board shows A's last move.
- B reloads mid-match and comes back to the same state.

## 9. Open Implementation Questions

- `[NEED: who goes first]` The PRD says first player is fixed (p1) with a coin flip planned. v1 makes the room creator p1. Should the server flip instead?
- `[NEED: notifications]` v1 has no "your turn" alert. Options for later: web push (free, needs a service worker that the Godot export doesn't ship), or a daily email digest (needs a mail provider).
- `[NEED: versions in flight]` Before publishing a rules update, should open matches be finished first, or should the old build stay at a second URL until they end (4.5)?
- `[NEED: verify free-tier limits at setup]` Workers Free: about 100,000 requests a day. Durable Objects with SQLite storage on the Free plan. Polling a 5-second interval for an hour is 720 requests. Confirm the current limits in the Cloudflare dashboard before relying on them.
- `[NEED: web host]` Cloudflare Pages and Workers static assets cap single files at 25 MiB, and `index.wasm` is 37 MB. Host the web build on itch.io (free; a draft page with a secret link) or GitHub Pages (if the repo can be public), and keep only the API on Cloudflare.
- `[NEED: Blitz]` Live play adds a WebSocket to the same `Room` DO (hibernatable sockets, so an idle match costs nothing) and a turn timer in `TurnManager.start_turn` (HLD Section 9). The timer length is still PRD-OQ-010.

### 9A. Implementation Notes (deviations from this spec)

- **2026-10-22, steps 1–2 built.**
  - Step 1: `ActionCodec` and `test_replay_determinism.gd` pass (603 GUT). Replay is exact for seeds 7, 42 and 2026, both directly and through the JSON round trip. Seed 2026 runs to the 120-turn cap without a winner and still replays 291 actions exactly.
  - Step 2: the room rules live in `server/src/room_logic.ts` (`RoomLogic` over a `RoomStore` interface). `room.ts` is only the Durable Object wrapper (SQLite `SqlStore`, cleanup alarm), and routing is in `api.ts`. `index.ts` re-exports both.
    - Why: `node --test` can't load `cloudflare:workers`, so the tested code must not import it.
    - The Worker calls the DO over RPC (`stub.create(...)`), not by forwarding HTTP.
  - `create` returns `409 code_taken` from a used DO, and the Worker retries with a new code up to 5 times (`503 no_free_code` after that).
  - Fetch responses also carry `seed`, `teams` and `version`, so `open` gets the room in the same call.
  - An entry whose `kind` isn't `deploy` or `action` is `400 unknown_kind`.
  - Tests: `npm test` in `server/` runs 17 tests. A smoke run against `wrangler dev` (real SQLite DO) covered create, version mismatch, join, `not_started`, deploy hiding, `seq_conflict`, append, fetch since and `401`.
  - npm's allow-scripts policy skipped workerd's postinstall. `wrangler dev` still runs, because the binary ships in `@cloudflare/workerd-windows-64`.
- **2026-10-22, step 3 built.** `NetTransport`, `HttpTransport`, `LoopbackTransport`, `NetStore` and `NetSession` are in, with 13 tests in `test_net_session.gd` (616 GUT total, all passing).
  - The outbox is saved in the seat's own section of `user://net_matches.cfg` (`NetStore.set_outbox`), not in a separate `net_outbox.cfg`. Each queued entry keeps the `seq` it was given, and `open` sends the outbox before it rebuilds.
  - `NetStore.save` also stores the build `version`, so `open` can refuse a match from another build (4.5).
  - Network calls run one at a time (`_busy`), and polling waits while anything is unsent. This keeps `applied` equal to the number of server entries applied.
  - A deploy that hits `seq_conflict` (the other formation went in first) fetches the new entries, renumbers the outbox and retries. An action's `seq_conflict` still clears the outbox and resyncs (Section 7).
  - Part of step 4 came with it, because `NetSession` drives the controller: `GameController.net`, `begin_online`, `place_deploy`, `apply_remote_deploys`, `is_remote_turn`, `_send` → `submit`, and remote choices skipped in `_start_pending_choice`. `apply_remote_deploys` calls a new `_start_from_setup(seed)`, not `confirm_placement`, because online "Done placing" now submits the deploy instead. Still to do in step 4: `is_waiting()` at the input gates, `OnlineMenu`, banners, and polling on the game screen.

## 10. Traceability

| LLD section | HLD | BRD / PRD |
| --- | --- | --- |
| 3.4, 4.1–4.3 `NetSession` | 4.14, 9 (networked PvP row) | BO-006, NFR-031, PRD Section 15 Standard/Asynchronous PvP |
| 3.1 `ActionCodec` | 4.13 (TestBridge serialization), 4.4 (single action gate) | FR-090A |
| 3.5 controller gates | 4.12 presentation, 4.4 | FR-090 (hotseat stays the default) |
| 4.4 server | 4.14 | PRD-RISK-007 (multiplayer cost: free tier, no game server) |
| 4.5 version pinning | 4.14 | PRD-RISK-001/002 (rules change often during balance) |

## 11. Next Steps (build order)

1. `ActionCodec` (moved out of TestBridge) and `test_replay_determinism.gd`. If replay isn't exact, nothing else matters, so this goes first.
2. `server/`: `Room` + `index.ts` + `room.test.ts`; run with `wrangler dev`.
3. `NetTransport`, `HttpTransport`, `LoopbackTransport`, `NetStore`, `NetSession` + `test_net_session.gd`.
4. Controller gates (`is_waiting`, `_send` → `submit`, online setup) and the screen: `OnlineMenu`, banners, polling.
5. Version stamping in both export scripts.
6. `online.spec.ts` against `wrangler dev`.
7. Deploy: a Cloudflare account (free) → `wrangler deploy`; web build on itch.io (draft, secret link); set `mythcards/net/server_url`; build web + Windows.
8. Play a real match with your friend; record anything awkward in this LLD's 9A notes.
