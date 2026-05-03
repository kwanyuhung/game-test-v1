# telegram_bot.gd
# Sends messages to Telegram when important events occur.
# Uses the configured bot token and admin chat_id.
extends Node

const BOT_TOKEN := "8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk"
const ADMIN_CHAT_ID := "1718058079"

func _ready() -> void:
	pass  # Call send_message() directly as static

static func send_message(text: String) -> bool:
	if BOT_TOKEN == "" or ADMIN_CHAT_ID == "":
		return false
	
	var url := "https://api.telegram.org/bot%s/sendMessage" % BOT_TOKEN
	var body := "chat_id=%s&text=%s&parse_mode=Markdown" % [ADMIN_CHAT_ID, text.uri_encode()]
	
	var http := HTTPRequest.new()
	var tree := Engine.get_main_loop()
	tree.root.add_child(http)
	
	var result = []
	var success = false
	
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

static func notify_commit(message: String) -> void:
	send_message("📦 *AutoCommit:*\n" + message)

static func notify_test_failed(errors: String) -> void:
	send_message("❌ *Test Failed:*\n" + errors)

static func notify_test_pass() -> void:
	send_message("✅ *Test Passed!*")
