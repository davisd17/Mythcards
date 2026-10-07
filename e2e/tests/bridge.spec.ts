import { test, expect } from '@playwright/test';
import { act, boot, character, resolvePending, state } from './mythcards';

// TestBridge contract and the rules gate, through the real Web export.

test('the web build boots a match and exposes the bridge', async ({ page }) => {
  const s = await boot(page, 42);
  expect(s.phase).toBe('in_progress');
  expect(s.turn_number).toBe(1);
  expect(s.active_player_id).toBe('p1');
  expect(s.deck_seed).toBe(42);
  expect(s.players.p1.characters).toHaveLength(7);
  expect(s.players.p2.characters).toHaveLength(7);
  expect(s.players.p1.pool_ap_max).toBe(2);        // the first turn of the match has 2 AP
  expect(s.deck_size).toBe(13);                    // p1 drew on turn 1
  expect(character(s, 'p1_r-reactor-worker').position).toEqual({ x: 0, y: 0 });
  await expect(page.locator('canvas')).toBeVisible();
});

test('the same seed deals the same deck', async ({ page }) => {
  const first = await boot(page, 7);
  const again = await boot(page, 7);
  expect(again.players.p1.active_relic_id).toBe(first.players.p1.active_relic_id);
  expect(again.active_events).toEqual(first.active_events);
  expect(again.pending_choice).toEqual(first.pending_choice);
});

test('a legal move goes through and spends AP', async ({ page }) => {
  await boot(page, 42);
  await resolvePending(page);
  const r = await act(page, 'move', 'p1_r-reactor-worker', { to: { x: 0, y: 2 } });
  expect(r).toEqual({ success: true });
  const s = await state(page);
  expect(character(s, 'p1_r-reactor-worker').position).toEqual({ x: 0, y: 2 });
  expect(character(s, 'p1_r-reactor-worker').character_ap_remaining).toBe(0);
  expect(s.players.p1.pool_ap_remaining).toBe(1);
});

test('illegal and malformed actions are rejected without changing state', async ({ page }) => {
  await boot(page, 42);
  await resolvePending(page);
  const before = await state(page);
  expect(await act(page, 'move', 'p1_r-reactor-worker', { to: { x: 6, y: 6 } })).toEqual({ success: false, reason: 'illegal move' });
  expect(await act(page, 'move', 'p2_a-flood-survivor-naia', { to: { x: 2, y: 5 } })).toEqual({ success: false, reason: 'not your turn' });
  expect(await act(page, 'end_turn', 'p2')).toEqual({ success: false, reason: 'not your turn' });
  const malformed = await page.evaluate(() => JSON.parse((window as any).mythcards_dispatch_action('{oops')));
  expect(malformed).toEqual({ success: false, reason: 'malformed action JSON' });
  expect(await state(page)).toEqual(before);
});

test('ending the turn hands over with a full pool', async ({ page }) => {
  await boot(page, 42);
  await resolvePending(page);
  expect((await act(page, 'end_turn', 'p1')).success).toBe(true);
  const s = await state(page);
  expect(s.active_player_id).toBe('p2');
  expect(s.turn_number).toBe(2);
  expect(s.players.p2.pool_ap_max).toBe(4);
});
