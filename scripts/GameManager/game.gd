extends Node2D
class_name Game

const MoveHistoryPanelContainer = preload("res://scripts/UI/move_history_panel_container.gd")

signal wait_selected

const OPENING_HAND_SIZE := 5

@onready var hand: HandUI = $UI/Handler/HandUi
@onready var deck_ui: DeckUI = $UI/Handler/DeckUI

var player: Player
var selected_piece: Vector2
var board: Board
var current_player: int = 0
var history_panel: MoveHistoryPanelContainer
var turn_label: Label
var status_label: Label
var game_over_label: Label
var reset_button: Button
var game_over: bool = false
var preparation_complete: bool = false
var battle_started: bool = false

func _ready() -> void:
	board = get_node_or_null("Board") as Board
	SignalBus.unit_moved.connect(_on_unit_moved)
	var banner_mgr = get_node_or_null("UI/EventBannerManager")
	if banner_mgr != null:
		banner_mgr.banner_started.connect(_on_banner_started)
		banner_mgr.banner_finished.connect(_on_banner_finished)
	SignalBus.turn_wait_confirmed.connect(_on_turn_wait_confirmed)
	SignalBus.move_history_undone.connect(_on_move_history_undone)
	SignalBus.game_over.connect(_on_game_over)
	SignalBus.royal_assignment_finished.connect(_on_royal_assignment_finished)
	SignalBus.royal_defeated.connect(_on_royal_defeated)
	SignalBus.piece_defeated.connect(_on_piece_defeated)
	hand.card_requested.connect(_on_hand_card_requested)
	hand.opening_draw_started.connect(_on_opening_draw_started)
	hand.opening_draw_completed.connect(_on_opening_draw_completed)
	_history_panel_setup()
	add_ui()
	if board != null:
		player = board.get_player(0)
		if player == null:
			player = Player.new(0)
		hand.set_player(player)
		hand.set_deck_ui(deck_ui)
		board.setup_initial_pieces()

func _process(_delta: float) -> void:
	pass

func start_preparation_phase() -> void:
	if board == null:
		return
	var white_player := board.get_player(0)
	var black_player := board.get_player(1)
	if white_player != null:
		white_player.initialize_deck()
		white_player.shuffle_deck()
	if black_player != null:
		black_player.initialize_deck()
		black_player.shuffle_deck()
	player = white_player if white_player != null else player
	if player != null:
		player.suppress_hand_changed = true
	if hand != null and player != null:
		hand.set_player(player)
	if player != null:
		player.draw_opening_hand()
	if black_player != null:
		black_player.draw_opening_hand()
	if player != null:
		player.suppress_hand_changed = false
		player.hand_changed.emit()

func start_battle() -> void:
	if board == null:
		return
	board.current_turn = current_player
	board.game_over = false
	game_over = false
	if game_over_label:
		game_over_label.visible = false
	begin_turn_for_player(board.get_player(current_player))
	update_ui()

func begin_turn_for_player(active_player: Player) -> void:
	if active_player == null:
		return
	if battle_started:
		active_player.begin_turn()
		if active_player == player and hand != null:
			hand.refresh()
	else:
		battle_started = true

func check_for_win_condition() -> void:
	print("checking for winner")

func _on_unit_moved(unit: Unit, from_cell: Vector2i, to_cell: Vector2i) -> void:
	if game_over:
		return
	update_ui()

func _on_turn_wait_confirmed(unit: Unit, from_cell: Vector2i, to_cell: Vector2i) -> void:
	if game_over:
		return
	var notation := format_move(unit, from_cell, to_cell)
	history_panel.add_move(notation)
	update_ui()

func _on_move_history_undone() -> void:
	if game_over:
		return
	history_panel.undo_last_move()
	update_ui()

func _on_game_over(winner: int) -> void:
	game_over = true
	if winner == -1:
		game_over_label.text = "Draw by stalemate!"
	else:
		var winner_name := "White" if winner == 0 else "Black"
		game_over_label.text = "%s wins by usurpation!" % winner_name
	game_over_label.visible = true
	reset_button.visible = true
	update_ui()

func _on_royal_assignment_finished(team: int) -> void:
	if preparation_complete:
		return
	preparation_complete = true
	start_preparation_phase()
	start_battle()

func _on_royal_defeated(unit: Unit) -> void:
	if unit == null:
		return
	var team_name := "White" if unit.team == 0 else "Black"
	var message := "%s's monarch has fallen!" % team_name
	if status_label != null:
		status_label.text = message
	if game_over_label != null:
		game_over_label.text = message
		game_over_label.visible = true
	update_ui()

func _on_piece_defeated(victim: Unit, killer: Unit) -> void:
	if victim == null or killer == null:
		return
	var victim_team_name := "White" if victim.team == 0 else "Black"
	var killer_team_name := "White" if killer.team == 0 else "Black"
	var message := "%s's %s killed %s's %s." % [killer_team_name, killer.get_piece_name(), victim_team_name, victim.get_piece_name()]
	if status_label != null:
		status_label.text = message
	update_ui()

func _on_opening_draw_started() -> void:
	var banner_mgr = get_node_or_null("UI/EventBannerManager")
	if banner_mgr != null and banner_mgr.has_method("set_hold_phase_banner"):
		banner_mgr.set_hold_phase_banner(true)

func _on_opening_draw_completed() -> void:
	var banner_mgr = get_node_or_null("UI/EventBannerManager")
	if banner_mgr != null and banner_mgr.has_method("set_hold_phase_banner"):
		banner_mgr.set_hold_phase_banner(false)

func _on_banner_started() -> void:
	if board != null:
		board.set_input_locked(true)

func _on_banner_finished() -> void:
	if board != null:
		board.set_input_locked(false)

func _on_reset_pressed() -> void:
	reset_button.visible = false
	game_over_label.visible = false
	history_panel.clear_history()
	current_player = 0
	preparation_complete = false
	battle_started = false
	board.current_turn = current_player
	board.game_over = false
	board.board_state = board.BoardState.IDLE
	board.clear_board()
	board.setup_initial_pieces()
	update_ui()

func format_move(unit: Unit, from_cell: Vector2i, to_cell: Vector2i) -> String:
	var piece_name := unit.piece_type.capitalize()
	var from_notation := coordinate_to_notation(from_cell)
	var to_notation := coordinate_to_notation(to_cell)
	var prefix := "White" if unit.team == 0 else "Black"
	if piece_name == "Pawn":
		piece_name = ""
	return "%s: %s%s -> %s" % [prefix, piece_name, from_notation, to_notation]

#Gridmap Cell coordinate to Chess cell coordinate conversion
func coordinate_to_notation(cell: Vector2i) -> String:
	var files := "abcdefgh"
	return files[cell.x] + str(8 - cell.y)

func _history_panel_setup() -> void:
	history_panel = get_node_or_null("UI/Handler/Game_Panel/MoveHistoryPanelContainer") as MoveHistoryPanelContainer
	if history_panel == null:
		push_error("MoveHistoryPanelContainer not found in scene tree")

func add_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "GameUI"
	add_child(canvas)

	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.position = Vector2(20, 20)
	turn_label.scale = Vector2(1.2, 1.2)
	canvas.add_child(turn_label)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(5, 335)
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.size = Vector2(320, 120)
	canvas.add_child(status_label)

	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.position = Vector2(20, 430)
	game_over_label.scale = Vector2(1.5, 1.5)
	game_over_label.visible = false
	game_over_label.modulate = Color.RED
	canvas.add_child(game_over_label)

	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "Replay"
	reset_button.position = Vector2(20, 500)
	reset_button.visible = false
	reset_button.pressed.connect(_on_reset_pressed)
	canvas.add_child(reset_button)

func update_ui() -> void:
	# Sync current_player with board's turn
	current_player = board.current_turn
	if board != null and board.has_method("is_royal_assignment_active") and board.is_royal_assignment_active():
		status_label.text = "Choose your monarch for %s." % ("White" if current_player == 0 else "Black")
	elif board != null and board.game_over:
		status_label.text = "The throne has been claimed."

func validate_card_play(card: Card, mouse_pos: Vector2) -> bool:
	if game_over or card == null or player == null or board == null:
		return false
	if not player.hand.has(card):
		return false
	if player.current_mana < card.mana_cost:
		return false
	if current_player != player.team:
		return false

	var target_cell := board.world_to_grid(mouse_pos)
	if not board.is_within_bounds(target_cell):
		return false
	var target_unit := board.get_unit_at(target_cell)

	if card.has_play_condition("requires_pawn") and target_unit != null and target_unit.piece_type.to_lower() != "pawn":
		return false
	if card.has_play_condition("requires_ally") and target_unit != null and target_unit.team != player.team:
		return false
	if card.has_play_condition("requires_enemy") and target_unit != null and target_unit.team == player.team:
		return false
	if card.has_play_condition("requires_empty_cell") and target_unit != null:
		return false
	if card.has_play_condition("requires_damaged_unit") and target_unit != null and target_unit.is_alive():
		return false
	if card.has_play_condition("requires_promotion_candidate") and target_unit != null and target_unit.piece_type.to_lower() != "pawn":
		return false

	var allowed_targets := board.get_valid_card_targets(card, player)
	if allowed_targets.is_empty():
		return card.target_type == Card.TargetType.NONE
	return allowed_targets.has(target_cell)

func _on_hand_card_requested(card: Card, mouse_pos: Vector2) -> void:
	if game_over:
		return
	if player == null or card == null:
		return
	if not player.hand.has(card):
		return
	if not validate_card_play(card, mouse_pos):
		return
	if not player.spend_mana(card.mana_cost):
		return

	player.discard_card(card)
	print("Game accepted card play request for: ", card.card_name)

	card.play({
		"player": player,
		"game": self,
		"board": board,
		"target_cell": board.world_to_grid(mouse_pos)
	})

	update_ui()

func _on_draw_button_pressed() -> void:
	print("Hand size:", player.hand.size())
	print("UI children:", hand.card_container.get_child_count())
	if player == null:
		return
	player.draw_card()

func _on_discard_pressed() -> void:
	if player == null or player.hand.is_empty():
		return
	player.discard_card(player.hand[-1])
