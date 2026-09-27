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

// Resolves a waiting drawn-card choice with a simple default, if there is one.
export async function resolvePending(page: Page): Promise<void> {
  const s = await state(page);
  const pending = s.pending_choice;
  if (!pending || !pending.kind) return;
  const player = s.active_player_id;
  let payload: object = pending.kind === 'relic' ? { keep_new: true } : { to_bottom: false };
  if (pending.card_id === 'r-rally-from-the-snow') {
    const hurt = s.players[player].characters.find((c: any) => !c.defeated && c.current_hp < c.max_hp);
    payload = { target_id: hurt.instance_id };
  }
  const r = await act(page, 'deck_choice', player, payload);
  expect(r.success, JSON.stringify(r)).toBe(true);
}

export function character(s: State, instanceId: string): any {
  for (const p of Object.values<any>(s.players)) {
    const c = p.characters.find((ch: any) => ch.instance_id === instanceId);
    if (c) return c;
  }
  return undefined;
}
