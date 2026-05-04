# floating_text.gd
# Floating text popups — "+1 Item Name" rises and fades when items are picked up.
extends CanvasLayer

const MAX_POPUPS := 6

var _popups: Array = []

func _process(delta: float) -> void:
	for p in _popups:
		p["age"] += delta
		var t := p["age"] / p["lifetime"]
		if t >= 1.0:
			p["label"].queue_free()
			_popups.erase(p)
			continue
		# Rise upward
		var y_offset := -30.0 * t
		p["label"].position.y = p["base_y"] + y_offset
		# Fade out in last 40% of life
		var alpha := 1.0 if t < 0.6 else (1.0 - (t - 0.6) / 0.4)
		p["label"].modulate = Color(1, 1, 1, alpha)

func show_pickup(item_name: String, world_pos: Vector2) -> void:
	if _popups.size() >= MAX_POPUPS:
		var oldest = _popups[0]
		oldest["label"].queue_free()
		_popups.erase(oldest)

	var lbl := Label.new()
	lbl.text = "+1 " + item_name
	lbl.position = Vector2(world_pos.x - 30.0, world_pos.y - 10.0)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.40))
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.z_index = 400
	add_child(lbl)

	_popups.append({
		"label": lbl,
		"base_y": world_pos.y - 10.0,
		"age": 0.0,
		"lifetime": 1.2,
	})
