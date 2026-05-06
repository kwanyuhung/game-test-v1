# audio_manager.gd
# Procedural audio — no external files needed.
# Uses Godot 4's AudioStreamGenerator to synthesize tones and noise.
extends Node
class_name AudioManager

const SAMPLE_RATE := 44100.0
const PI := 3.14159265

var _player: AudioStreamPlayer = null
var _gen: AudioStreamGenerator = null
var _playback: AudioStreamGeneratorPlayback = null

var _bgm_running := false
var _bgm_thread: Thread = null

# Queue of pending SFX tones to play (freq, duration, vol)
var _sfx_queue: Array = []
var _sfx_mutex: Mutex = null

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_sfx_mutex = Mutex.new()
	_init_audio()
	play_bgm()

func play_checkout_beep() -> void:
	_queue_tone(880.0, 0.12, 0.30)
	call_deferred("_defer_second_beep")

func _defer_second_beep() -> void:
	await get_tree().create_timer(0.15).timeout
	_queue_tone(1046.5, 0.10, 0.25)

func play_purchase() -> void:
	_queue_tone(523.3, 0.08, 0.22)
	call_deferred("_defer_purchase2")

func _defer_purchase2() -> void:
	await get_tree().create_timer(0.09).timeout
	_queue_tone(659.3, 0.08, 0.22)
	call_deferred("_defer_purchase3")

func _defer_purchase3() -> void:
	await get_tree().create_timer(0.09).timeout
	_queue_tone(783.99, 0.10, 0.25)

func play_error() -> void:
	_queue_tone(220.0, 0.15, 0.25)
	call_deferred("_defer_error2")

func _defer_error2() -> void:
	await get_tree().create_timer(0.18).timeout
	_queue_tone(196.0, 0.18, 0.22)

func play_elevator_ding() -> void:
	_queue_tone(1318.5, 0.12, 0.30)
	call_deferred("_defer_ding2")

func _defer_ding2() -> void:
	await get_tree().create_timer(0.55).timeout
	_queue_tone(1568.0, 0.14, 0.28)

func play_item_add() -> void:
	_queue_tone(1046.5, 0.05, 0.18)

func play_level_up() -> void:
	var notes := [523.3, 659.3, 783.99, 1046.5]
	var delay := 0.0
	for n in notes:
		await get_tree().create_timer(delay).timeout
		_queue_tone(n, 0.13, 0.25)
		delay += 0.14

func play_alarm() -> void:
	for i in range(4):
		_queue_tone(800.0, 0.10, 0.30)
		await get_tree().create_timer(0.13).timeout
		_queue_tone(600.0, 0.10, 0.30)
		await get_tree().create_timer(0.13).timeout

func play_cart_grab() -> void:
	_queue_tone(300.0, 0.08, 0.22)
	call_deferred("_defer_cart2")

func _defer_cart2() -> void:
	await get_tree().create_timer(0.06).timeout
	_queue_tone(450.0, 0.06, 0.18)

func play_floor_change() -> void:
	_queue_tone(440.0, 0.07, 0.20)
	call_deferred("_defer_floor2")

func _defer_floor2() -> void:
	await get_tree().create_timer(0.09).timeout
	_queue_tone(550.0, 0.07, 0.20)
	call_deferred("_defer_floor3")

func _defer_floor3() -> void:
	await get_tree().create_timer(0.09).timeout
	_queue_tone(660.0, 0.09, 0.22)

func stop_bgm() -> void:
	_bgm_running = false
	if _bgm_thread != null:
		_bgm_thread.wait_to_finish()
		_bgm_thread = null

# ─────────────────────────────────────────────────────────────────
# Implementation
# ─────────────────────────────────────────────────────────────────

func _init_audio() -> void:
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = SAMPLE_RATE
	_gen.buffer_length = 0.05

	_player = AudioStreamPlayer.new()
	_player.stream = _gen
	_player.volume_db = -8.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func _queue_tone(freq: float, duration: float, vol: float) -> void:
	if !is_instance_valid(_playback):
		return
	var samples := int(SAMPLE_RATE * duration)
	var buf := PackedVector2Array()
	buf.resize(samples)
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var env := _env(i, samples)
		var s := sin(2.0 * PI * freq * t) * env * vol
		buf[i] = Vector2(s, s)
	_playback.push_buffer(buf)

func _env(sample: int, total: int) -> float:
	var rel := float(sample) / float(total)
	var a := 0.04
	var r := 0.12
	if rel < a:
		return rel / a
	if rel > 1.0 - r:
		return clampf((1.0 - rel) / r, 0.0, 1.0)
	return 1.0

# ─── BGM thread ─────────────────────────────────────────────────

func play_bgm() -> void:
	if _bgm_running:
		return
	_bgm_running = true
	_bgm_thread = Thread.new()
	_bgm_thread.start(Callable(self, "_bgm_loop"))

func _bgm_loop() -> void:
	# Chord loop: Am9 — Fmaj7 — Cmaj9 — G9  (quiet, ambient)
	# Each chord: root + 3rd + 5th + 9th
	while _bgm_running:
		_bgm_chord([220.0, 261.6, 329.6, 392.0], 5.0)   # Am9
		if !_bgm_running: break
		_bgm_chord([174.6, 220.0, 329.6, 392.0], 5.0)   # Fmaj7
		if !_bgm_running: break
		_bgm_chord([261.6, 329.6, 392.0, 493.88], 5.0)  # Cmaj9
		if !_bgm_running: break
		_bgm_chord([196.0, 246.9, 392.0, 493.88], 5.0)  # G9

func _bgm_chord(freqs: Array, dur: float) -> void:
	if !_bgm_running or !is_instance_valid(_playback):
		return
	var samples := int(SAMPLE_RATE * dur)
	var buf := PackedVector2Array()
	buf.resize(samples)
	for i in samples:
		if !_bgm_running:
			break
		var t := float(i) / SAMPLE_RATE
		var env := _chord_env(i, samples)
		var s := 0.0
		for f in freqs:
			s += sin(2.0 * PI * f * t)
		s = (s / freqs.size()) * env * 0.035
		buf[i] = Vector2(s, s)
	if _bgm_running and is_instance_valid(_playback):
		_playback.push_buffer(buf)

func _chord_env(sample: int, total: int) -> float:
	var rel := float(sample) / float(total)
	var a := 0.03
	var r := 0.20
	if rel < a:
		return rel / a
	if rel > 1.0 - r:
		return clampf((1.0 - rel) / r, 0.0, 1.0)
	return 1.0

func _exit_tree() -> void:
	stop_bgm()
	if is_instance_valid(_player):
		_player.stop()
