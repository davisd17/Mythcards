# MythCards UI Style and Responsive Layout Guide

Version 1 - 2026-10-17

Status: proposed implementation contract. This document does not change the running
game. Apply the first phase below before broad visual redesign.

## 1. Purpose

Make the Godot game feel like one designed product at every window size. Controls
of the same role must keep the same height, typography, padding, and states.
Resizing changes placement and column count, not individual button proportions.

Keep the existing occult tactical diorama direction from
[`VISUAL_POLISH_PHASE_1.md`](../VISUAL_POLISH_PHASE_1.md). The board and figures
remain the focus. Interface chrome is restrained charcoal, ivory text, brass
emphasis, and limited faction accents. No paid assets or new UI framework.

Scope: match HUD, deployment, action controls, menus/settings, card overlays,
choice dialogs, notices, log, and match results. Do not change game rules.

## 2. Current Findings

The current implementation is primarily in
[`game_screen.gd`](../game/scripts/ui/game_screen.gd).

| Observed implementation | Consequence or risk |
| --- | --- |
| `_button()` sets a 78-unit minimum height | A minimum is not a fixed final height |
| Wide buttons use a 280-unit minimum width and word wrapping | Label length and available space can change row height |
| `_side`, `_options`, and `_chips` are flow containers | Flow wrapping is useful, but is not an equal-width column contract |
| Only End turn expands in the command row | Width differences are intentional there, but currently unspecified |
| `_chip()` uses 320x60, font 24, radius 12 | Interactive chips follow different sizing/style rules |
| `_notice_button` overrides its font to 18 | Some interactive text can be much smaller than other controls |
| `_fit_board()` changes a board stretch ratio only | It is not a complete responsive HUD policy |
| `_build_menu()` uses fixed offsets and different width assumptions | Menu content can demand more space than its frame |

These are source-level findings, not a fresh resize-test report. Older screenshot
references are in `docs/visual-polish-phase4/`; recapture the current build.

## 3. Units and Readability

The current project uses a 720x1280 reference viewport, `canvas_items` stretching,
and `expand` aspect behavior in [`project.godot`](../game/project.godot).

The tokens below are **Godot logical UI units**, not physical display pixels.
For an exact-aspect 360x640 surface, the nominal scale is 0.5: an 88-unit control
renders at about 44 pixels and a 32-unit font at about 16 pixels. At 405x720 the
nominal scale is 0.5625. Other aspect ratios and embedded canvas sizes must be
measured; do not assume these conversions apply everywhere.

- Project target: interactive controls at least 44x44 rendered CSS pixels in the
  web export, or equivalent native-window logical pixels. Device pixels are not
  the same thing as CSS pixels.
- Main button and body text target: at least 16 rendered pixels at supported sizes.
- Do not solve overflow by continually shrinking fonts with window width.
- Keep the existing stretch configuration in the first phase. If a supported
  short/landscape surface makes controls too small, define a single discrete UI
  scale mode centrally and reflow the layout. Do not patch individual buttons.
- Treat board tags separately from menus and commands; increasing every board
  annotation to body-text size would obscure the pieces.

## 4. Shared Tokens

These are proposed product defaults, not a claim that the current UI uses them.

| Token | Logical value | Use |
| --- | --- | --- |
| `control_height` | 88 | All ordinary commands, primary and secondary alike |
| `control_height_large` | 104 | Optional spacious dialog CTA tier; never mixed in an ordinary action row |
| `icon_control_size` | 88x88 | Close, log, menu, back, other utility controls |
| `choice_row_height` | 128 | Dedicated two-line roster/choice list items |
| `control_padding_x` / `control_padding_y` | 24 / 16 | Shared internal space |
| `control_gap` | 16 | Between adjacent controls |
| `section_gap` | 24 | Between HUD groups |
| `page_inset` | 24 | Content edge, plus platform safe-area inset |
| `radius_control` / `radius_panel` | 6 / 6 | Match existing restrained shapes; maximum 8 |
| `border_width` / `focus_width` | 2 / 4 | Reserve state geometry so focus does not resize anything |
| `font_button` / `font_body` | 32 / 32 | Commands and normal reading |
| `font_secondary` | 28 | Nonessential metadata only; not primary commands |
| `font_heading` | 36 | Compact screen/dialog headings, not hero typography |

Use the existing font initially. Letter spacing stays zero. Different tiers must
be named roles, never accidental results of label length. A tappable character
summary/card is a framed content item, not an 88-unit command button.

## 5. Button Contract

### Size and Width

- Primary emphasis changes color, not height or font size. End turn is not taller
  than Log/Menu beside it.
- Commands use one line. Keep the label stable across hover, press, focus, disabled,
  and busy states. A spinner replaces/reserves an icon slot without changing width.
- Ordinary commands never gain height through automatic wrapping.
- Action groups use equal-width slots. One column fills the action region; two
  columns split its available width equally after the gap. Incomplete rows retain
  the same column width instead of stretching the last button across both columns.
- Choose column count from available action-region width and measured label fit.
  Do not hardcode a 280-unit width independently on each child.
- Utility icons are square. End turn may take the remaining command-row width;
  Log and Menu may not expand into unrelated oversized rectangles.
- Cap the wide-screen action region at 360 rendered pixels. Extra desktop width
  goes to layout/board space, not a screen-wide ability button.
- In dedicated choice lists, allow exactly two lines in the 128-unit row tier.
  Every sibling uses that tier, including short labels. More detail belongs in
  the inspection panel. Do not hide the only distinguishing part of a choice.

### Long Labels

First widen/reflow the group. Next use a deliberately concise visible command,
with the ability's full name in the selected-character detail area. Preserve the
actual action and identity; do not ambiguously shorten destructive choices.
For unavoidable detailed choices, use the dedicated two-line list, not a taller
one-off action button. Tooltips alone are insufficient on touch devices.

### Semantics and States

- One primary progression command per local region: End turn, Confirm, Continue.
- Normal actions use the neutral style; destructive confirmations use warning red.
- On/off settings use toggles/checkboxes; option sets use menus or segmented choices.
- Use familiar utility icons with accessible names and hover/focus tooltips. Reuse
  existing assets, or add a small consistent licensed icon set; no emoji icons.
- Support normal, hover, pressed, focused, disabled, and busy states explicitly.
- Focus must remain visible over primary and secondary fills. Do not rely on color
  alone for selected state. Disabled actions retain readable labels and a reason
  in supporting state text or a touch-accessible explanation.
- Hover/focus must not change padding, font weight metrics, borders, or dimensions.
- Do not animate button scale; use color/opacity feedback without layout movement.

## 6. Color and Surface Roles

Preserve the existing palette rather than inventing a separate theme per screen.

| Role | Starting value |
| --- | --- |
| App background | `#0b0f0e` |
| Panel surface | `#171c1b` |
| Neutral control | `#222928` |
| Hover surface | `#303937` |
| Standard text | `#e9e5db` |
| Primary brass | `#c9a45c` |
| Text on brass | `#1a1916` |
| Neutral border | `#4b5552` |

Faction colors communicate ownership, not button sizing. Keep warning red,
selection green, and water/ley cyan reserved for their established meanings.
Verify text contrast rather than assuming these starting swatches pass every
state: target 4.5:1 for normal text and 3:1 for significant UI boundaries/focus.
Keep textures and bright effects off reading surfaces. Do not nest decorative
cards or turn every section into a floating panel.

## 7. Responsive Layout Rules

Use available **rendered game-surface** width, excluding safe-area insets, to
select a layout mode. Do not confuse it with the OS screen or raw stretched
Godot viewport dimensions. Define that conversion once for native and web.

| Mode | Proposed trigger | Behavior |
| --- | --- | --- |
| Narrow | Width below 600 rendered px | Header, compact status, board, selected summary, action group stacked |
| Medium | Width 600-999 rendered px | Board and details may share space only if both remain readable |
| Wide | Width at least 1000 rendered px and height at least 600 | Board with constrained side details/actions, not an expanding bottom strip |
| Short | Height below 600 rendered px | Explicit landscape layout; scroll secondary content, keep commands reachable |

These are layout breakpoints, not font-size interpolation rules. If minimum
content widths do not fit, fall back to the narrower layout regardless of label.

- Maintain a square board drawing region and stable 7x7 tile geometry. Fit it
  into remaining space; do not stretch tiles to rectangular cells.
- Keep End turn and core match information reachable. Scroll long details,
  choices, or logs inside bounded regions instead of growing the whole HUD.
- Use vertical scrolling for narrow action lists; avoid horizontal scrolling
  for commands. Never leave actions below the window with no scroll access.
- Distinguish interactive relic chips from passive counters. Relic buttons meet
  the control hit-target rule; passive Deck/Embers counters need not look tappable.
- On narrow screens, cap the inline status summary and provide an accessible
  details surface rather than allowing status rows to grow without bound.
- Dialog width is constrained by the available viewport and readable content;
  dialog body scrolls, footer actions remain reachable. Respect safe areas.
- Resizing retains selection, action mode, keyboard focus, modal state, and scroll
  position where meaningful. It must not restart the match or recreate rules state.

## 8. Godot Implementation Guidance

Keep this a small presentation-layer change, not a rewrite of `game_screen.gd`.

1. Centralize tokens and Theme variations in one shared UI module/resource.
   Evolve `_build_ui_theme()` and `_button()` into that source of truth. Route
   `_chip()`, notice buttons and dialog commands through named role helpers.
2. Let containers own layout. Do not repeatedly assign `size` or offsets to a
   child whose parent Container will immediately assign them again.
3. `custom_minimum_size` supplies a floor, not a fixed-size guarantee. Implement
   the height contract using nonexpanding vertical sizing, one-line content,
   consistent theme margins, and a tested sizing wrapper if needed. Check the
   control's combined minimum size before imposing a smaller tier.
4. Use equal-width action slots. A FlowContainer is not an equal-column layout;
   neither should an unconfigured GridContainer be assumed to make all columns
   equal. Compute/assign the shared slot width at the group level.
5. Reserve FlowContainer for deliberately variable-width content such as passive
   badges. Keep fixed role metrics when a group changes column count.
6. Recalculate on resize, coalescing layout work once per frame. Do not recreate
   the UI every frame or let wrap/height changes oscillate near a breakpoint.
7. Keep long content in bounded ScrollContainers with sensible minimum sizes.
   Share the same layout policy between web and native; no browser-only CSS patch
   that merely stretches the Godot canvas.
8. Keep card art, figure scale, attack registration, gameplay and animation timing
   unchanged. This task owns UI presentation only.

Godot references: [Control sizing and themes](https://docs.godotengine.org/en/stable/classes/class_control.html),
[container layout](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html),
and [multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html).
Check API availability against this project's installed Godot 4.7.x engine.

## 9. First Phase Handoff

Mission: remove inconsistent button resizing before doing further decoration.

1. Capture the current chooser, deployment, selected-character HUD, menu, pending
   choice, card popup, notice, log and results at the QA sizes below.
2. Implement shared tokens and standard command/icon/choice-row variants. Replace
   ad hoc metrics in `_button`, `_chip`, `_notice_button`, `_accent`, and menu sizing.
3. Normalize action-group heights/columns. Remove ordinary command autowrapping
   and oversized desktop expansion. Preserve all callbacks and legal-action logic.
4. Add narrow/wide/short layout modes and bounded scrolling. Keep the board visible
   and the primary command reachable before tuning secondary presentation.
5. Extend `ui_snapshot()` for tests with stable role/id, rect, text, visibility,
   and enabled state. Preserve current fields used by existing browser tests.
   Convert measured rects into rendered/CSS units before asserting touch sizes.
6. Add focused GUT and Playwright resize tests; run the existing suite and inspect
   screenshots. Deliver before/after images, the tested size matrix, and residual
   issues. Do not claim the UI is fixed from a theme/token-only test.

Do not start a card redesign, buy fonts/assets, change game rules, replace the
animation pipeline, or push to GitHub unless separately requested.

## 10. Acceptance and QA

Test 360x640, 390x844, 405x720, 768x1024, 844x390, 1280x720, and 1920x1080.
Also test widths immediately above/below each layout breakpoint, a long character
name, the longest ability/choice labels, disabled actions, and a pending popup.
Resize the same running match portrait -> landscape -> desktop -> portrait.

- Same-role command heights differ by at most 1 rendered pixel within a mode.
- Equal-width action siblings differ by at most 1 rendered pixel; an incomplete
  grid row does not stretch its remaining item.
- Every interactive control meets the rendered 44x44 target. Text meets its
  defined readability floor without being clipped or scaled down to fit a label.
- Normal commands remain one line. Choice rows have consistent two-line bounds.
- No text/control overlap, offscreen footer, clipped focus ring, hidden action,
  whole-screen horizontal scrolling, or layout jitter during continuous resizing.
- Hover, focus, press, disabled, busy and translated/long-label samples retain
  geometry. Focus order and touch interaction remain usable after reflow.
- The board stays square, pieces retain their existing proportions, and rules,
  selection, turn/AP behavior and attack playback are unchanged.
- Screenshots are visually inspected, not only recorded. Tests distinguish
  intended overlays from accidental overlap and exclude hidden/freed controls.

Verification entry points: `tools/run_game_tests.ps1`, `tools/run_e2e.ps1`,
`game/tests/unit/test_game_screen.gd`, and `e2e/tests/`. Add a focused responsive-UI
test file rather than changing every unrelated gameplay test.
