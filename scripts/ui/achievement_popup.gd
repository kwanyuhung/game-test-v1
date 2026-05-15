# achievement_popup.gd
# Floating achievement unlock notification.
# Appears top-center of screen, auto-dismisses after 4 seconds.
# ═══════════════════════════════════════════════════════════════════════
class_name AchievementPopup
extends Control

signal dismissed()

var _timer: float = 0.0
var _duration: float = 4.0
var _start_y: float = 0.0

func _ready() -> void:
	z_index = 500

func show_achievement(ach_id: String, name: String, icon: String, xp: int) -> void:
	visible = true
	modulate.a = 0.0

	var scr_w := 320.0
	var scr_h := 180.0

	# Background banner
	var banner := ColorRect.new()
	banner.position = Vector2((scr_w - 220) * 0.5, 10)
	banner.size = Vector2(220, 32)
	banner.color = Color(0.08, 0.08, 0.14, 0.95)
	add_child(banner)

	# Achievement name
	var name_lbl := Label.new()
	name_lbl.text = "%s  %s" % [icon, name]
	name_lbl.position = Vector2((scr_w - 220) * 0.5 + 8, 14)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40))
	name_lbl.add_theme_font_size_override("font_size", 8)
	add_child(name_lbl)

	# XP reward
	var xp_lbl := Label.new()
	xp_lbl.text = "+%d XP" % xp
	xp_lbl.position = Vector2((scr_w - 220) * 0.5 + 8, 26)
	xp_lbl.add_theme_color_override("font_color", Color(0.70, 0.90, 0.60))
	xp_lbl.add_theme_font_size_override("font_size", 7)
	add_child(xp_lbl)

	# Unlock label
	var unl_lbl := Label.new()
	unl_lbl.text = "ACHIEVEMENT UNLOCKED!"
	unl_lbl.position = Vector2((scr_w - 220) * 0.5 + 130, 22)
	unl_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.75))
	unl_lbl.add_theme_font_size_override("font_size", 5)
	add_child(unl_lbl)

	# Fade in
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	set_process(true)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _duration:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.4)
		tween.tween_callback(Callable(self, "queue_free"))
		set_process(false)
