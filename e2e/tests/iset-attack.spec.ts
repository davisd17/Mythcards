import { test, expect } from '@playwright/test';
import { boot, act, resolvePending, state, character } from './mythcards';

test('Iset-Nara divider pulse attack renders through impact', async ({ page }) => {
  const errors: string[] = [];
  page.on('console', message => {
    if (message.type() === 'error' || /SCRIPT ERROR|ERROR:/.test(message.text())) errors.push(message.text());
  });
  page.on('pageerror', error => errors.push(String(error)));
  await boot(page, 42);
  await resolvePending(page);
  const architect = 'p2_a-flood-survivor-iset-nara';
  const enemy = 'p1_r-yuri-volkov';
  expect((await act(page, 'move', enemy, { to: { x: 2, y: 2 } })).success).toBe(true);
  expect((await act(page, 'end_turn', 'p1')).success).toBe(true);
  await resolvePending(page);
  expect((await act(page, 'move', architect, { to: { x: 5, y: 4 } })).success).toBe(true);
  expect((await act(page, 'end_turn', 'p2')).success).toBe(true);
  await resolvePending(page);
  expect((await act(page, 'move', enemy, { to: { x: 4, y: 2 } })).success).toBe(true);
  expect((await act(page, 'end_turn', 'p1')).success).toBe(true);
  await resolvePending(page);
  expect((await act(page, 'move', architect, { to: { x: 4, y: 4 } })).success).toBe(true);
  expect((await act(page, 'end_turn', 'p2')).success).toBe(true);
  await resolvePending(page);
  expect((await act(page, 'end_turn', 'p1')).success).toBe(true);
  await resolvePending(page);
  for (let i = 0; i < 8; i++) {
    const layout = await page.evaluate(() => JSON.parse((window as any).mythcards_ui()));
    if (!layout.popup) break;
    const button = layout.buttons.find((b: any) => b.text === 'Continue' || b.text === 'Close');
    expect(button).toBeTruthy();
    await page.mouse.click(button.center.x, button.center.y);
    await page.waitForTimeout(100);
  }
  await page.waitForTimeout(600);
  const before = character(await state(page), enemy).current_hp;
  await page.screenshot({ path: 'test-results/iset-attack-idle.png' });
  const attack = await act(page, 'attack', architect, { target_id: enemy });
  expect(attack.success, JSON.stringify(attack)).toBe(true);
  await page.waitForTimeout(220);
  await page.screenshot({ path: 'test-results/iset-attack-brace.png' });
  await page.waitForTimeout(130);
  await page.screenshot({ path: 'test-results/iset-attack-impact.png' });
  await page.waitForTimeout(90);
  await page.screenshot({ path: 'test-results/iset-attack-follow-through.png' });
  expect(character(await state(page), enemy).current_hp).toBeLessThan(before);
  expect(errors).toEqual([]);
});
