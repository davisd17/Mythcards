// The rules of one room (LLD-network-match.md 4.4), over a storage interface so they run
// both in the Durable Object (SQLite) and under `node --test` (in memory).
// Uses only Web Crypto, which Workers and Node both provide.

export const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ"; // no I, L, O
export const CODE_LENGTH = 6;
export const MAX_ENTRY_BYTES = 8 * 1024;
export const ROOM_TTL_MS = 30 * 24 * 60 * 60 * 1000;

// The creator plays p1 with their team; p2 gets the other one (`[NEED]` coin flip, LLD 9).
export const OPPONENT_TEAM: Record<string, string> = {
  "closed-city": "flood-survivors",
  "flood-survivors": "closed-city",
};

export type Seat = "p1" | "p2";

export interface RoomRow {
  code: string;
  seed: number;
  team_p1: string;
  team_p2: string;
  version: string;
  token_p1: string; // SHA-256 hex of the token
  token_p2: string | null;
  created_at: number;
  updated_at: number;
}

export interface LogRow {
  seq: number;
  seat: Seat;
  kind: string;
  body: string; // the whole entry as JSON
  at: number;
}

export interface RoomStore {
  getRoom(): RoomRow | null;
  putRoom(room: RoomRow): void;
  logCount(): number;
  logSince(since: number): LogRow[];
  insertLog(row: LogRow): void;
  clear(): void;
}

export interface Reply {
  status: number;
  body: Record<string, unknown>;
}

function reply(status: number, body: Record<string, unknown>): Reply {
  return { status, body };
}

export function randomCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(CODE_LENGTH));
  let code = "";
  for (const b of bytes) code += CODE_ALPHABET[b % CODE_ALPHABET.length];
  return code;
}

export function isValidCode(code: string): boolean {
  return code.length === CODE_LENGTH && [...code].every((c) => CODE_ALPHABET.includes(c));
}

function randomToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(24));
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function randomSeed(): number {
  return crypto.getRandomValues(new Uint32Array(1))[0] >>> 1; // 31 bits
}

export async function hashToken(token: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export class RoomLogic {
  store: RoomStore;
  now: () => number;

  constructor(store: RoomStore, now: () => number = Date.now) {
    this.store = store;
    this.now = now;
  }

  async create(code: string, teamId: string, version: string): Promise<Reply> {
    if (!(teamId in OPPONENT_TEAM)) return reply(400, { error: "unknown_team" });
    if (this.store.getRoom() !== null) return reply(409, { error: "code_taken" });
    const token = randomToken();
    const now = this.now();
    const room: RoomRow = {
      code, seed: randomSeed(), team_p1: teamId, team_p2: OPPONENT_TEAM[teamId], version,
      token_p1: await hashToken(token), token_p2: null, created_at: now, updated_at: now,
    };
    this.store.putRoom(room);
    return reply(201, { code, seat: "p1", token, ...this.summary(room) });
  }

  async join(version: string): Promise<Reply> {
    const room = this.store.getRoom();
    if (room === null) return reply(404, { error: "no_room" });
    if (room.token_p2 !== null) return reply(409, { error: "seat_taken" });
    if (version !== room.version) {
      return reply(409, { error: "version_mismatch", room_version: room.version, your_version: version });
    }
    const token = randomToken();
    room.token_p2 = await hashToken(token);
    room.updated_at = this.now();
    this.store.putRoom(room);
    return reply(200, { seat: "p2", token, ...this.summary(room) });
  }

  async fetchLog(token: string, since: number): Promise<Reply> {
    const room = this.store.getRoom();
    if (room === null) return reply(404, { error: "no_room" });
    const seat = await this.seatFor(room, token);
    if (seat === null) return reply(401, { error: "bad_token" });
    const deployed = this.deployedSeats();
    const entries = this.store.logSince(Math.max(0, since)).map((row) => {
      if (row.kind === "deploy" && row.seat !== seat && !deployed.has(seat)) {
        return { seq: row.seq, seat: row.seat, kind: "deploy_hidden" };
      }
      return JSON.parse(row.body);
    });
    return reply(200, { entries, next: this.store.logCount(), status: this.status(room), ...this.summary(room) });
  }

  async append(token: string, entry: Record<string, unknown>): Promise<Reply> {
    const room = this.store.getRoom();
    if (room === null) return reply(404, { error: "no_room" });
    const seat = await this.seatFor(room, token);
    if (seat === null) return reply(401, { error: "bad_token" });
    const next = this.store.logCount();
    if (entry.seq !== next) return reply(409, { error: "seq_conflict", next });
    const kind = entry.kind;
    const deployed = this.deployedSeats();
    if (kind === "deploy") {
      if (deployed.has(seat)) return reply(409, { error: "already_deployed" });
    } else if (kind === "action") {
      if (deployed.size < 2) return reply(409, { error: "not_started" });
    } else {
      return reply(400, { error: "unknown_kind" });
    }
    const now = this.now();
    // The seat always comes from the token, never from the body.
    const stored = { ...entry, seat };
    this.store.insertLog({ seq: next, seat, kind, body: JSON.stringify(stored), at: now });
    room.updated_at = now;
    this.store.putRoom(room);
    return reply(200, { next: next + 1 });
  }

  // The cleanup alarm: true if the room expired and was deleted.
  expire(): boolean {
    const room = this.store.getRoom();
    if (room === null) return false;
    if (this.now() < room.updated_at + ROOM_TTL_MS) return false;
    this.store.clear();
    return true;
  }

  expiresAt(): number | null {
    const room = this.store.getRoom();
    return room === null ? null : room.updated_at + ROOM_TTL_MS;
  }

  private summary(room: RoomRow): Record<string, unknown> {
    return { seed: room.seed, teams: { p1: room.team_p1, p2: room.team_p2 }, version: room.version };
  }

  private status(room: RoomRow): string {
    if (room.token_p2 === null) return "waiting_for_join";
    return this.deployedSeats().size < 2 ? "deploying" : "playing";
  }

  private deployedSeats(): Set<Seat> {
    const seats = new Set<Seat>();
    for (const row of this.store.logSince(0)) if (row.kind === "deploy") seats.add(row.seat);
    return seats;
  }

  private async seatFor(room: RoomRow, token: string): Promise<Seat | null> {
    if (!token) return null;
    const hashed = await hashToken(token);
    if (hashed === room.token_p1) return "p1";
    if (room.token_p2 !== null && hashed === room.token_p2) return "p2";
    return null;
  }
}

// An in-memory RoomStore, for tests.
export class MemoryStore implements RoomStore {
  room: RoomRow | null = null;
  log: LogRow[] = [];

  getRoom(): RoomRow | null {
    return this.room === null ? null : { ...this.room };
  }
  putRoom(room: RoomRow): void {
    this.room = { ...room };
  }
  logCount(): number {
    return this.log.length;
  }
  logSince(since: number): LogRow[] {
    return this.log.filter((row) => row.seq >= since);
  }
  insertLog(row: LogRow): void {
    this.log.push(row);
  }
  clear(): void {
    this.room = null;
    this.log = [];
  }
}
