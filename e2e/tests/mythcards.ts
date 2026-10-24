import { expect, Page } from '@playwright/test';

// Helpers around TestBridge's window hooks (LLD-test-bridge.md). Positions are {x, y}.

export type Pos = { x: number; y: number };
export type State = any;
export type Result = { success: boolean; reason?: string; [key: string]: unknown };

// Loads the Web export and starts a match with a fixed deck seed.
export async function boot(page: Page, seed = 42): Promise<State> {
  await page.goto('/');
  await page.waitForFunction(() => (window as any).mythcards_ready === true, null, { timeout: 90_000 });
  const restarted = await page.evaluate((s) => JSON.parse((window as any).mythcards_new_match(s)), seed);
  expect(restarted).toEqual({ success: true, deck_seed: seed });
  return state(page);
}

export async function state(page: Page): Promise<State> {
  return page.evaluate(() => JSON.parse((window as any).mythcards_get_state()));
}

export async function act(page: Page, action_type: string, actor_id: string, payload: object = {}): Promise<Result> {
  const json = JSON.stringify({ action_type, actor_id, payload });
  return page.evaluate((j) => JSON.parse((window as any).mythcards_dispatch_action(j)), json);
}

// The first legal answer a pending choice's spec offers (see RelicEventDeck.choice_spec).
export function firstChoice(spec: any): object {
  const payload: any = { ...(spec.options?.[0]?.payload ?? {}) };
  if (spec.pick === 'tiles') payload.tiles = spec.tiles.slice(0, spec.count);
  if (spec.pick === 'character') payload.target_id = spec.characters[0];
  if (spec.pick === 'character_tile') {
    payload.target_id = spec.characters[0];
    payload.to = spec.tiles_by_character[spec.characters[0]][0];
  }
  return payload;
}

// Resolves a waiting drawn-card choice with its first legal answer, if there is one.
export async function resolvePending(page: Page): Promise<void> {
  const s = await state(page);
  const spec = s.pending_choice;
  if (!spec || !spec.pick) return;
  const player = s.decision_player_id ?? s.active_player_id;
  const r = await act(page, 'deck_choice', player, firstChoice(spec));
  expect(r.success, JSON.stringify(r)).toBe(true);
}

export function character(s: State, instanceId: string): any {
  for (const p of Object.values<any>(s.players)) {
    const c = p.characters.find((ch: any) => ch.instance_id === instanceId);
    if (c) return c;
  }
  return undefined;
}

// Runs in the browser. Each turn: resolve any drawn-card choice; every character
// attacks an enemy in range if it can, else an enemy object (Stones), otherwise steps
// toward the nearest enemy;
// then the turn ends. Only the bridge hooks are used. With stopAtClaim it returns as soon
// as an attack gains its attacker a Spirit Ember (the claimer is in `claimer`).
export function playMatch({ maxTurns, stopAtClaim = false }: { maxTurns: number; stopAtClaim?: boolean }) {
  const w = window as any;
  const get = () => JSON.parse(w.mythcards_get_state());
  const act = (action_type: string, actor_id: string, payload: object = {}) =>
    JSON.parse(w.mythcards_dispatch_action(JSON.stringify({ action_type, actor_id, payload })));
  const dist = (a: any, b: any) => Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
  const live = (p: any) => p.characters.filter((c: any) => !c.defeated);
  const violations: string[] = [];
  let actions = 0;

  const checkInvariants = (s: any) => {
    const seen = new Map<string, string>();
    for (const p of Object.values<any>(s.players)) {
      for (const c of live(p)) {
        if (c.current_hp <= 0) violations.push(`turn ${s.turn_number}: ${c.instance_id} alive at ${c.current_hp} HP`);
        if (c.character_ap_remaining < 0) violations.push(`turn ${s.turn_number}: ${c.instance_id} negative AP`);
        if (c.mounted_with_id !== '' && !c.is_mounted_rider) continue; // a ridden Mount shares the rider's tile
        const key = `${c.position.x},${c.position.y}`;
        if (seen.has(key)) violations.push(`turn ${s.turn_number}: ${c.instance_id} and ${seen.get(key)} share ${key}`);
        seen.set(key, c.instance_id);
      }
      if (p.pool_ap_remaining < 0) violations.push(`turn ${s.turn_number}: negative pool AP`);
    }
  };

  const resolveChoice = (s: any) => {
    // Same as firstChoice in mythcards.ts, repeated because this code runs inside the page.
    const spec = s.pending_choice;
    if (!spec || !spec.pick) return;
    const payload: any = { ...(spec.options?.[0]?.payload ?? {}) };
    if (spec.pick === 'tiles') payload.tiles = spec.tiles.slice(0, spec.count);
    if (spec.pick === 'character') payload.target_id = spec.characters[0];
    if (spec.pick === 'character_tile') {
      payload.target_id = spec.characters[0];
      payload.to = spec.tiles_by_character[spec.characters[0]][0];
    }
    const r = act('deck_choice', s.decision_player_id ?? s.active_player_id, payload);
    if (!r.success) violations.push(`turn ${s.turn_number}: choice failed: ${r.reason}`);
  };

  let s = get();
  while (s.phase === 'in_progress' && s.turn_number <= maxTurns) {
    checkInvariants(s);
    resolveChoice(s);
    const me = s.active_player_id;
    const them = me === 'p1' ? 'p2' : 'p1';
    for (const c of live(s.players[me])) {
      if (s.phase !== 'in_progress') break;
      if (c.mounted_with_id !== '' && !c.is_mounted_rider) continue;
      const enemies = live(s.players[them]).filter((e: any) => !(e.mounted_with_id !== '' && !e.is_mounted_rider));
      // Attack the weakest enemy in range, if any.
      const byHp = [...enemies].sort((a: any, b: any) => a.current_hp - b.current_hp);
      let done = false;
      for (const e of byHp) {
        const r = act('attack', c.instance_id, { target_id: e.instance_id });
        if (r.success) { actions++; done = true; break; }
        if (r.reason === 'no pool AP remaining') break;
      }
      if (done && stopAtClaim) {
        const after = get().players[me].characters.find((x: any) => x.instance_id === c.instance_id);
        if (after.spirit_ember_count > c.spirit_ember_count)
          return { claimer: c.instance_id, phase: get().phase, turns: s.turn_number, winner: '', winCondition: '', actions, violations };
      }
      // No character in range: break an enemy object in the way (Stones wall lines off).
      if (!done) {
        for (const o of get().objects ?? []) {
          if (o.owner === me) continue;
          const r = act('attack', c.instance_id, { target_pos: o.position });
          if (r.success) { actions++; done = true; break; }
        }
      }
      s = get();
      if (done || s.phase !== 'in_progress') continue;
      // Otherwise step toward the nearest enemy (or at least somewhere no farther).
      const nearest = (pos: any) => Math.min(...enemies.map((e: any) => dist(pos, e.position)));
      const here = nearest(c.position);
      const tiles = [];
      for (let y = 0; y < 7; y++) for (let x = 0; x < 7; x++) tiles.push({ x, y });
      tiles.sort((a, b) => nearest(a) - nearest(b));
      for (const t of tiles) {
        if (nearest(t) > here) break;
        if (t.x === c.position.x && t.y === c.position.y) continue;
        const r = act('move', c.instance_id, { to: t });
        if (r.success) { actions++; break; }
        if (r.reason === 'no pool AP remaining') break;
      }
      s = get();
    }
    if (s.phase !== 'in_progress') break;
    s = get();
    resolveChoice(s);
    const end = act('end_turn', me);
    if (!end.success) violations.push(`turn ${s.turn_number}: end_turn failed: ${end.reason}`);
    s = get();
  }
  checkInvariants(s);
  return { claimer: '', phase: s.phase, turns: s.turn_number, winner: s.winner_id, winCondition: s.win_condition, actions, violations };
}
