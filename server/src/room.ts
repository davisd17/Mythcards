// Durable Object Room: one per room code (LLD-network-match.md 4.4). It stores the room and
// its log in SQLite and calls RoomLogic for every rule. The Worker reaches it over RPC.
import { DurableObject } from "cloudflare:workers";
import { RoomLogic, type LogRow, type Reply, type RoomRow, type RoomStore } from "./room_logic.ts";

class SqlStore implements RoomStore {
  sql: SqlStorage;

  constructor(sql: SqlStorage) {
    this.sql = sql;
    sql.exec(`CREATE TABLE IF NOT EXISTS room (code TEXT PRIMARY KEY, seed INTEGER, team_p1 TEXT,
      team_p2 TEXT, version TEXT, token_p1 TEXT, token_p2 TEXT, created_at INTEGER, updated_at INTEGER)`);
    sql.exec(`CREATE TABLE IF NOT EXISTS log (seq INTEGER PRIMARY KEY, seat TEXT, kind TEXT, body TEXT,
      at INTEGER)`);
  }

  getRoom(): RoomRow | null {
    const rows = this.sql.exec("SELECT * FROM room LIMIT 1").toArray();
    return rows.length === 0 ? null : (rows[0] as unknown as RoomRow);
  }

  putRoom(r: RoomRow): void {
    this.sql.exec("INSERT OR REPLACE INTO room VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", r.code, r.seed,
      r.team_p1, r.team_p2, r.version, r.token_p1, r.token_p2, r.created_at, r.updated_at);
  }

  logCount(): number {
    return this.sql.exec("SELECT COUNT(*) AS n FROM log").one().n as number;
  }

  logSince(since: number): LogRow[] {
    return this.sql.exec("SELECT * FROM log WHERE seq >= ? ORDER BY seq", since).toArray() as unknown as LogRow[];
  }

  insertLog(row: LogRow): void {
    this.sql.exec("INSERT INTO log VALUES (?, ?, ?, ?, ?)", row.seq, row.seat, row.kind, row.body, row.at);
  }

  clear(): void {
    this.sql.exec("DELETE FROM log");
    this.sql.exec("DELETE FROM room");
  }
}

export class Room extends DurableObject<object> {
  logic: RoomLogic;

  constructor(ctx: DurableObjectState, env: object) {
    super(ctx, env);
    this.logic = new RoomLogic(new SqlStore(ctx.storage.sql));
  }

  async create(code: string, teamId: string, version: string): Promise<Reply> {
    return this.touched(await this.logic.create(code, teamId, version));
  }

  async join(version: string): Promise<Reply> {
    return this.touched(await this.logic.join(version));
  }

  async fetchLog(token: string, since: number): Promise<Reply> {
    return this.logic.fetchLog(token, since);
  }

  async append(token: string, entry: Record<string, unknown>): Promise<Reply> {
    return this.touched(await this.logic.append(token, entry));
  }

  async alarm(): Promise<void> {
    if (!this.logic.expire()) await this.scheduleCleanup();
  }

  // Every successful write moves the cleanup alarm to 30 days after it.
  private async touched(result: Reply): Promise<Reply> {
    if (result.status < 300) await this.scheduleCleanup();
    return result;
  }

  private async scheduleCleanup(): Promise<void> {
    const at = this.logic.expiresAt();
    if (at !== null) await this.ctx.storage.setAlarm(at);
  }
}
