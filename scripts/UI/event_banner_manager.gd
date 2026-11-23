extends Node2D

# Manager for showing EventBanner scenes in sequence

class_name EventBannerManager

const TurnBannerScene := preload("res://scenes/UI/TurnBanner.tscn")
const PieceDeathBannerScene := preload("res://scenes/UI/PieceDeathBanner.tscn")
const BattleOverBannerScene := preload("res://scenes/UI/BattleOverBanner.tscn")

signal banner_started
signal banner_finished

enum BannerType {
	TURN,
	PHASE_ROYAL_ASSIGNMENT,
	PIECE_DEATH,
	BATTLE_OVER
}

var _queue: Array = []
var _showing: bool = false
var _delay_after_battle: bool = false
var _royal_phase_banner_scheduled: bool = false
var _hold_phase_banner: bool = false
var _pending_phase_team: int = -1

func _ready() -> void:
	get_tree().node_added.connect(_on_tree_node_added)
	# connect to the SignalBus autoload (registered as SignalBus)
	var bus = get_node_or_null("/root/SignalBus")
	if bus != null:
		bus.connect("round_started", Callable(self, "_on_round_started"))
		bus.connect("piece_defeated", Callable(self, "_on_piece_defeated"))
		bus.connect("game_over", Callable(self, "_on_game_over"))
		bus.connect("royal_assignment_finished", Callable(self, "_on_royal_assignment_finished"))
	# if autoload isn't present at runtime nothing will crash; manager still works via announce_type()

func _on_tree_node_added(node: Node) -> void:
	if node.has_signal("battle_animation_finished") and not node.is_connected("battle_animation_finished", Callable(self, "_on_battle_animation_finished")):
		node.connect("battle_animation_finished", Callable(self, "_on_battle_animation_finished"))

func _on_battle_animation_finished() -> void:
	_delay_after_battle = true

# Centralized template builders for banner text
func _build_banner_for_type(btype: int, data: Dictionary) -> Dictionary:
	match btype:
		BannerType.TURN:
			var team = data.get("team", null)
			var name = "White" if team == 0 else "Black"
			return {"title": "%s Turn" % name, "subtitle": data.get("subtitle", "")}
		BannerType.PHASE_ROYAL_ASSIGNMENT:
			return {"title": "Choose Your Monarch", "subtitle": "Select one of your pieces to be your royalty."}
		BannerType.PIECE_DEATH:
			var victim: Variant = data.get("victim", null)
			var killer: Variant = data.get("killer", null)
			var v_name = "A unit"
			var v_piece = ""
			if victim:
				if victim.has_method("get_piece_name"):
					v_piece = victim.get_piece_name()
				v_name = "White" if victim.team == 0 else "Black"
			var k_name = ""
			var k_piece = ""
			if killer:
				if killer.has_method("get_piece_name"):
					k_piece = killer.get_piece_name()
				k_name = "White" if killer.team == 0 else "Black"
			var title = "%s's %s was defeated" % [v_name, v_piece]
			var subtitle = "Killed by %s's %s" % [k_name, k_piece]
			return {"title": title, "subtitle": subtitle}
		BannerType.BATTLE_OVER:
			var winner = data.get("winner", null)
			var w_text = "Draw" if winner == -1 else ("White" if winner == 0 else "Black")
			return {"title": "Battle Over", "subtitle": "Winner: %s" % w_text}
		_:
			return {"title":"Announcement","subtitle":""}

func announce_type(btype: int, data: Dictionary = {}) -> void:
	var built = _build_banner_for_type(btype, data)
	_queue.append({"type": btype, "title": built.title, "subtitle": built.subtitle})
	if not _showing:
		_process_queue()

func announce_custom(scene_path: PackedScene, title: String, subtitle: String = "") -> void:
	_queue.append({"scene":scene_path,"title":title,"subtitle":subtitle})
	if not _showing:
		_process_queue()

func _process_queue() -> void:
	if _queue.is_empty():
		_showing = false
		emit_signal("banner_finished")
		return
	if not _showing:
		_showing = true
		emit_signal("banner_started")
	if _delay_after_battle:
		_delay_after_battle = false
		await get_tree().create_timer(0.5).timeout
	var item = _queue.pop_front()
	var banner: Node2D = null
	if item.has("scene"):
		var scene = item.scene
		if scene is PackedScene:
			banner = scene.instantiate()
		else:
			banner = TurnBannerScene.instantiate()
	else:
		var btype = item.get("type", BannerType.TURN)
		match btype:
			BannerType.TURN:
				banner = TurnBannerScene.instantiate()
			BannerType.PIECE_DEATH:
				banner = PieceDeathBannerScene.instantiate()
			BannerType.BATTLE_OVER:
				banner = BattleOverBannerScene.instantiate()
			_:
				banner = TurnBannerScene.instantiate()

	add_child(banner)
	banner.show_banner(item.title, item.subtitle)
	# wait for finished signal
	await banner.finished
	banner.queue_free()
	# continue processing queue
	_process_queue()

# --- Signal handlers for gameplay events ---
func _on_round_started(round) -> void:
	announce_type(BannerType.TURN, {"team": round})

func _on_piece_defeated(victim, killer) -> void:
	announce_type(BannerType.PIECE_DEATH, {"victim": victim, "killer": killer})

func _on_game_over(winner) -> void:
	announce_type(BannerType.BATTLE_OVER, {"winner": winner})

func _on_royal_assignment_finished(team: int) -> void:
	# The first turn-phase banner should wait until the opening hand draw animation finishes.
	if _royal_phase_banner_scheduled:
		return
	if _hold_phase_banner:
		_pending_phase_team = team
		return
	_royal_phase_banner_scheduled = true
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(func() -> void:
		_royal_phase_banner_scheduled = false
		if _hold_phase_banner:
			_pending_phase_team = team
			return
		announce_type(BannerType.TURN, {"team": team})
	, CONNECT_ONE_SHOT)

func set_hold_phase_banner(hold: bool) -> void:
	_hold_phase_banner = hold
	if not _hold_phase_banner and _pending_phase_team >= 0:
		var team := _pending_phase_team
		_pending_phase_team = -1
		announce_type(BannerType.TURN, {"team": team})
