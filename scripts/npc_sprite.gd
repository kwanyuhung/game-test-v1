# npc_sprite.gd
# ═══════════════════════════════════════════════════════════════════════
# Generates pixel art NPC sprites from an ActorData.Appearance definition.
# Supports: hair styles, glasses, makeup, accessories, shoes, bags,
#           tops, bottoms, and baby/stroller sprites.
# All 16×16 or 24×24 per character, fully programmatic.
# ═══════════════════════════════════════════════════════════════════════
class_name NPCSprite
extends Node

const ActorData = preload("res://scripts/actor_data.gd")

# ─── Textures ────────────────────────────────────────────────

static func make_actor_texture(appearance: ActorData.Appearance, scale: int = 16) -> Texture2D:
	var sz := scale
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_shadow(img, sz)
	_draw_shoes(img, appearance.shoes_color, appearance.shoes_style, sz)
	_draw_lower_body(img, appearance.bottom_color, appearance.bottom_style, sz)
	_draw_upper_body(img, appearance.top_color, appearance.top_style, sz)
	_draw_head(img, appearance.skin_tone, appearance.has_glasses, appearance.glasses_tint if appearance.has("glasses_tint") else Color.WHITE, sz)
	_draw_hair(img, appearance.hair_color, appearance.hair_style, sz)
	_draw_accessory(img, appearance.accessory, appearance.top_color, sz)
	_draw_makeup(img, appearance.skin_tone, appearance.makeup_intensity, sz)
	return ImageTexture.create_from_image(img)

static func make_baby_texture(child: ActorData.ChildData, scale: int = 12) -> Texture2D:
	var sz := scale
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_baby(img, child, sz)
	return ImageTexture.create_from_image(img)

static func make_stroller_texture(child: ActorData.ChildData, scale: int = 20) -> Texture2D:
	var sz := scale
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_stroller(img, child, sz)
	return ImageTexture.create_from_image(img)

# ─── Shoe Drawing ─────────────────────────────────────────────

static func _draw_shoes(img: Image, col: Color, style: int, sz: int) -> void:
	var sc := float(sz) / 16.0
	var shoes_dark := col.darkened(0.3)
	match style:
		0:  # sneakers
			_fill_img(img, int(2*sc), int(14*sc), int(5*sc), int(2*sc), col, sz)
			_fill_img(img, int(9*sc), int(14*sc), int(5*sc), int(2*sc), col, sz)
			_fill_img(img, int(2*sc), int(14*sc), int(5*sc), int(1*sc), shoes_dark, sz)
			_fill_img(img, int(9*sc), int(14*sc), int(5*sc), int(1*sc), shoes_dark, sz)
		1:  # formal shoes
			_fill_img(img, int(2*sc), int(14*sc), int(5*sc), int(2*sc), shoes_dark, sz)
			_fill_img(img, int(9*sc), int(14*sc), int(5*sc), int(2*sc), shoes_dark, sz)
			_fill_img(img, int(2*sc), int(13*sc), int(5*sc), int(1*sc), col, sz)
			_fill_img(img, int(9*sc), int(13*sc), int(5*sc), int(1*sc), col, sz)
		2:  # sandals
			_fill_img(img, int(2*sc), int(14*sc), int(5*sc), int(1*sc), shoes_dark, sz)
			_fill_img(img, int(9*sc), int(14*sc), int(5*sc), int(1*sc), shoes_dark, sz)
			_fill_img(img, int(3*sc), int(13*sc), int(1*sc), int(1*sc), col, sz)
			_fill_img(img, int(7*sc), int(13*sc), int(1*sc), int(1*sc), col, sz)
		3:  # boots
			_fill_img(img, int(2*sc), int(12*sc), int(5*sc), int(4*sc), shoes_dark, sz)
			_fill_img(img, int(9*sc), int(12*sc), int(5*sc), int(4*sc), shoes_dark, sz)
			_fill_img(img, int(2*sc), int(13*sc), int(5*sc), int(1*sc), col, sz)
			_fill_img(img, int(9*sc), int(13*sc), int(5*sc), int(1*sc), col, sz)

# ─── Lower Body ──────────────────────────────────────────────

static func _draw_lower_body(img: Image, col: Color, style: int, sz: int) -> void:
	var sc := float(sz) / 16.0
	match style:
		0:  # pants
			_fill_img(img, int(3*sc), int(10*sc), int(4*sc), int(1*sc), col.darkened(0.1), sz)
			_fill_img(img, int(9*sc), int(10*sc), int(4*sc), int(1*sc), col.darkened(0.1), sz)
			_fill_img(img, int(3*sc), int(11*sc), int(4*sc), int(3*sc), col, sz)
			_fill_img(img, int(9*sc), int(11*sc), int(4*sc), int(3*sc), col, sz)
			_fill_img(img, int(3*sc), int(12*sc), int(3*sc), int(2*sc), col.darkened(0.15), sz)
			_fill_img(img, int(10*sc), int(12*sc), int(3*sc), int(2*sc), col.darkened(0.15), sz)
		1:  # skirt
			_fill_img(img, int(3*sc), int(10*sc), int(10*sc), int(1*sc), col.darkened(0.1), sz)
			_fill_img(img, int(2*sc), int(11*sc), int(12*sc), int(3*sc), col, sz)
			_fill_img(img, int(2*sc), int(12*sc), int(12*sc), int(1*sc), col.darkened(0.15), sz)
			_fill_img(img, int(2*sc), int(13*sc), int(3*sc), int(1*sc), col.darkened(0.1), sz)
			_fill_img(img, int(11*sc), int(13*sc), int(3*sc), int(1*sc), col.darkened(0.1), sz)
		2:  # shorts
			_fill_img(img, int(3*sc), int(10*sc), int(10*sc), int(1*sc), col.darkened(0.1), sz)
			_fill_img(img, int(3*sc), int(11*sc), int(4*sc), int(3*sc), col, sz)
			_fill_img(img, int(9*sc), int(11*sc), int(4*sc), int(3*sc), col, sz)
		3:  # dress (covers lower body)
			_fill_img(img, int(3*sc), int(8*sc), int(10*sc), int(5*sc), col, sz)
			_fill_img(img, int(2*sc), int(10*sc), int(12*sc), int(1*sc), col.darkened(0.15), sz)
			_fill_img(img, int(1*sc), int(11*sc), int(14*sc), int(3*sc), col, sz)
			_fill_img(img, int(1*sc), int(13*sc), int(14*sc), int(1*sc), col.darkened(0.1), sz)

# ─── Upper Body ───────────────────────────────────────────────

static func _draw_upper_body(img: Image, col: Color, style: int, sz: int) -> void:
	var sc := float(sz) / 16.0
	match style:
		0:  # t-shirt
			_fill_img(img, int(3*sc), int(6*sc), int(10*sc), int(5*sc), col.darkened(0.1), sz)
			_fill_img(img, int(4*sc), int(7*sc), int(8*sc), int(4*sc), col, sz)
			_fill_img(img, int(1*sc), int(7*sc), int(2*sc), int(3*sc), col, sz)
			_fill_img(img, int(13*sc), int(7*sc), int(2*sc), int(3*sc), col, sz)
			_fill_img(img, int(5*sc), int(6*sc), int(6*sc), int(1*sc), col.lightened(0.15), sz)
		1:  # button shirt
			_fill_img(img, int(3*sc), int(6*sc), int(10*sc), int(5*sc), col, sz)
			_fill_img(img, int(4*sc), int(7*sc), int(8*sc), int(4*sc), col.lightened(0.05), sz)
			_fill_img(img, int(1*sc), int(7*sc), int(2*sc), int(3*sc), col.darkened(0.1), sz)
			_fill_img(img, int(13*sc), int(7*sc), int(2*sc), int(3*sc), col.darkened(0.1), sz)
			_fill_img(img, int(6*sc), int(7*sc), int(1*sc), int(4*sc), col.darkened(0.15), sz)
			_set_img(img, int(7*sc), int(8*sc), Color(0.88, 0.78, 0.58), sz)
			_set_img(img, int(7*sc), int(9*sc), Color(0.88, 0.78, 0.58), sz)
			_set_img(img, int(7*sc), int(10*sc), Color(0.88, 0.78, 0.58), sz)
		2:  # sweater
			_fill_img(img, int(2*sc), int(6*sc), int(12*sc), int(5*sc), col.darkened(0.08), sz)
			_fill_img(img, int(3*sc), int(7*sc), int(10*sc), int(4*sc), col, sz)
			_fill_img(img, int(1*sc), int(7*sc), int(2*sc), int(3*sc), col.darkened(0.12), sz)
			_fill_img(img, int(13*sc), int(7*sc), int(2*sc), int(3*sc), col.darkened(0.12), sz)
			_fill_img(img, int(3*sc), int(6*sc), int(10*sc), int(1*sc), col.darkened(0.15), sz)
			_fill_img(img, int(3*sc), int(10*sc), int(10*sc), int(1*sc), col.darkened(0.15), sz)
		3:  # jacket
			_fill_img(img, int(2*sc), int(6*sc), int(12*sc), int(5*sc), col.darkened(0.1), sz)
			_fill_img(img, int(3*sc), int(7*sc), int(10*sc), int(4*sc), col, sz)
			_fill_img(img, int(1*sc), int(7*sc), int(2*sc), int(4*sc), col.darkened(0.1), sz)
			_fill_img(img, int(13*sc), int(7*sc), int(2*sc), int(4*sc), col.darkened(0.1), sz)
			_fill_img(img, int(6*sc), int(7*sc), int(1*sc), int(4*sc), col.darkened(0.2), sz)
			_fill_img(img, int(9*sc), int(7*sc), int(1*sc), int(4*sc), col.darkened(0.2), sz)
		4:  # tank top
			_fill_img(img, int(4*sc), int(6*sc), int(8*sc), int(5*sc), col.darkened(0.1), sz)
			_fill_img(img, int(5*sc), int(7*sc), int(6*sc), int(4*sc), col, sz)
			_fill_img(img, int(4*sc), int(6*sc), int(1*sc), int(1*sc), col.darkened(0.2), sz)
			_fill_img(img, int(11*sc), int(6*sc), int(1*sc), int(1*sc), col.darkened(0.2), sz)

# ─── Head ──────────────────────────────────────────────────

static func _draw_head(img: Image, skin: Color, has_glasses: bool, glasses_col: Color, sz: int) -> void:
	var sc := float(sz) / 16.0
	# Basic head
	_fill_img(img, int(5*sc), int(1*sc), int(6*sc), int(1*sc), skin.darkened(0.1), sz)
	_fill_img(img, int(4*sc), int(2*sc), int(8*sc), int(4*sc), skin, sz)
	_fill_img(img, int(5*sc), int(6*sc), int(6*sc), int(1*sc), skin.darkened(0.1), sz)

	# Eyes
	_set_img(img, int(6*sc), int(4*sc), Color.WHITE, sz)
	_set_img(img, int(9*sc), int(4*sc), Color.WHITE, sz)
	_set_img(img, int(6*sc), int(4*sc), Color(0.12, 0.08, 0.06), sz)
	_set_img(img, int(9*sc), int(4*sc), Color(0.12, 0.08, 0.06), sz)
	# Eye shine
	_set_img(img, int(5*sc), int(3*sc), Color.WHITE.lightened(0.5), sz)
	_set_img(img, int(8*sc), int(3*sc), Color.WHITE.lightened(0.5), sz)
	# Mouth
	_set_img(img, int(7*sc), int(6*sc), skin.darkened(0.25), sz)
	_set_img(img, int(8*sc), int(6*sc), skin.darkened(0.25), sz)

	# Glasses
	if has_glasses:
		_fill_img(img, int(5*sc), int(3*sc), int(3*sc), int(2*sc), glasses_col.darkened(0.3), sz)
		_fill_img(img, int(8*sc), int(3*sc), int(3*sc), int(2*sc), glasses_col.darkened(0.3), sz)
		_set_img(img, int(7*sc), int(4*sc), glasses_col.darkened(0.5), sz)
		_set_img(img, int(7*sc), int(3*sc), glasses_col.darkened(0.5), sz)

# ─── Hair ───────────────────────────────────────────────────

static func _draw_hair(img: Image, col: Color, style: int, sz: int) -> void:
	var sc := float(sz) / 16.0
	var h := col.darkened(0.1)
	match style:
		0:  # bob (Japanese-style neat bob)
			_fill_img(img, int(4*sc), int(0*sc), int(8*sc), int(1*sc), h, sz)
			_fill_img(img, int(3*sc), int(1*sc), int(2*sc), int(2*sc), h, sz)
			_fill_img(img, int(11*sc), int(1*sc), int(2*sc), int(2*sc), h, sz)
			_fill_img(img, int(3*sc), int(1*sc), int(10*sc), int(1*sc), col.lightened(0.1), sz)
			_fill_img(img, int(2*sc), int(2*sc), int(12*sc), int(3*sc), col, sz)
			_fill_img(img, int(2*sc), int(4*sc), int(2*sc), int(2*sc), col.darkened(0.1), sz)
			_fill_img(img, int(12*sc), int(4*sc), int(2*sc), int(2*sc), col.darkened(0.1), sz)
		1:  # long hair
			_fill_img(img, int(3*sc), int(0*sc), int(10*sc), int(1*sc), h, sz)
			_fill_img(img, int(2*sc), int(1*sc), int(12*sc), int(3*sc), col, sz)
			_fill_img(img, int(2*sc), int(2*sc), int(2*sc), int(5*sc), col.darkened(0.1), sz)
			_fill_img(img, int(12*sc), int(2*sc), int(2*sc), int(5*sc), col.darkened(0.1), sz)
			_fill_img(img, int(2*sc), int(5*sc), int(3*sc), int(4*sc), col, sz)
			_fill_img(img, int(11*sc), int(5*sc), int(3*sc), int(4*sc), col, sz)
		2:  # short neat
			_fill_img(img, int(4*sc), int(0*sc), int(8*sc), int(1*sc), h, sz)
			_fill_img(img, int(3*sc), int(1*sc), int(10*sc), int(1*sc), col.lightened(0.1), sz)
			_fill_img(img, int(3*sc), int(1*sc), int(2*sc), int(2*sc), col, sz)
			_fill_img(img, int(11*sc), int(1*sc), int(2*sc), int(2*sc), col, sz)
		3:  # bald / buzz cut
			_fill_img(img, int(4*sc), int(0*sc), int(8*sc), int(1*sc), h.darkened(0.05), sz)
			_fill_img(img, int(4*sc), int(0*sc), int(8*sc), int(2*sc), col.darkened(0.15), sz)

# ─── Accessory ─────────────────────────────────────────────

static func _draw_accessory(img: Image, acc: int, top_col: Color, sz: int) -> void:
	var sc := float(sz) / 16.0
	match acc:
		1:  # handbag / shoulder bag
			_fill_img(img, int(13*sc), int(8*sc), int(3*sc), int(3*sc), top_col.darkened(0.3), sz)
			_fill_img(img, int(14*sc), int(8*sc), int(1*sc), int(1*sc), top_col.darkened(0.4), sz)
			_set_img(img, int(13*sc), int(7*sc), top_col.darkened(0.4), sz)
		2:  # backpack
			_fill_img(img, int(3*sc), int(6*sc), int(3*sc), int(4*sc), top_col.darkened(0.35), sz)
			_fill_img(img, int(2*sc), int(7*sc), int(1*sc), int(2*sc), top_col.darkened(0.4), sz)
			_fill_img(img, int(4*sc), int(6*sc), int(1*sc), int(1*sc), top_col.darkened(0.4), sz)
		3:  # fancy handbag
			_fill_img(img, int(13*sc), int(8*sc), int(3*sc), int(2*sc), top_col.lightened(0.1), sz)
			_fill_img(img, int(14*sc), int(7*sc), int(1*sc), int(1*sc), top_col.darkened(0.3), sz)
			_set_img(img, int(14*sc), int(8*sc), Color(0.88, 0.78, 0.28), sz)

# ─── Makeup ────────────────────────────────────────────────

static func _draw_makeup(img: Image, skin: Color, intensity: int, sz: int) -> void:
	var sc := float(sz) / 16.0
	if intensity == 0:
		return
	var lip_col := Color(0.85, 0.28, 0.38)
	var blush_col := Color(0.92, 0.55, 0.55)
	match intensity:
		1:  # light makeup
			_set_img(img, int(6*sc), int(5*sc), lip_col.lightened(0.2), sz)
			_set_img(img, int(8*sc), int(5*sc), lip_col.lightened(0.2), sz)
			_fill_img(img, int(4*sc), int(5*sc), int(2*sc), int(1*sc), blush_col.darkened(0.3), sz)
			_fill_img(img, int(10*sc), int(5*sc), int(2*sc), int(1*sc), blush_col.darkened(0.3), sz)
		2:  # full makeup
			_fill_img(img, int(6*sc), int(5*sc), int(2*sc), int(1*sc), lip_col, sz)
			_fill_img(img, int(8*sc), int(5*sc), int(2*sc), int(1*sc), lip_col, sz)
			_fill_img(img, int(4*sc), int(5*sc), int(2*sc), int(1*sc), blush_col, sz)
			_fill_img(img, int(10*sc), int(5*sc), int(2*sc), int(1*sc), blush_col, sz)
			# Eyeshadow
			_fill_img(img, int(5*sc), int(3*sc), int(3*sc), int(1*sc), Color(0.60, 0.35, 0.60), sz)
			_fill_img(img, int(8*sc), int(3*sc), int(3*sc), int(1*sc), Color(0.60, 0.35, 0.60), sz)
			# Eyeliner
			_set_img(img, int(5*sc), int(4*sc), Color(0.08, 0.05, 0.05), sz)
			_set_img(img, int(10*sc), int(4*sc), Color(0.08, 0.05, 0.05), sz)

# ─── Baby Drawing ──────────────────────────────────────────

static func _draw_baby(img: Image, child: ActorData.ChildData, sz: int) -> void:
	var sc := float(sz) / 12.0
	# Baby body
	_fill_img(img, int(3*sc), int(4*sc), int(6*sc), int(4*sc), child.outfit_color, sz)
	_fill_img(img, int(4*sc), int(3*sc), int(4*sc), int(2*sc), child.outfit_color, sz)
	# Baby head
	_fill_img(img, int(4*sc), int(1*sc), int(4*sc), int(3*sc), child.skin_tone, sz)
	_fill_img(img, int(4*sc), int(3*sc), int(4*sc), int(1*sc), child.skin_tone.darkened(0.1), sz)
	# Baby eyes
	_set_img(img, int(5*sc), int(2*sc), Color.WHITE, sz)
	_set_img(img, int(7*sc), int(2*sc), Color.WHITE, sz)
	_set_img(img, int(5*sc), int(2*sc), Color(0.08, 0.08, 0.08), sz)
	_set_img(img, int(7*sc), int(2*sc), Color(0.08, 0.08, 0.08), sz)
	# Baby hair
	match child.hair_style:
		0: _fill_img(img, int(4*sc), int(0*sc), int(4*sc), int(1*sc), child.hair_color, sz)
		1: _fill_img(img, int(3*sc), int(0*sc), int(6*sc), int(2*sc), child.hair_color, sz)
		2: _fill_img(img, int(4*sc), int(0*sc), int(4*sc), int(2*sc), child.hair_color, sz)
	# Baby hat
	if child.accessory == 2:
		_fill_img(img, int(3*sc), int(0*sc), int(6*sc), int(2*sc), child.outfit_color.lightened(0.2), sz)
	# Baby legs
	_fill_img(img, int(4*sc), int(8*sc), int(2*sc), int(3*sc), child.skin_tone, sz)
	_fill_img(img, int(6*sc), int(8*sc), int(2*sc), int(3*sc), child.skin_tone, sz)

# ─── Stroller Drawing ───────────────────────────────────────

static func _draw_stroller(img: Image, child: ActorData.ChildData, sz: int) -> void:
	var sc := float(sz) / 20.0
	# Wheels
	_fill_img(img, int(3*sc), int(16*sc), int(3*sc), int(3*sc), Color(0.18, 0.18, 0.18), sz)
	_fill_img(img, int(14*sc), int(16*sc), int(3*sc), int(3*sc), Color(0.18, 0.18, 0.18), sz)
	# Frame
	_fill_img(img, int(4*sc), int(8*sc), int(12*sc), int(2*sc), child.cart_color.darkened(0.2), sz)
	_fill_img(img, int(3*sc), int(8*sc), int(2*sc), int(8*sc), child.cart_color.darkened(0.2), sz)
	_fill_img(img, int(15*sc), int(8*sc), int(2*sc), int(8*sc), child.cart_color.darkened(0.2), sz)
	# Canopy
	_fill_img(img, int(2*sc), int(4*sc), int(16*sc), int(4*sc), child.cart_color.lightened(0.3), sz)
	_fill_img(img, int(2*sc), int(4*sc), int(16*sc), int(1*sc), child.cart_color, sz)
	# Baby inside (tiny)
	_fill_img(img, int(6*sc), int(10*sc), int(8*sc), int(4*sc), child.outfit_color, sz)
	_fill_img(img, int(7*sc), int(8*sc), int(6*sc), int(3*sc), child.skin_tone, sz)

# ─── Legacy support (random sprite) ─────────────────────────

static func make_random_texture() -> Texture2D:
	var skin := [
		Color(0.96, 0.80, 0.65),
		Color(0.88, 0.68, 0.48),
		Color(0.72, 0.52, 0.38),
		Color(0.55, 0.38, 0.28),
	][randi() % 4]
	var hair := [
		Color(0.18, 0.12, 0.08),
		Color(0.62, 0.42, 0.22),
		Color(0.92, 0.72, 0.35),
		Color(0.78, 0.32, 0.18),
	][randi() % 4]
	var top := [
		Color(0.28, 0.42, 0.78),
		Color(0.78, 0.28, 0.28),
		Color(0.28, 0.68, 0.42),
		Color(0.88, 0.68, 0.28),
		Color(0.68, 0.28, 0.68),
	][randi() % 5]
	var bottom := [
		Color(0.22, 0.22, 0.42),
		Color(0.42, 0.38, 0.32),
		Color(0.32, 0.38, 0.52),
		Color(0.22, 0.32, 0.22),
	][randi() % 4]
	var ap := ActorData.Appearance.new()
	ap.skin_tone = skin
	ap.hair_color = hair
	ap.top_color = top
	ap.bottom_color = bottom
	ap.hair_style = randi() % 4
	ap.top_style = randi() % 3
	ap.bottom_style = randi() % 2
	ap.has_glasses = (randi() % 4 == 0)
	ap.makeup_intensity = randi() % 3
	ap.accessory = randi() % 4
	return make_actor_texture(ap, 16)

# ─── Helpers ────────────────────────────────────────────────

static func _draw_shadow(img: Image, sz: int) -> void:
	var sc := float(sz) / 16.0
	_fill_img(img, int(4*sc), int(14*sc), int(8*sc), int(2*sc), Color(0, 0, 0, 0.18), sz)

static func _fill_img(img: Image, x: int, y: int, w: int, h: int, col: Color, sz: int) -> void:
	x = clampi(x, 0, sz); y = clampi(y, 0, sz)
	w = clampi(w, 0, sz - x); h = clampi(h, 0, sz - y)
	if w <= 0 or h <= 0:
		return
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

static func _set_img(img: Image, x: int, y: int, col: Color, sz: int) -> void:
	if x < 0 or x >= sz or y < 0 or y >= sz:
		return
	img.set_pixel(x, y, col)
