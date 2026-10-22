// LLD-network-match.md 8.4: the room rules and the HTTP API, against an in-memory store.
// Run: npm test (node --test, Node 22.18+ strips the TypeScript types itself).
import { test } from "node:test";
import assert from "node:assert/strict";
import { handle, type Env } from "../src/api.ts";
import {
  CODE_ALPHABET, CODE_LENGTH, MemoryStore, ROOM_TTL_MS, RoomLogic, isValidCode, randomCode,
} from "../src/room_logic.ts";

const V = "abc1234";

async function newRoom(now = () => 1000) {
  const logic = new RoomLogic(new MemoryStore(), now);
  const created = await logic.create("ABCDEF", "closed-city", V);
  return { logic, p1: created.body.token as string, created };
}

async function joined() {
  const r = await newRoom();
  const j = await r.logic.join(V);
  return { ...r, p2: j.body.token as string };
}

const deploy = (seq: number) => ({ seq, kind: "deploy", placements: { p1_x: { x: 0, y: 0 } } });
const action = (seq: number) => ({
  seq, kind: "action", action: { action_type: "end_turn", actor_id: "", payload: {} }, hash_after: "0123456789abcdef",
});

// --- Codes -------------------------------------------------------------------------------

test("codes are 6 letters from the alphabet with no I, L or O", () => {
  for (let i = 0; i < 200; i++) {
    const code = randomCode();
    assert.equal(code.length, CODE_LENGTH);
    assert.ok(isValidCode(code), code);
    assert.doesNotMatch(code, /[ILO]/);
  }
  assert.equal(CODE_ALPHABET.length, 23);
  assert.ok(!isValidCode("ABCDEO"));
  assert.ok(!isValidCode("ABCDE"));
});

// --- Create and join ---------------------------------------------------------------------

test("create gives p1 its team, the other team to p2, and a 31-bit seed", async () => {
  const { created } = await newRoom();
  assert.equal(created.status, 201);
  assert.equal(created.body.seat, "p1");
  assert.deepEqual(created.body.teams, { p1: "closed-city", p2: "flood-survivors" });
  const seed = created.body.seed as number;
  assert.ok(Number.isInteger(seed) && seed >= 0 && seed < 2 ** 31);
  assert.equal(created.body.version, V);
});

test("create refuses an unknown team and a taken code", async () => {
  const logic = new RoomLogic(new MemoryStore());
  assert.equal((await logic.create("ABCDEF", "original-russian", V)).status, 400);
  await logic.create("ABCDEF", "flood-survivors", V);
  assert.equal((await logic.create("ABCDEF", "closed-city", V)).body.error, "code_taken");
});

test("tokens are stored hashed", async () => {
  const store = new MemoryStore();
  const logic = new RoomLogic(store);
  const created = await logic.create("ABCDEF", "closed-city", V);
  assert.notEqual(store.room!.token_p1, created.body.token);
  assert.equal(store.room!.token_p1.length, 64);
});

test("join: seat p2, then seat_taken; a different version is refused", async () => {
  const { logic } = await newRoom();
  const wrong = await logic.join("zzz9999");
  assert.equal(wrong.status, 409);
  assert.deepEqual(wrong.body, { error: "version_mismatch", room_version: V, your_version: "zzz9999" });
  const ok = await logic.join(V);
  assert.equal(ok.status, 200);
  assert.equal(ok.body.seat, "p2");
  assert.equal((await logic.join(V)).body.error, "seat_taken");
  assert.equal((await new RoomLogic(new MemoryStore()).join(V)).status, 404);
});

// --- Seat from token ---------------------------------------------------------------------

test("the seat comes from the token, never the body", async () => {
  const { logic, p2 } = await joined();
  await logic.append(p2, { ...deploy(0), seat: "p1" });
  const log = await logic.fetchLog(p2, 0);
  assert.equal((log.body.entries as any[])[0].seat, "p2");
});

test("a bad token is 401", async () => {
  const { logic } = await joined();
  assert.equal((await logic.fetchLog("nope", 0)).status, 401);
  assert.equal((await logic.append("nope", deploy(0))).status, 401);
  assert.equal((await logic.fetchLog("", 0)).status, 401);
});

// --- Append rules ------------------------------------------------------------------------

test("seq_conflict reports the next seq", async () => {
  const { logic, p1 } = await joined();
  const r = await logic.append(p1, deploy(3));
  assert.equal(r.status, 409);
  assert.deepEqual(r.body, { error: "seq_conflict", next: 0 });
  assert.deepEqual((await logic.append(p1, deploy(0))).body, { next: 1 });
});

test("a seat deploys once; actions wait for both deploys", async () => {
  const { logic, p1, p2 } = await joined();
  assert.equal((await logic.append(p1, action(0))).body.error, "not_started");
  await logic.append(p1, deploy(0));
  assert.equal((await logic.append(p1, deploy(1))).body.error, "already_deployed");
  assert.equal((await logic.append(p1, action(1))).body.error, "not_started");
  await logic.append(p2, deploy(1));
  assert.equal((await logic.append(p1, action(2))).status, 200);
  assert.equal((await logic.append(p1, { seq: 3, kind: "chat" })).body.error, "unknown_kind");
});

// --- Fetch: deploy hiding and status -----------------------------------------------------

test("the opponent's deploy stays hidden until your own is in", async () => {
  const { logic, p1, p2 } = await joined();
  await logic.append(p1, deploy(0));
  const hidden = await logic.fetchLog(p2, 0);
  assert.deepEqual(hidden.body.entries, [{ seq: 0, seat: "p1", kind: "deploy_hidden" }]);
  assert.equal(hidden.body.status, "deploying");
  const own = await logic.fetchLog(p1, 0);
  assert.equal((own.body.entries as any[])[0].kind, "deploy", "you always see your own deploy");

  await logic.append(p2, deploy(1));
  const shown = await logic.fetchLog(p2, 0);
  const entries = shown.body.entries as any[];
  assert.deepEqual(entries.map((e) => e.kind), ["deploy", "deploy"]);
  assert.deepEqual(entries[0].placements, { p1_x: { x: 0, y: 0 } });
  assert.equal(shown.body.status, "playing");
  assert.equal(shown.body.next, 2);
});

test("fetch returns entries from since, with the room summary", async () => {
  const { logic, p1, p2 } = await joined();
  await logic.append(p1, deploy(0));
  await logic.append(p2, deploy(1));
  await logic.append(p1, action(2));
  const r = await logic.fetchLog(p2, 2);
  assert.deepEqual((r.body.entries as any[]).map((e) => e.seq), [2]);
  assert.deepEqual((r.body.entries as any[])[0].action.action_type, "end_turn");
  assert.equal(typeof r.body.seed, "number");
  assert.deepEqual(r.body.teams, { p1: "closed-city", p2: "flood-survivors" });
});

test("status is waiting_for_join before p2 joins", async () => {
  const { logic, p1 } = await newRoom();
  assert.equal((await logic.fetchLog(p1, 0)).body.status, "waiting_for_join");
});

// --- Cleanup -----------------------------------------------------------------------------

test("a room expires 30 days after its last write", async () => {
  let now = 1000;
  const { logic, p1 } = await newRoom(() => now);
  await logic.join(V);
  now = 5000;
  await logic.append(p1, deploy(0));
  assert.equal(logic.expiresAt(), 5000 + ROOM_TTL_MS);
  now = 5000 + ROOM_TTL_MS - 1;
  assert.equal(logic.expire(), false);
  now = 5000 + ROOM_TTL_MS;
  assert.equal(logic.expire(), true);
  assert.equal((await logic.fetchLog(p1, 0)).status, 404);
});

// --- HTTP API ----------------------------------------------------------------------------

function fakeEnv(): { env: Env; rooms: Map<string, RoomLogic> } {
  const rooms = new Map<string, RoomLogic>();
  const env: Env = {
    ROOM: {
      idFromName: (name: string) => name,
      get: (id: unknown) => {
        const name = id as string;
        if (!rooms.has(name)) rooms.set(name, new RoomLogic(new MemoryStore()));
        return rooms.get(name)!;
      },
    },
  };
  return { env, rooms };
}

const BASE = "https://api.example";

function post(path: string, body: unknown, token = ""): Request {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  return new Request(BASE + path, { method: "POST", headers, body: JSON.stringify(body) });
}

test("API: create, join (case-insensitive code), append, fetch", async () => {
  const { env } = fakeEnv();
  const created = await handle(post("/rooms", { team_id: "flood-survivors", version: V }), env);
  assert.equal(created.status, 201);
  assert.equal(created.headers.get("Access-Control-Allow-Origin"), "*");
  const c = await created.json() as any;
  assert.deepEqual(c.teams, { p1: "flood-survivors", p2: "closed-city" });

  const joinRes = await handle(post(`/rooms/${c.code.toLowerCase()}/join`, { version: V }), env);
  assert.equal(joinRes.status, 200);
  const j = await joinRes.json() as any;

  assert.equal((await handle(post(`/rooms/${c.code}/log`, deploy(0), c.token), env)).status, 200);
  const get = new Request(`${BASE}/rooms/${c.code}/log?since=0`, { headers: { Authorization: `Bearer ${j.token}` } });
  const log = await (await handle(get, env)).json() as any;
  assert.equal(log.entries[0].kind, "deploy_hidden");
});

test("API: missing token is 401, oversized entry is 413, bad JSON is 400", async () => {
  const { env } = fakeEnv();
  const c = await (await handle(post("/rooms", { team_id: "closed-city", version: V }), env)).json() as any;
  assert.equal((await handle(new Request(`${BASE}/rooms/${c.code}/log`), env)).status, 401);
  const big = { ...deploy(0), pad: "x".repeat(9000) };
  assert.equal((await handle(post(`/rooms/${c.code}/log`, big, c.token), env)).status, 413);
  const bad = new Request(`${BASE}/rooms/${c.code}/join`, { method: "POST", body: "{nope" });
  assert.equal((await handle(bad, env)).status, 400);
});

test("API: unknown room is 404; CORS preflight is 204", async () => {
  const { env } = fakeEnv();
  assert.equal((await handle(post("/rooms/ABCDEF/join", { version: V }), env)).status, 404);
  assert.equal((await handle(post("/rooms/AB/join", { version: V }), env)).status, 404);
  assert.equal((await handle(new Request(`${BASE}/elsewhere`), env)).status, 404);
  const pre = await handle(new Request(`${BASE}/rooms`, { method: "OPTIONS" }), env);
  assert.equal(pre.status, 204);
  assert.match(pre.headers.get("Access-Control-Allow-Headers")!, /Authorization/);
});

test("API: create retries when a code is taken", async () => {
  const { env, rooms } = fakeEnv();
  const realGet = env.ROOM.get;
  let calls = 0;
  env.ROOM.get = (id: unknown) => {
    calls += 1;
    const logic = realGet(id) as RoomLogic;
    if (calls === 1) {
      // The first code drawn is already in use.
      const store = (logic.store as MemoryStore);
      store.room = { code: id as string, seed: 1, team_p1: "closed-city", team_p2: "flood-survivors", version: V,
        token_p1: "x", token_p2: null, created_at: 0, updated_at: 0 };
    }
    return logic;
  };
  const r = await handle(post("/rooms", { team_id: "closed-city", version: V }), env);
  assert.equal(r.status, 201);
  assert.equal(calls, 2);
  assert.equal(rooms.size, 2);
});
