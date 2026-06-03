# game_state.gd
# Phase 7: Single source of truth for all shared mutable state.
# ProximitySystem writes here. All managers and main.gd read from here.
# No more duplicate state across managers.
class_name GameState
extends Node

# ── Floor navigation ─────────────────────────────────────────────────────────
var current_floor_idx: int = 0

# ── Proximity flags (written by ProximitySystem) ───────────────────────────
var nearby_section: Node = null
var nearby_checkout: Node = null
var nearby_stall: Node = null
var nearby_claw_machine: Node = null
var nearby_npc_for_chat: Node = null
var nearby_elevator: bool = false
var nearby_stairs: bool = false
var nearby_parking: bool = false
var nearby_warehouse: bool = false
var nearby_warehouse_dock: bool = false
var nearby_terminal: bool = false
var nearby_loyalty: bool = false
var nearby_gift_wrap: bool = false
var nearby_digital_kiosk: bool = false
var nearby_info_desk: bool = false
var nearby_cafe: bool = false
var nearby_promo_booth: bool = false
var nearby_lost_found: bool = false
var nearby_store_news: bool = false
var nearby_vending: bool = false
var nearby_karaoke: bool = false
var nearby_pool_table: bool = false
var nearby_darts_board: bool = false
var nearby_atm: bool = false
var nearby_monitor: bool = false
var nearby_issue: bool = false

# ── Mode flags ──────────────────────────────────────────────────────────────
var in_elevator: bool = false
var warehouse_mode: bool = false
var checkout_receipt_visible: bool = false
var temp_order_mode: String = ""
var cart_gift_wrapped: bool = false
var staff_blocked_floor: int = -1
var truck_arrived: bool = false

# ── Temp data ───────────────────────────────────────────────────────────────
var temp_order_items: Array = []
var current_section_browse: Node = null
var target_issue: Object = null

# ── Player reference (set once at spawn) ───────────────────────────────────
var player: Node = null

# ── Signals ────────────────────────────────────────────────────────────────
signal floor_changed(idx: int)
signal proximity_updated()        # Emitted when any proximity flag changes
signal mode_changed(flag: String, value)  # Generic mode change

# ── Convenience: bulk write proximity flags ──────────────────────────────────
func set_proximity_flags(p: Dictionary) -> void:
	if p.has("section"):    nearby_section     = p.section
	if p.has("checkout"):   nearby_checkout    = p.checkout
	if p.has("stall"):     nearby_stall       = p.stall
	if p.has("claw"):      nearby_claw_machine = p.claw
	if p.has("npc"):       nearby_npc_for_chat = p.npc
	if p.has("elevator"):  nearby_elevator    = p.elevator
	if p.has("stairs"):    nearby_stairs       = p.stairs
	if p.has("parking"):   nearby_parking      = p.parking
	if p.has("warehouse"): nearby_warehouse    = p.warehouse
	if p.has("dock"):      nearby_warehouse_dock = p.dock
	if p.has("terminal"):  nearby_terminal     = p.terminal
	if p.has("loyalty"):   nearby_loyalty      = p.loyalty
	if p.has("gift_wrap"): nearby_gift_wrap    = p.gift_wrap
	if p.has("kiosk"):     nearby_digital_kiosk = p.kiosk
	if p.has("info_desk"): nearby_info_desk    = p.info_desk
	if p.has("cafe"):      nearby_cafe         = p.cafe
	if p.has("promo"):     nearby_promo_booth  = p.promo
	if p.has("lost_found"):nearby_lost_found   = p.lost_found
	if p.has("news"):      nearby_store_news    = p.news
	if p.has("vending"):   nearby_vending      = p.vending
	if p.has("karaoke"):   nearby_karaoke      = p.karaoke
	if p.has("pool"):      nearby_pool_table   = p.pool
	if p.has("darts"):     nearby_darts_board  = p.darts
	if p.has("atm"):       nearby_atm          = p.atm
	if p.has("monitor"):    nearby_monitor      = p.monitor
	if p.has("issue"):     nearby_issue        = p.issue
	emit_signal("proximity_updated")

func set_mode_flags(m: Dictionary) -> void:
	if m.has("elevator"):      in_elevator               = m.elevator
	if m.has("warehouse"):      warehouse_mode            = m.warehouse
	if m.has("receipt"):       checkout_receipt_visible  = m.receipt
	if m.has("temp_order"):    temp_order_mode          = m.temp_order
	if m.has("cart_gift"):     cart_gift_wrapped         = m.cart_gift
	if m.has("staff_blocked"): staff_blocked_floor      = m.staff_blocked
	if m.has("truck"):         truck_arrived             = m.truck
	emit_signal("mode_changed", "", null)

# ── Convenience: read current nearby as interaction dict ─────────────────────
func get_proximity_as_dict() -> Dictionary:
	return {
		"section":      nearby_section,
		"checkout":     nearby_checkout,
		"stall":       nearby_stall,
		"claw":         nearby_claw_machine,
		"npc":          nearby_npc_for_chat,
		"elevator":     nearby_elevator,
		"stairs":       nearby_stairs,
		"parking":      nearby_parking,
		"warehouse":    nearby_warehouse,
		"dock":         nearby_warehouse_dock,
		"terminal":     nearby_terminal,
		"loyalty":      nearby_loyalty,
		"gift_wrap":    nearby_gift_wrap,
		"kiosk":        nearby_digital_kiosk,
		"info_desk":    nearby_info_desk,
		"cafe":         nearby_cafe,
		"promo":        nearby_promo_booth,
		"lost_found":   nearby_lost_found,
		"news":         nearby_store_news,
		"vending":      nearby_vending,
		"karaoke":      nearby_karaoke,
		"pool":         nearby_pool_table,
		"darts":        nearby_darts_board,
		"atm":          nearby_atm,
		"monitor":      nearby_monitor,
		"issue":        nearby_issue,
	}
