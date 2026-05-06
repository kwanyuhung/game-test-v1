extends Node2D
class_name FloorBuilder

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")
const FoodStallScript = preload("res://scripts/food_stall.gd")
const ClawMachineScript = preload("res://scripts/claw_machine.gd")

const CELL_SIZE = 16
const WORLD_W  = 96
const WORLD_H  = 50

func _build_zone_home_decor(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "HOME DECOR")
	var zone_color: Color = zone.meta.get("color", Color(0.78, 0.65, 0.50))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Display shelves with decor items
	var item_colors := [Color(0.80, 0.60, 0.45), Color(0.70, 0.55, 0.60), Color(0.60, 0.70, 0.65), Color(0.90, 0.75, 0.55)]
	for row in range(4):
		var sy := cy + 14 + row * (ch * 0.22)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(6):
			var ix := cx + 6 + col * ((cw - 12) / 6.0)
			var ih := 10 + (col % 3) * 4
			var item := ColorRect.new()
			item.position = Vector2(ix, sy - ih); item.size = Vector2((cw - 12) / 7.0, ih)
			item.color = item_colors[(row + col) % item_colors.size()]
			_parent.add_child(item); _floor_nodes.append(item)

func _build_zone_furniture(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "FURNITURE")
	var zone_color: Color = zone.meta.get("color", Color(0.65, 0.55, 0.48))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Furniture display items — sofa, table, chair silhouettes
	var items := [
		{"type": "sofa", "x": 0.1, "w": 0.35, "h": 0.35, "col": Color(0.55, 0.45, 0.42)},
		{"type": "table", "x": 0.5, "w": 0.25, "h": 0.25, "col": Color(0.50, 0.40, 0.32)},
		{"type": "chair", "x": 0.78, "w": 0.15, "h": 0.30, "col": Color(0.60, 0.50, 0.44)},
	]
	for it in items:
		var ix := cx + cw * it["x"]; var iw := cw * it["w"]; var ih := ch * it["h"]
		var furn := ColorRect.new()
		furn.position = Vector2(ix, cy + ch * 0.5 - ih * 0.3)
		furn.size = Vector2(iw, ih); furn.color = it["col"]
		_parent.add_child(furn); _floor_nodes.append(furn)

func _build_zone_outdoor_living(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "OUTDOOR LIVING")
	var zone_color: Color = zone.meta.get("color", Color(0.55, 0.70, 0.52))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Umbrella table, patio chair, BBQ grill display
	var pat_colors := [Color(0.50, 0.72, 0.55), Color(0.68, 0.60, 0.48), Color(0.45, 0.58, 0.50)]
	for row in range(3):
		var ry := cy + 16 + row * (ch * 0.28)
		for col in range(3):
			var rx := cx + 8 + col * ((cw - 16) / 3.0)
			var rh := 16 + (row * 4)
			var rect := ColorRect.new()
			rect.position = Vector2(rx, ry - rh); rect.size = Vector2((cw - 16) / 3.5, rh)
			rect.color = pat_colors[(row + col) % pat_colors.size()]
			_parent.add_child(rect); _floor_nodes.append(rect)

func _build_zone_organization(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "ORGANIZATION")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.60, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Stackable storage boxes
	for row in range(3):
		var sy := cy + 14 + row * (ch * 0.28)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(5):
			var bx := cx + 6 + col * ((cw - 12) / 5.0)
			var box := ColorRect.new()
			box.position = Vector2(bx, sy - 12); box.size = Vector2((cw - 12) / 6.0, 12)
			box.color = zone_color.lightened(0.1) if (col % 2 == 0) else zone_color.darkened(0.1)
			_parent.add_child(box); _floor_nodes.append(box)

func _build_zone_lighting(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "LIGHTING")
	var zone_color: Color = zone.meta.get("color", Color(0.90, 0.85, 0.60))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.1)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Lamp displays with glow effect
	for row in range(3):
		var ly := cy + 20 + row * (ch * 0.28)
		for col in range(4):
			var lx := cx + 8 + col * ((cw - 16) / 4.0)
			var shade_h := 14 + (col % 2) * 6
			# Lamp shade
			var shade := ColorRect.new()
			shade.position = Vector2(lx, ly - shade_h); shade.size = Vector2((cw - 16) / 5.0, shade_h)
			shade.color = zone_color.lightened(0.1)
			_parent.add_child(shade); _floor_nodes.append(shade)
			# Glow
			var glow := ColorRect.new()
			glow.position = Vector2(lx + 2, ly - shade_h + 2); glow.size = Vector2((cw - 16) / 5.0 - 4, shade_h - 4)
			glow.color = Color(1.0, 0.98, 0.80, 0.6)
			_parent.add_child(glow); _floor_nodes.append(glow)


func _build_zone_customer_service(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "CUSTOMER SERVICE")
	var zone_color: Color = zone.meta.get("color", Color(0.50, 0.55, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.25); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Service counter
	var counter := ColorRect.new()
	counter.position = Vector2(cx + 4, cy + ch * 0.4); counter.size = Vector2(cw - 8, ch * 0.35)
	counter.color = Color(0.35, 0.38, 0.50); _parent.add_child(counter); _floor_nodes.append(counter)
	# Counter top
	var top := ColorRect.new()
	top.position = Vector2(cx + 4, cy + ch * 0.4); top.size = Vector2(cw - 8, 3)
	top.color = zone_color.lightened(0.2); _parent.add_child(top); _floor_nodes.append(top)
	# Computer monitor on counter
	var mon := ColorRect.new()
	mon.position = Vector2(cx + cw * 0.3, cy + ch * 0.2); mon.size = Vector2(cw * 0.4, ch * 0.2)
	mon.color = Color(0.15, 0.20, 0.30); _parent.add_child(mon); _floor_nodes.append(mon)
	var scr := ColorRect.new()
	scr.position = Vector2(cx + cw * 0.305, cy + ch * 0.205); scr.size = Vector2(cw * 0.39 - 2, ch * 0.18 - 2)
	scr.color = Color(0.20, 0.50, 0.80); _parent.add_child(scr); _floor_nodes.append(scr)

func _build_zone_loyalty_kiosk(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "LOYALTY CENTER")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.50, 0.75))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Kiosk machine
	var kiosk := ColorRect.new()
	kiosk.position = Vector2(cx + cw * 0.2, cy + ch * 0.15); kiosk.size = Vector2(cw * 0.6, ch * 0.70)
	kiosk.color = Color(0.20, 0.18, 0.28); _parent.add_child(kiosk); _floor_nodes.append(kiosk)
	# Screen
	var screen := ColorRect.new()
	screen.position = Vector2(cx + cw * 0.23, cy + ch * 0.20); screen.size = Vector2(cw * 0.54, ch * 0.45)
	screen.color = Color(0.15, 0.20, 0.60); _parent.add_child(screen); _floor_nodes.append(screen)
	# Card slot
	var slot := ColorRect.new()
	slot.position = Vector2(cx + cw * 0.35, cy + ch * 0.68); slot.size = Vector2(cw * 0.3, 4)
	slot.color = Color(0.10, 0.10, 0.15); _parent.add_child(slot); _floor_nodes.append(slot)
	# Hint text
	var hint := Label.new(); hint.text = "[E] Sign Up"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.70, 0.80, 1.0))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_gift_wrap(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "GIFT WRAPPING")
	var zone_color: Color = zone.meta.get("color", Color(0.72, 0.55, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Wrapping paper rolls display
	var roll_colors := [Color(0.90, 0.30, 0.30), Color(0.30, 0.75, 0.90), Color(0.90, 0.80, 0.30), Color(0.50, 0.90, 0.50)]
	for i in range(4):
		var rx := cx + 8 + i * ((cw - 16) / 4.0)
		var roll := ColorRect.new()
		roll.position = Vector2(rx, cy + ch * 0.25); roll.size = Vector2((cw - 16) / 5.0, ch * 0.5)
		roll.color = roll_colors[i]; _parent.add_child(roll); _floor_nodes.append(roll)
		var core := ColorRect.new()
		core.position = Vector2(rx + 2, cy + ch * 0.25); core.size = Vector2((cw - 16) / 8.0, ch * 0.5)
		core.color = Color(0.80, 0.75, 0.65); _parent.add_child(core); _floor_nodes.append(core)
	var hint := Label.new(); hint.text = "[E] Wrap Gift +XP"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.90, 0.75, 0.90))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_digital_kiosk(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "INFO KIOSK")
	var zone_color: Color = zone.meta.get("color", Color(0.40, 0.65, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 2, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Large touchscreen
	var screen := ColorRect.new()
	screen.position = Vector2(cx + 4, cy + 4); screen.size = Vector2(cw - 8, ch * 0.8)
	screen.color = Color(0.10, 0.15, 0.25); _parent.add_child(screen); _floor_nodes.append(screen)
	var display := ColorRect.new()
	display.position = Vector2(cx + 6, cy + 6); display.size = Vector2(cw - 12, ch * 0.76)
	display.color = Color(0.15, 0.35, 0.60); _parent.add_child(display); _floor_nodes.append(display)
	var hint := Label.new(); hint.text = "[E] Browse"
	hint.position = Vector2(cx + 4, cy + ch - 16)
	hint.add_theme_color_override("font_color", Color(0.60, 0.90, 1.0))
	hint.add_theme_font_size_override("font_size", 6)
	_parent.add_child(hint); _floor_nodes.append(hint)


	var name: String = zone.meta.get("name", "JUICE BAR")
	var zone_color: Color = zone.meta.get("color", Color(1.0, 0.75, 0.30))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Counter
	var counter := ColorRect.new()
	counter.position = Vector2(cx + 4, cy + ch * 0.55); counter.size = Vector2(cw - 8, ch * 0.3)
	counter.color = Color(0.45, 0.38, 0.30); _parent.add_child(counter); _floor_nodes.append(counter)
	# Juicer machine
	var juicer := ColorRect.new()
	juicer.position = Vector2(cx + cw * 0.3, cy + ch * 0.15); juicer.size = Vector2(cw * 0.15, ch * 0.40)
	juicer.color = Color(0.70, 0.70, 0.75); _parent.add_child(juicer); _floor_nodes.append(juicer)
	# Juice dispensers
	var disp_colors := [Color(1.0, 0.60, 0.20), Color(1.0, 0.85, 0.30), Color(0.80, 0.50, 0.30), Color(0.90, 0.40, 0.50)]
	for i in range(4):
		var dx := cx + 8 + i * ((cw - 16) / 4.0)
		var disp := ColorRect.new()
		disp.position = Vector2(dx, cy + ch * 0.20); disp.size = Vector2((cw - 16) / 5.0, ch * 0.35)
		disp.color = disp_colors[i]; _parent.add_child(disp); _floor_nodes.append(disp)
	# Cups display
	var cup := ColorRect.new()
	cup.position = Vector2(cx + cw * 0.55, cy + ch * 0.30); cup.size = Vector2(cw * 0.1, ch * 0.20)
	cup.color = Color(0.90, 0.90, 0.88); _parent.add_child(cup); _floor_nodes.append(cup)

func _build_zone_health_food(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "HEALTH FOODS")
	var zone_color: Color = zone.meta.get("color", Color(0.55, 0.82, 0.58))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	var hf_colors := [Color(0.60, 0.85, 0.65), Color(0.80, 0.90, 0.60), Color(0.90, 0.75, 0.55), Color(0.70, 0.60, 0.80)]
	for row in range(4):
		var sy := cy + 14 + row * (ch * 0.22)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(6):
			var bx := cx + 6 + col * ((cw - 12) / 6.0)
			var item := ColorRect.new()
			item.position = Vector2(bx, sy - 10); item.size = Vector2((cw - 12) / 7.0, 10)
			item.color = hf_colors[(row + col) % hf_colors.size()]
			_parent.add_child(item); _floor_nodes.append(item)

func _build_zone_smoothie(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SMOOTHIE STATION")
	var zone_color: Color = zone.meta.get("color", Color(0.80, 0.55, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Blender display
	for i in range(3):
		var bx := cx + 8 + i * ((cw - 16) / 3.0)
		var blender := ColorRect.new()
		blender.position = Vector2(bx, cy + ch * 0.3); blender.size = Vector2((cw - 16) / 4.0, ch * 0.45)
		blender.color = Color(0.55, 0.55, 0.65); _parent.add_child(blender); _floor_nodes.append(blender)
		var glass := ColorRect.new()
		glass.position = Vector2(bx + 2, cy + ch * 0.15); glass.size = Vector2((cw - 16) / 4.5, ch * 0.30)
		glass.color = [Color(0.90, 0.55, 0.75), Color(0.55, 0.85, 0.75), Color(0.85, 0.75, 0.55)][i]
		_parent.add_child(glass); _floor_nodes.append(glass)

func _build_zone_salad_bar(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SALAD BAR")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.85, 0.60))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Salad ingredient bins
	var ing_colors := [Color(0.60, 0.85, 0.45), Color(0.90, 0.70, 0.40), Color(0.85, 0.80, 0.55), Color(0.70, 0.60, 0.80), Color(0.90, 0.85, 0.60), Color(0.55, 0.80, 0.70)]
	for row in range(3):
		var sy := cy + 14 + row * (ch * 0.28)
		var trough := ColorRect.new()
		trough.position = Vector2(cx + 4, sy); trough.size = Vector2(cw - 8, ch * 0.20)
		trough.color = zone_color.darkened(0.4); _parent.add_child(trough); _floor_nodes.append(trough)
		for col in range(6):
			var bx := cx + 6 + col * ((cw - 12) / 6.0)
			var ing := ColorRect.new()
			ing.position = Vector2(bx, sy + 2); ing.size = Vector2((cw - 12) / 7.0, ch * 0.16)
			ing.color = ing_colors[(row + col) % ing_colors.size()]
			_parent.add_child(ing); _floor_nodes.append(ing)


func _build_zone_kids_play(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "PLAY ZONE")
	var zone_color: Color = zone.meta.get("color", Color(0.80, 0.60, 0.90))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Soft play blocks (colorful squares)
	var block_colors := [Color(0.95, 0.50, 0.50), Color(0.50, 0.85, 0.95), Color(0.95, 0.85, 0.40), Color(0.60, 0.95, 0.60), Color(0.85, 0.60, 0.95)]
	for row in range(4):
		for col in range(6):
			var bx := cx + 8 + col * ((cw - 16) / 6.0)
			var bh := 14 + (col % 2) * 6
			var block := ColorRect.new()
			block.position = Vector2(bx, cy + ch * 0.45 - row * (ch * 0.15))
			block.size = Vector2((cw - 16) / 7.0, bh)
			block.color = block_colors[(row + col) % block_colors.size()]
			_parent.add_child(block); _floor_nodes.append(block)
	# Slide representation
	var slide := ColorRect.new()
	slide.position = Vector2(cx + cw * 0.7, cy + ch * 0.1); slide.size = Vector2(cw * 0.1, ch * 0.6)
	slide.color = Color(0.60, 0.80, 0.95); _parent.add_child(slide); _floor_nodes.append(slide)
	var hint := Label.new(); hint.text = "SUPERVISED — Parents must accompany children"
	hint.position = Vector2(cx + 4, cy + ch - 16)
	hint.add_theme_color_override("font_color", Color(0.90, 0.75, 1.0))
	hint.add_theme_font_size_override("font_size", 6)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_kids_clothing(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "KIDS WEAR")
	var zone_color: Color = zone.meta.get("color", Color(0.90, 0.72, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.1)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Hanging tiny outfits on child-sized racks
	for row in range(3):
		var ry := cy + 18 + row * (ch * 0.26)
		var pole := _make_plank(Vector2(cx + 4, ry), Vector2(cw - 8, 2), Color(0.60, 0.55, 0.50)); _parent.add_child(pole); _floor_nodes.append(pole)
		for h in range(6):
			var hx := cx + 8 + h * ((cw - 16) / 6.0)
			var outfit := ColorRect.new()
			outfit.position = Vector2(hx, ry - 14); outfit.size = Vector2(12, 14)
			outfit.color = [Color(0.95, 0.70, 0.70), Color(0.70, 0.80, 0.95), Color(0.75, 0.95, 0.75), Color(0.95, 0.90, 0.60), Color(0.90, 0.75, 0.90), Color(0.60, 0.90, 0.90)][h]
			_parent.add_child(outfit); _floor_nodes.append(outfit)

func _build_zone_nursing_room(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "NURSING ROOM")
	var zone_color: Color = zone.meta.get("color", Color(0.95, 0.85, 0.90))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.25); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Nursing chair
	var chair := ColorRect.new()
	chair.position = Vector2(cx + cw * 0.25, cy + ch * 0.35); chair.size = Vector2(cw * 0.5, ch * 0.35)
	chair.color = Color(0.85, 0.70, 0.75); _parent.add_child(chair); _floor_nodes.append(chair)
	# Curtain rod
	var rod := _make_plank(Vector2(cx + 4, cy + ch * 0.3), Vector2(cw - 8, 2), Color(0.70, 0.65, 0.60)); _parent.add_child(rod); _floor_nodes.append(rod)
	var hint := Label.new(); hint.text = "[E] Private Room"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.80, 0.60, 0.75))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_family_wc(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "FAMILY WC")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.75, 0.90))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.25); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Toilet icon
	var toilet := ColorRect.new()
	toilet.position = Vector2(cx + cw * 0.3, cy + ch * 0.3); toilet.size = Vector2(cw * 0.4, ch * 0.4)
	toilet.color = Color(0.85, 0.88, 0.92); _parent.add_child(toilet); _floor_nodes.append(toilet)
	# Sink
	var sink := ColorRect.new()
	sink.position = Vector2(cx + cw * 0.25, cy + ch * 0.15); sink.size = Vector2(cw * 0.5, ch * 0.18)
	sink.color = Color(0.80, 0.85, 0.90); _parent.add_child(sink); _floor_nodes.append(sink)
	var hint := Label.new(); hint.text = "FAMILY FACILITIES"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.40, 0.65, 0.85))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_kids_club(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "KIDS CLUB")
	var zone_color: Color = zone.meta.get("color", Color(0.72, 0.80, 0.60))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.15)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Reception desk
	var desk := ColorRect.new()
	desk.position = Vector2(cx + cw * 0.1, cy + ch * 0.3); desk.size = Vector2(cw * 0.35, ch * 0.3)
	desk.color = Color(0.50, 0.60, 0.45); _parent.add_child(desk); _floor_nodes.append(desk)
	# Activity tables
	for i in range(3):
		var tx := cx + cw * 0.5 + i * (cw * 0.15)
		var table := ColorRect.new()
		table.position = Vector2(tx, cy + ch * 0.45); table.size = Vector2(cw * 0.12, ch * 0.25)
		table.color = Color(0.65, 0.75, 0.55); _parent.add_child(table); _floor_nodes.append(table)
	var hint := Label.new(); hint.text = "[E] Sign Kids In ($5/30min) +XP Bonus"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.50, 0.75, 0.50))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _make_zone_label(text: String, pos: Vector2, col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 10)
	return lbl

func _make_plank(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new(); r.position = pos; r.size = sz; r.color = col; return r

# ??? Phase H: Home Electronics & Tech Zones ?????????????????????????????????????

func _build_zone_phone_gadgets(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "PHONES & GADGETS")
	var zone_color: Color = zone.meta.get("color", Color(0.35, 0.55, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Phone display stands
	for i in range(4):
		var px := cx + 8 + i * ((cw - 16) / 4.0)
		# Stand base
		var stand := ColorRect.new()
		stand.position = Vector2(px, cy + ch * 0.55); stand.size = Vector2((cw - 16) / 5.5, ch * 0.30)
		stand.color = Color(0.25, 0.28, 0.35); _parent.add_child(stand); _floor_nodes.append(stand)
		# Phone on stand
		var phone := ColorRect.new()
		phone.position = Vector2(px + 2, cy + ch * 0.25); phone.size = Vector2((cw - 16) / 7.0, ch * 0.30)
		phone.color = Color(0.15, 0.15, 0.20); _parent.add_child(phone); _floor_nodes.append(phone)
		# Screen glow
		var glow := ColorRect.new()
		glow.position = Vector2(px + 3, cy + ch * 0.27); glow.size = Vector2((cw - 16) / 7.5, ch * 0.22)
		glow.color = zone_color.lightened(0.3); _parent.add_child(glow); _floor_nodes.append(glow)
	# Accessory hooks below
	for i in range(6):
		var ax := cx + 6 + i * ((cw - 12) / 6.0)
		var acc := ColorRect.new()
		acc.position = Vector2(ax, cy + ch * 0.72); acc.size = Vector2((cw - 12) / 7.5, ch * 0.15)
		acc.color = [Color(0.90, 0.90, 0.95), Color(0.90, 0.85, 0.90), Color(0.85, 0.90, 0.90)][i % 3]
		_parent.add_child(acc); _floor_nodes.append(acc)

func _build_zone_smart_home(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SMART HOME")
	var zone_color: Color = zone.meta.get("color", Color(0.40, 0.60, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Smart device shelves ??speakers, cameras, displays
	var dev_colors := [Color(0.30, 0.30, 0.35), Color(0.35, 0.35, 0.40), Color(0.25, 0.30, 0.35), Color(0.40, 0.35, 0.30)]
	for row in range(3):
		var sy := cy + 16 + row * (ch * 0.28)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(4):
			var dx := cx + 6 + col * ((cw - 12) / 4.0)
			var dh := 12 + (col % 2) * 6
			var dev := ColorRect.new()
			dev.position = Vector2(dx, sy - dh); dev.size = Vector2((cw - 12) / 5.5, dh)
			dev.color = dev_colors[(row + col) % dev_colors.size()]; _parent.add_child(dev); _floor_nodes.append(dev)
			# LED indicator dot
			var led := ColorRect.new()
			led.position = Vector2(dx + 2, sy - dh - 3); led.size = Vector2(3, 3)
			led.color = Color(0.20, 0.90, 0.50); _parent.add_child(led); _floor_nodes.append(led)

func _build_zone_electronics(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "ELECTRONICS")
	var zone_color: Color = zone.meta.get("color", Color(0.45, 0.50, 0.65))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# TV display wall
	var tv_bg := ColorRect.new()
	tv_bg.position = Vector2(cx + cw * 0.1, cy + ch * 0.1); tv_bg.size = Vector2(cw * 0.8, ch * 0.5)
	tv_bg.color = Color(0.10, 0.10, 0.12); _parent.add_child(tv_bg); _floor_nodes.append(tv_bg)
	var tv_screen := ColorRect.new()
	tv_screen.position = Vector2(cx + cw * 0.12, cy + ch * 0.12); tv_screen.size = Vector2(cw * 0.76, ch * 0.46)
	tv_screen.color = Color(0.15, 0.25, 0.50); _parent.add_child(tv_screen); _floor_nodes.append(tv_screen)
	# Speaker blocks
	for i in range(3):
		var sp_x := cx + 8 + i * ((cw - 16) / 3.0)
		var sp := ColorRect.new()
		sp.position = Vector2(sp_x, cy + ch * 0.65); sp.size = Vector2((cw - 16) / 4.5, ch * 0.22)
		sp.color = Color(0.25, 0.25, 0.30); _parent.add_child(sp); _floor_nodes.append(sp)

func _build_zone_repair_counter(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "REPAIR COUNTER")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.45, 0.40))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.30); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Workbench counter
	var bench := ColorRect.new()
	bench.position = Vector2(cx + 4, cy + ch * 0.40); bench.size = Vector2(cw - 8, ch * 0.35)
	bench.color = Color(0.40, 0.35, 0.30); _parent.add_child(bench); _floor_nodes.append(bench)
	# Tool pegboard above
	var board := ColorRect.new()
	board.position = Vector2(cx + 4, cy + ch * 0.15); board.size = Vector2(cw - 8, ch * 0.22)
	board.color = Color(0.50, 0.42, 0.35); _parent.add_child(board); _floor_nodes.append(board)
	# Tool outlines
	var tool_colors := [Color(0.80, 0.60, 0.30), Color(0.70, 0.70, 0.70), Color(0.90, 0.40, 0.40), Color(0.60, 0.80, 0.60)]
	for i in range(4):
		var tx := cx + 8 + i * ((cw - 16) / 4.0)
		var tool := ColorRect.new()
		tool.position = Vector2(tx, cy + ch * 0.17); tool.size = Vector2((cw - 16) / 6.0, ch * 0.18)
		tool.color = tool_colors[i]; _parent.add_child(tool); _floor_nodes.append(tool)
	var hint := Label.new(); hint.text = "[E] Tech Support"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.90, 0.80, 0.80))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_cafe_counter(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "CAFE COUNTER")
	var items: Array = zone.meta.get("items", [])
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE

	# Warm café floor
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = Color(0.60, 0.45, 0.30).darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)

	# Zone label above
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), Color(0.90, 0.75, 0.50)); _parent.add_child(tl); _floor_nodes.append(tl)

	# Counter base (wooden)
	var counter := ColorRect.new()
	counter.position = Vector2(cx, cy + ch - 5 * CELL_SIZE)
	counter.size = Vector2(cw, 5 * CELL_SIZE)
	counter.color = Color(0.55, 0.38, 0.22); _parent.add_child(counter); _floor_nodes.append(counter)

	# Counter top ledge
	var counter_top := ColorRect.new()
	counter_top.position = Vector2(cx, cy + ch - 5 * CELL_SIZE)
	counter_top.size = Vector2(cw, 2)
	counter_top.color = Color(0.75, 0.55, 0.35); _parent.add_child(counter_top); _floor_nodes.append(counter_top)

	# Coffee machine (back of counter)
	var machine := ColorRect.new()
	machine.position = Vector2(cx + cw * 0.35, cy + ch * 0.20)
	machine.size = Vector2(cw * 0.30, ch * 0.55)
	machine.color = Color(0.30, 0.30, 0.35); _parent.add_child(machine); _floor_nodes.append(machine)

	# Coffee machine top detail
	var machine_top := ColorRect.new()
	machine_top.position = Vector2(cx + cw * 0.33, cy + ch * 0.18)
	machine_top.size = Vector2(cw * 0.34, 4)
	machine_top.color = Color(0.50, 0.50, 0.55); _parent.add_child(machine_top); _floor_nodes.append(machine_top)

	# Cup warming label
	var cup_lbl := Label.new(); cup_lbl.text = "CUP WARMER"
	cup_lbl.position = Vector2(cx + cw * 0.36, cy + ch * 0.22)
	cup_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	cup_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(cup_lbl); _floor_nodes.append(cup_lbl)

	# Espresso machine button area
	var btn_area := ColorRect.new()
	btn_area.position = Vector2(cx + cw * 0.40, cy + ch * 0.38)
	btn_area.size = Vector2(cw * 0.20, ch * 0.12)
	btn_area.color = Color(0.20, 0.20, 0.25); _parent.add_child(btn_area); _floor_nodes.append(btn_area)

	# Menu board on back wall
	var board_bg := ColorRect.new()
	board_bg.position = Vector2(cx + 4, cy + 2)
	board_bg.size = Vector2(cw * 0.30, ch * 0.40)
	board_bg.color = Color(0.05, 0.10, 0.05); _parent.add_child(board_bg); _floor_nodes.append(board_bg)

	# Show menu items on board
	for i in range(mini(items.size(), 4)):
		var item_lbl := Label.new()
		item_lbl.text = items[i]
		item_lbl.position = Vector2(cx + 6, cy + 3 + i * (ch * 0.10))
		item_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.70))
		item_lbl.add_theme_font_size_override("font_size", 6)
		_parent.add_child(item_lbl); _floor_nodes.append(item_lbl)

	# Warm glow above the counter (lamp)
	var glow := Sprite2D.new()
	glow.position = Vector2(cx + cw * 0.5, cy - 10 * CELL_SIZE)
	glow.texture = _make_glow(Color(1.0, 0.75, 0.40))
	_parent.add_child(glow); _floor_nodes.append(glow)

	# Hint label
	var hint := Label.new(); hint.text = "[E] Browse Menu"
	hint.position = Vector2(cx + 4, cy + ch - 4 * CELL_SIZE)
	hint.add_theme_color_override("font_color", Color(0.90, 0.80, 0.60))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)
