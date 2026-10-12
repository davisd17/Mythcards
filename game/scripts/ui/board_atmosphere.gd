class_name BoardAtmosphere
extends RefCounted
# Visual Polish Phase 4 (LLD-atmosphere-phase4.md 3): restrained ambient motion drawn into
# GameBoardView. Every particle's position is a pure function of its index and the time,
# so redraws never flicker and nothing is stored. Each side's territory carries its
# palette's atmosphere, fading out toward the middle of the board like the wash.

const COUNTS := {"ash": 22, "snow": 26, "stars": 22, "quartz": 12}


# region: the side's territory rows on screen. outer_at_bottom: Player 1's side.
static func draw_side(canvas: CanvasItem, palette: SidePalette, region: Rect2, outer_at_bottom: bool, px: float, t: float) -> void:
	match palette.atmosphere:
		"ash":
			_drift(canvas, region, outer_at_bottom, px, t, COUNTS.ash, -0.05, Color("#cdbfae"), palette.accent, 1.6)
		"snow":
			_drift(canvas, region, outer_at_bottom, px, t, COUNTS.snow, 0.07, Color("#eef6f8"), Color("#ffffff"), 1.5)
		"aurora":
			_bands(canvas, region, outer_at_bottom, px, t, [palette.primary, palette.accent], 0.24, px * 0.10)
		"caustics":
			_bands(canvas, region, outer_at_bottom, px, t, [palette.primary.lightened(0.45), palette.primary.lightened(0.25),
					palette.accent.lightened(0.3)], 0.26, 3.0)
		"stars":
			_twinkle(canvas, region, outer_at_bottom, px, t, COUNTS.stars, palette.accent, false)
		"quartz":
			_twinkle(canvas, region, outer_at_bottom, px, t, COUNTS.quartz, palette.accent, true)


# How strongly the atmosphere shows at screen y: full at the outer edge, gone at the inner.
static func fade(region: Rect2, outer_at_bottom: bool, y: float) -> float:
	var from_outer := (region.end.y - y) if outer_at_bottom else (y - region.position.y)
	return clampf(1.0 - from_outer / maxf(1.0, region.size.y), 0.0, 1.0)


static func _seed(i: int, salt: int) -> float:
	var n := (i * 92821 + salt * 68917 + 7) & 0x7fffffff
	n = (n * 1103515245 + 12345) & 0x7fffffff
	return float(n % 10000) / 10000.0


# Motes drifting through the region (speed in regions per second; negative rises).
static func _drift(canvas: CanvasItem, region: Rect2, outer_at_bottom: bool, px: float, t: float, count: int,
		speed: float, color: Color, glint: Color, radius: float) -> void:
	for i in count:
		var phase := fposmod(_seed(i, 1) + t * speed * (0.7 + 0.6 * _seed(i, 2)), 1.0)
		var x := region.position.x + region.size.x * fposmod(_seed(i, 3) + 0.03 * sin(t * 0.8 + i), 1.0)
		var y := region.position.y + region.size.y * phase
		var a := 0.75 * fade(region, outer_at_bottom, y) * sin(PI * phase)
		var c := glint if i % 5 == 0 else color
		canvas.draw_circle(Vector2(x, y), radius * (0.9 + 0.7 * _seed(i, 4)) * maxf(1.0, px / 60.0), Color(c, a))


# Slow wavy light bands across the region: aurora curtains, or water caustics when thin.
static func _bands(canvas: CanvasItem, region: Rect2, outer_at_bottom: bool, px: float, t: float, colors: Array,
		alpha: float, width: float) -> void:
	var steps := 28
	for b in colors.size():
		var base_y := region.position.y + region.size.y * (0.22 + 0.28 * b)
		var points := PackedVector2Array()
		for s in steps + 1:
			var u := float(s) / steps
			var wave := sin(u * TAU * (1.2 + 0.4 * b) + t * (0.5 + 0.17 * b)) * 0.5 \
					+ sin(u * TAU * 2.7 - t * 0.33 + b) * 0.25
			points.append(Vector2(region.position.x + region.size.x * u, base_y + wave * px * 0.22))
		var a := alpha * fade(region, outer_at_bottom, base_y) * (0.75 + 0.25 * sin(t * 0.6 + b))
		canvas.draw_polyline(points, Color(colors[b], a), width, true)


# Points that twinkle in place: stars, or four-point quartz glints.
static func _twinkle(canvas: CanvasItem, region: Rect2, outer_at_bottom: bool, px: float, t: float, count: int,
		color: Color, cross: bool) -> void:
	for i in count:
		var p := Vector2(region.position.x + region.size.x * _seed(i, 5), region.position.y + region.size.y * _seed(i, 6))
		var tw := 0.5 + 0.5 * sin(t * (0.9 + _seed(i, 7)) + TAU * _seed(i, 8))
		var a := (0.2 + 0.7 * tw * tw) * fade(region, outer_at_bottom, p.y)
		if cross:
			var r := px * (0.03 + 0.05 * tw)
			canvas.draw_line(p - Vector2(r, 0), p + Vector2(r, 0), Color(color, a), 1.5)
			canvas.draw_line(p - Vector2(0, r), p + Vector2(0, r), Color(color, a), 1.5)
		else:
			canvas.draw_circle(p, 1.2 + 0.8 * tw, Color(color, a))


# Frost tiles: a few flakes sifting down inside the tile.
static func draw_frost_drift(canvas: CanvasItem, rect: Rect2, t: float, salt: int) -> void:
	for i in 4:
		var phase := fposmod(_seed(i, salt) + t * 0.12, 1.0)
		var x := rect.position.x + rect.size.x * (0.15 + 0.7 * fposmod(_seed(i, salt + 1) + 0.04 * sin(t + i), 1.0))
		var y := rect.position.y + rect.size.y * phase
		canvas.draw_circle(Vector2(x, y), 1.4, Color(1, 1, 1, 0.6 * sin(PI * phase)))


# The convergence: motes slowly orbiting the center, drawn toward it and released.
static func draw_convergence(canvas: CanvasItem, center: Vector2, px: float, t: float, color: Color) -> void:
	for i in 7:
		var angle := TAU * i / 7.0 + t * (0.25 + 0.05 * i)
		var breathe := 0.5 + 0.5 * sin(t * 0.7 + i * 1.3)
		var r := px * (0.55 + 0.30 * breathe)
		canvas.draw_circle(center + Vector2.from_angle(angle) * r, 1.6 + 1.2 * (1.0 - breathe), Color(color, 0.25 + 0.35 * (1.0 - breathe)))
