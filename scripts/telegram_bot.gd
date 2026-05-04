# telegram_bot.gd
# Sends messages to Telegram when important events occur.
# Uses the configured bot token and admin chat_id.
extends Node

const BOT_TOKEN := "8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk"
const ADMIN_CHAT_ID := "1718058079"

var _report_queue: Array = []
var _report_timer: float = 0.0
var _game_started: bool = false

func _ready() -> void:
	_report_timer = 0.0
	# Queue an initial startup report (deferred so tree is ready)
	call_deferred("_queue_startup_report")
	_game_started = true

func _queue_startup_report() -> void:
	queue_report("🟢 *Game Started*\nSupermarket is open for business!")

func _process(delta: float) -> void:
	# Flush queued reports every 30 seconds max to avoid spam
	if _report_queue.size() > 0:
		_report_timer += delta
		if _report_timer >= 30.0:
			_flush_reports()

func queue_report(text: String) -> void:
	# Deduplicate
	if text in _report_queue:
		return
	_report_queue.append(text)
	# Flush immediately for important events
	if text.begins_with("🔴") or text.begins_with("🟢"):
		_flush_reports()

func _flush_reports() -> void:
	if _report_queue.size() == 0:
		return
	var combined := "\n\n".join(_report_queue.slice(0, 5))
	if _report_queue.size() > 5:
		combined += "\n\n_... +%d more_" % (_report_queue.size() - 5)
	_send(combined)
	_report_queue.clear()
	_report_timer = 0.0

static func send_message(text: String) -> bool:
	if BOT_TOKEN == "" or ADMIN_CHAT_ID == "":
		return false
	
	var url := "https://api.telegram.org/bot%s/sendMessage" % BOT_TOKEN
	var body := "chat_id=%s&text=%s&parse_mode=Markdown" % [ADMIN_CHAT_ID, text.uri_encode()]
	
	var http := HTTPRequest.new()
	var tree := Engine.get_main_loop()
	tree.root.add_child(http)
	
	var result := []
	var success := false
	
	http.request_completed.connect(
		func(req_result: int, req_code: int, req_headers: Array, req_body: PackedByteArray) -> void:
			result = [req_result, req_code]
			success = (req_code == 200)
	)
	
	var err = http.request(url, [], HTTPClient.METHOD_POST, body)
	if err != OK:
		tree.root.remove_child(http)
		http.queue_free()
		return false
	
	# Wait for response (max 5s)
	var wait_time := 0.0
	while result.size() == 0 and wait_time < 5.0:
		tree.process_frame
		wait_time += 0.1
		await tree.create_timer(0.1).timeout
	
	tree.root.remove_child(http)
	http.queue_free()
	return success

func _send(text: String) -> void:
	call_deferred("_send_deferred", text)

func _send_deferred(text: String) -> void:
	send_message(text)

# ═══════════════════════════════════════════════════════════════
# STATUS REPORTS
# ═══════════════════════════════════════════════════════════════

static func notify_game_started() -> void:
	queue_report_static("🟢 *Game Started*\nSupermarket is open!")

static func notify_game_error(err_msg: String) -> void:
	var short := err_msg
	if short.length() > 200:
		short = short.substr(0, 200) + "..."
	queue_report_static("🔴 *Runtime Error*\n`" + short + "`")

static func notify_player_checkout(total: float, item_count: int) -> void:
	var msg := "🛒 *Checkout Complete*\n"
	msg += "%d items · *$%.2f*" % [item_count, total]
	queue_report_static(msg)

static func notify_cart_updated(item_count: int, subtotal: float) -> void:
	# Only report meaningful cart changes
	if item_count >= 3:
		queue_report_static("🛒 *Cart Updated*\n%d items · $%.2f" % [item_count, subtotal])

static func notify_section_browse(section_name: String, product_count: int) -> void:
	queue_report_static("📋 *Browsing* `%s`\n%d products available" % [section_name, product_count])

static func notify_npc_spawn(npc_count: int) -> void:
	queue_report_static("👥 *NPCs Active*\n%d shoppers in store" % npc_count)

static func notify_test_failed(errors: String) -> void:
	queue_report_static("❌ *Test Failed*\n" + errors)

static func notify_test_pass() -> void:
	queue_report_static("✅ *Test Passed*")

static func notify_commit(message: String) -> void:
	queue_report_static("📦 *Committed*\n" + message)

# Queue a report from static context (game events called before _ready)
static func queue_report_static(text: String) -> void:
	# For static calls, send immediately to avoid queuing complexity
	send_message(text)
