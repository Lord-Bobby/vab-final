extends Control
class_name LoveMeter

@export var max_value: int = 50
@export var value: int = 50

# Size (each "unit" is px_w wide; total width = max_value * px_w)
@export var px_w: int = 2
@export var px_h: int = 10

# Set these to 0 to avoid any visual inset
@export var border_px: int = 0
@export var padding: int = 0

# Colors (used if textures are off or missing)
@export var color_full: Color = Color(1.0, 0.25, 0.35, 1.0)
@export var color_empty: Color = Color(0.18, 0.18, 0.20, 1.0)
@export var color_border: Color = Color(0.05, 0.05, 0.06, 1.0)

# Texture mode (optional). If enabled, they are tiled across the bar.
@export var use_textures: bool = false
@export var tex_full: Texture2D
@export var tex_empty: Texture2D
@export var tile_textures: bool = true

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_min_size()
	queue_redraw()

func _update_min_size() -> void:
	var total_w: int = max_value * px_w + (border_px + padding) * 2
	var total_h: int = px_h + (border_px + padding) * 2
	custom_minimum_size = Vector2(float(total_w), float(total_h))

func _get_minimum_size() -> Vector2:
	var total_w: int = max_value * px_w + (border_px + padding) * 2
	var total_h: int = px_h + (border_px + padding) * 2
	return Vector2(float(total_w), float(total_h))

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func _draw() -> void:
	var total: Vector2 = _get_minimum_size()
	var inner_x: int = border_px + padding
	var inner_y: int = border_px + padding
	var inner_w: int = max_value * px_w
	var inner_h: int = px_h

	# Border (optional)
	if border_px > 0:
		draw_rect(Rect2(Vector2.ZERO, total), color_border, true)

	# Background
	var bg_rect: Rect2 = Rect2(Vector2(float(inner_x), float(inner_y)), Vector2(float(inner_w), float(inner_h)))
	if use_textures and tex_empty != null:
		draw_texture_rect(tex_empty, bg_rect, tile_textures)
	else:
		draw_rect(bg_rect, color_empty, true)

	# Fill (continuous, no gaps)
	var filled_units: int = clamp(value, 0, max_value)
	var fill_w: int = filled_units * px_w
	if fill_w > 0:
		var fill_rect: Rect2 = Rect2(Vector2(float(inner_x), float(inner_y)), Vector2(float(fill_w), float(inner_h)))
		if use_textures and tex_full != null:
			draw_texture_rect(tex_full, fill_rect, tile_textures)
		else:
			draw_rect(fill_rect, color_full, true)

# --- Public API ---
func set_love(v: int) -> void:
	value = clamp(v, 0, max_value)
	queue_redraw()

func set_love_max(m: int, keep_ratio: bool = true) -> void:
	var new_max: int = max(1, m)
	if keep_ratio:
		var ratio: float = float(value) / float(max_value)
		max_value = new_max
		value = int(round(ratio * float(max_value)))
	else:
		max_value = new_max
		value = clamp(value, 0, max_value)
	_update_min_size()
	queue_redraw()
