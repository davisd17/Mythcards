import { test, expect } from '@playwright/test';
import { boot } from './mythcards';

// HLD 13 step 15: a full match driven only through window.mythcards_dispatch_action,
// played to a win by a simple greedy bot, checking board invariants every turn.
// The loop runs inside the page (one evaluate) because it makes thousands of calls.

for (const seed of [42, 7, 2026]) {
  test(`greedy bots play a full match to a win (seed ${seed})`, async ({ page }) => {
    await boot(page, seed);
    const summary = await page.evaluate(playMatch, { maxTurns: 400 });
    console.log(`seed ${seed}:`, JSON.stringify(summary));
    expect(summary.violations).toEqual([]);
    expect(summary.phase, `still going after ${summary.turns} turns`).toBe('ended');
    expect(['hero_capture', 'army_defeat']).toContain(summary.winCondition);
    expect(summary.actions).toBeGreaterThan(0);
  });
}

// Runs in the browser. Each turn: resolve any drawn-card choice; every character
// attacks an enemy in range if it can, otherwise steps toward the nearest enemy;
// then the turn ends. Only the bridge hooks are used.
function playMatch({ maxTurns }: { maxTurns: number }) {
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
    const pending = s.pending_choice;
    if (!pending || !pending.kind) return;
    let payload: object = pending.kind === 'relic' ? { keep_new: true } : { to_bottom: false };
    if (pending.card_id === 'r-rally-from-the-snow') {
      const hurt = live(s.players[s.active_player_id]).find((c: any) => c.current_hp < c.max_hp);
      payload = { target_id: hurt.instance_id };
    }
    const r = act('deck_choice', s.active_player_id, payload);
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
  return { phase: s.phase, turns: s.turn_number, winner: s.winner_id, winCondition: s.win_condition, actions, violations };
}
