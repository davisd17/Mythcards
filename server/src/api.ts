// HTTP routing, CORS and request checks (LLD-network-match.md Section 6). Kept apart from
// index.ts so `node --test` can load it without the Workers runtime.
import { MAX_ENTRY_BYTES, isValidCode, randomCode, type Reply } from "./room_logic.ts";

// The Room methods the API calls; the Durable Object stub and the test fake both have them.
export interface RoomApi {
  create(code: string, teamId: string, version: string): Promise<Reply>;
  join(version: string): Promise<Reply>;
  fetchLog(token: string, since: number): Promise<Reply>;
  append(token: string, entry: Record<string, unknown>): Promise<Reply>;
}

export interface Env {
  ROOM: { idFromName(name: string): unknown; get(id: unknown): RoomApi };
}

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Max-Age": "86400",
};

const CREATE_ATTEMPTS = 5;

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });
}

function bearer(request: Request): string {
  const header = request.headers.get("Authorization") ?? "";
  return header.startsWith("Bearer ") ? header.slice(7).trim() : "";
}

async function readJson(request: Request): Promise<Record<string, unknown> | Response> {
  const text = await request.text();
  if (new TextEncoder().encode(text).length > MAX_ENTRY_BYTES) return json(413, { error: "too_large" });
  try {
    const value = JSON.parse(text || "{}");
    if (typeof value !== "object" || value === null || Array.isArray(value)) throw new Error();
    return value;
  } catch {
    return json(400, { error: "bad_json" });
  }
}

function room(env: Env, code: string): RoomApi {
  return env.ROOM.get(env.ROOM.idFromName(code));
}

function send(result: Reply): Response {
  return json(result.status, result.body);
}

export async function handle(request: Request, env: Env): Promise<Response> {
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  const parts = new URL(request.url).pathname.split("/").filter((p) => p !== "");
  if (parts[0] !== "rooms") return json(404, { error: "not_found" });

  // POST /rooms
  if (parts.length === 1 && request.method === "POST") {
    const body = await readJson(request);
    if (body instanceof Response) return body;
    for (let i = 0; i < CREATE_ATTEMPTS; i++) {
      const code = randomCode();
      const result = await room(env, code).create(code, String(body.team_id ?? ""), String(body.version ?? ""));
      if (result.body.error !== "code_taken") return send(result);
    }
    return json(503, { error: "no_free_code" });
  }

  const code = (parts[1] ?? "").toUpperCase();
  if (!isValidCode(code)) return json(404, { error: "no_room" });

  // POST /rooms/{code}/join
  if (parts.length === 3 && parts[2] === "join" && request.method === "POST") {
    const body = await readJson(request);
    if (body instanceof Response) return body;
    return send(await room(env, code).join(String(body.version ?? "")));
  }

  if (parts.length === 3 && parts[2] === "log") {
    const token = bearer(request);
    if (!token) return json(401, { error: "bad_token" });
    // GET /rooms/{code}/log?since=n
    if (request.method === "GET") {
      const since = Number.parseInt(new URL(request.url).searchParams.get("since") ?? "0", 10);
      return send(await room(env, code).fetchLog(token, Number.isNaN(since) ? 0 : since));
    }
    // POST /rooms/{code}/log
    if (request.method === "POST") {
      const body = await readJson(request);
      if (body instanceof Response) return body;
      return send(await room(env, code).append(token, body));
    }
  }

  return json(404, { error: "not_found" });
}
