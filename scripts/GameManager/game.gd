extends Node2D
class_name Game

const MoveHistoryPanelContainer = preload("res://scripts/UI/move_history_panel_container.gd")

signal wait_selected

const OPENING_HAND_SIZE := 5

@onready var hand: HandUI = $UI/Handler/HandUI
@onready var deck_ui: DeckUI = $UI/Handler/DeckUI
@onready var draw_button: Button = $UI/Handler/Game_Panel/DrawButton
@onready var discard_button: Button = $UI/Handler/Game_Panel/Discard
@onready var hand_toggle_button: Button = $UI/Handler/Game_Panel/HandToggle

var player: Player
var selected_piece: Vector2
var board: Board
var current_player: int = 0
var history_panel: MoveHistoryPanelContainer
var turn_label: Label
var status_label: Label
var mana_label: Label
var game_over_label: Label
var reset_button: Button
var targeting_prompt_label: Label
var game_over: bool = false
var preparation_complete: bool = false
var battle_started: bool = false
var _banner_active: bool = false
var _must_discard_for_hand_limit: bool = false

# A pending card is owned by the player who began targeting, not whoever is active later.
var pending_card: Card = null
var pending_card_player: Player = null

func _ready() -> void:
	board = get_node_or_null("Board") as Board
	SignalBus.unit_moved.connect(_on_unit_moved)
	var banner_mgr = get_node_or_null("UI/EventBannerManager")
	if banner_mgr != null:
		banner_mgr.banner_started.connect(_on_banner_started)
		banner_mgr.banner_finished.connect(_on_banner_finished)
	SignalBus.turn_wait_confirmed.connect(_on_turn_wait_confirmed)
	SignalBus.round_ended.connect(_on_round_ended)
	SignalBus.round_started.connect(_on_round_started)
	SignalBus.move_history_undone.connect(_on_move_history_undone)
	SignalBus.game_over.connect(_on_game_over)
	SignalBus.royal_assignment_finished.connect(_on_royal_assignment_finished)
	SignalBus.royal_defeated.connect(_on_royal_defeated)
	SignalBus.piece_defeated.connect(_on_piece_defeated)
	hand.card_requested.connect(_on_hand_card_requested)
	hand.card_selected.connect(_on_hand_card_selected)
	hand.opening_draw_started.connect(_on_opening_draw_started)
	hand.opening_draw_completed.connect(_on_opening_draw_completed)
	if hand_toggle_button != null:
		hand_toggle_button.pressed.connect(_on_hand_toggle_pressed)
	if not SignalBus.cell_selected.is_connected(_on_targeting_cell_selected):
		SignalBus.cell_selected.connect(_on_targeting_cell_selected)
	_history_panel_setup()
	add_ui()
	if board != null:
		player = board.get_player(0)
		if player == null:
			player = Player.new(0)
		hand.set_player(player)
		hand.set_deck_ui(deck_ui)
		draw_button.disabled = true
		discard_button.disabled = true
		hand_toggle_button.disabled = true
		board.setup_initial_pieces()

func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if pending_card != null and event.is_action_pressed("ui_cancel"):
		cancel_card_targeting()
		get_viewport().set_input_as_handled()

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

func get_active_player() -> Player:
	if board == null:
		return null

	return board.get_player(board.current_turn)

func begin_turn_for_player(active_player: Player) -> void:
	if active_player == null:
		return

	battle_started = true
	active_player.begin_turn()

	draw_button.disabled = false
	discard_button.disabled = false

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

func _on_round_ended(team: int) -> void:
	if game_over or player == null or team != player.team:
		return
	if player.hand.size() < player.hand_size_limit:
		return
	_must_discard_for_hand_limit = true
	if board != null:
		board.defer_turn_transition()
	hand.set_card_selection_mode(true)
	hand.set_hidden(false)
	if hand_toggle_button != null:
		hand_toggle_button.text = "Hide Cards"
		hand_toggle_button.disabled = true
	discard_button.disabled = true
	status_label.text = "Choose a card to discard before the next turn."
	if board != null:
		board.set_input_locked(true)

func _on_round_started(team: int) -> void:
	if pending_card != null and (pending_card_player == null or pending_card_player.team != team):
		cancel_card_targeting()
	if board == null:
		return
	var active_player := board.get_player(team)
	if active_player == null:
		return

	player = active_player
	#hand.set_player(player) - Commenting this out because we are implementing online multiplayer first
	begin_turn_for_player(active_player)
	update_ui()

func _on_hand_card_selected(card: Card) -> void:
	if not _must_discard_for_hand_limit or player == null or not player.hand.has(card):
		return
	player.discard_card(card)
	if player.hand.size() >= player.hand_size_limit:
		status_label.text = "Choose another card to discard before the next turn."
		return

	_must_discard_for_hand_limit = false
	hand.set_card_selection_mode(false)
	discard_button.disabled = false
	if hand_toggle_button != null:
		hand_toggle_button.disabled = false
	if status_label.text.begins_with("Choose a card"):
		status_label.text = ""
	if board != null:
		board.resume_turn_transition()
	update_ui()
	if board != null:
		board.set_input_locked(_banner_active)

func _on_move_history_undone() -> void:
	if game_over:
		return
	history_panel.undo_last_move()
	update_ui()

func _on_game_over(winner: int) -> void:
	if pending_card != null:
		cancel_card_targeting()
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
	_banner_active = true
	if board != null:
		board.set_input_locked(true)

func _on_banner_finished() -> void:
	_banner_active = false
	if board != null:
		board.set_input_locked(_must_discard_for_hand_limit)

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

	mana_label = Label.new()
	mana_label.name = "ManaLabel"
	mana_label.position = Vector2(5, 300)
	mana_label.size = Vector2(320, 40)
	canvas.add_child(mana_label)

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

	targeting_prompt_label = Label.new()
	targeting_prompt_label.name = "TargetingPrompt"
	targeting_prompt_label.position = Vector2(350, 20)
	targeting_prompt_label.size = Vector2(500, 60)
	targeting_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	targeting_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	targeting_prompt_label.add_theme_font_size_override("font_size", 22)
	targeting_prompt_label.visible = false
	canvas.add_child(targeting_prompt_label)

func update_ui() -> void:
	current_player = board.current_turn
	if turn_label != null:
		turn_label.text = "Turn: %s" % ("White" if current_player == 0 else "Black")
	if mana_label != null:
		var active_player := board.get_player(current_player) if board != null else player
		if active_player != null:
			mana_label.text = "Mana: %d / %d" % [active_player.current_mana, active_player.max_mana]
		else:
			mana_label.text = "Mana: 0 / 0"
	if board != null and board.has_method("is_royal_assignment_active") and board.is_royal_assignment_active():
		status_label.text = "Choose your monarch for %s." % ("White" if current_player == 0 else "Black")
	elif board != null and board.game_over:
		status_label.text = "The throne has been claimed."

func is_targetless_card(card: Card) -> bool:
	return card.target_type in [
		Card.TargetType.NONE,
		Card.TargetType.SELF,
		Card.TargetType.ALL_ALLIES,
		Card.TargetType.ALL_ENEMIES
	]

func get_card_targeting_prompt(card: Card) -> String:
	if card == null:
		return ""

	var prompt := "Select a target."
	match card.target_type:
		Card.TargetType.ALLY_UNIT:
			prompt = "Select an allied unit."
		Card.TargetType.ENEMY_UNIT:
			prompt = "Select an enemy unit."
		Card.TargetType.ANY_UNIT:
			prompt = "Select a unit."
		Card.TargetType.EMPTY_CELL:
			prompt = "Select an empty board cell."
		Card.TargetType.ANY_CELL:
			prompt = "Select a board cell."
		Card.TargetType.ANY_QUADRANT:
			prompt = "Select a quadrant."
		Card.TargetType.SELF_QUADRANT:
			prompt = "Select your quadrant."
		Card.TargetType.ENEMY_QUADRANT:
			prompt = "Select the enemy quadrant."
		Card.TargetType.SELF:
			prompt = "Activate on yourself."
		Card.TargetType.ALL_ALLIES:
			prompt = "Apply to all allied units."
		Card.TargetType.ALL_ENEMIES:
			prompt = "Apply to all enemy units."

	if card.has_play_condition("requires_empty_cell"):
		prompt = "Select an empty board cell."
	elif card.has_play_condition("requires_promotion_candidate"):
		prompt = "Select a unit eligible for promotion."
	elif card.has_play_condition("requires_pawn"):
		var pawn_description := "pawn"
		if card.target_type == Card.TargetType.ALLY_UNIT or card.has_play_condition("requires_ally"):
			pawn_description = "allied pawn"
		elif card.target_type == Card.TargetType.ENEMY_UNIT or card.has_play_condition("requires_enemy"):
			pawn_description = "enemy pawn"
		prompt = "Select %s." % pawn_description
	elif card.has_play_condition("requires_damaged_unit"):
		if card.target_type == Card.TargetType.ALLY_UNIT or card.has_play_condition("requires_ally"):
			prompt = "Select a damaged allied unit."
		elif card.target_type == Card.TargetType.ENEMY_UNIT or card.has_play_condition("requires_enemy"):
			prompt = "Select a damaged enemy unit."
		else:
			prompt = "Select a damaged unit."
	elif card.has_play_condition("requires_ally"):
		prompt = "Select an allied unit."
	elif card.has_play_condition("requires_enemy"):
		prompt = "Select an enemy unit."

	return prompt

func _show_targeting_prompt(text: String) -> void:
	if targeting_prompt_label != null:
		targeting_prompt_label.text = text
		targeting_prompt_label.visible = not text.is_empty()
	SignalBus.card_targeting_prompt_changed.emit(text)

func validate_card_play(card: Card, context: EffectContext) -> bool:
	if game_over or card == null or context == null:
		return false

	if board == null:
		return false

	var active_player := get_active_player()

	if active_player == null:
		return false

	# Make sure this is the active player's card.
	if context.player != active_player:
		return false

	if not active_player.hand.has(card):
		return false

	# Check mana.
	if active_player.current_mana < card.mana_cost:
		return false

	# Check target bounds for cell-targeted cards.
	if not is_targetless_card(card):
		if not board.is_within_bounds(context.target_cell):
			return false
		print("Checking target type:", card.target_type)
		print("Checking target cell:", context.target_cell)

		# Check whether the selected cell is a legal target.
		var allowed_targets := board.get_valid_card_targets(card, active_player)
		print("Allowed targets:", allowed_targets)
		
		if not allowed_targets.has(context.target_cell):
			return false

	# Check card-specific conditions.
	if not validate_play_conditions(card, context):
		return false

	# Finally, validate every effect.
	return card.can_execute(context)

func validate_play_conditions(card: Card, context: EffectContext) -> bool:
	for condition in card.play_conditions:
		match condition.strip_edges().to_lower():

			"requires_pawn":
				if context.target_unit == null:
					print("FAILED requires_pawn: Target is null.")
					return false
				if context.target_unit.piece_type.to_lower() != "pawn":
					print("FAILED requires_pawn: Target is not a pawn.")
					return false

			"requires_ally":
				if context.target_unit == null:
					print("FAILED requires_ally: Target is null.")
					return false
				if context.target_unit.team != context.player.team:
					return false

			"requires_enemy":
				if context.target_unit == null:
					print("FAILED requires_enemy: Target is null.")
					return false
				if context.target_unit.team == context.player.team:
					return false

			"requires_empty_cell":
				if context.target_unit != null:
					print("FAILED requires_empty_cell: Target is null.")
					return false

			"requires_damaged_unit":
				if context.target_unit == null:
					print("FAILED requires_damaged_unit: Target is null.")
					return false
				if not context.target_unit.is_damaged():
					return false

			"requires_promotion_candidate":
				if context.target_unit == null:
					print("FAILED requires_promotion_candidate: Target is null.")
					return false
				if not context.target_unit.can_be_promoted():
					return false

			_:
				push_warning("Unknown card play condition: " + condition)
				return false

	return true

func _create_effect_context(card: Card, target_cell: Vector2i, target_unit: Unit, owner_player: Player) -> EffectContext:
	var context := EffectContext.new(
		self,
		board,
		owner_player,
		card
	)
	context.owner_player = owner_player
	context.target_cell = target_cell
	context.target_unit = target_unit
	context.target_player = board.get_player(target_unit.team) if target_unit != null else null
	if card.target_type == Card.TargetType.SELF:
		context.target_player = owner_player
	if card.target_type in [
		Card.TargetType.ANY_QUADRANT,
		Card.TargetType.SELF_QUADRANT,
		Card.TargetType.ENEMY_QUADRANT
	] and board.is_within_bounds(target_cell):
		context.target_quadrant = int(target_cell.y / 4) * 2 + int(target_cell.x / 4)
	return context

func _on_hand_card_requested(card: Card, _mouse_pos: Vector2) -> void:
	if game_over or card == null or board == null:
		return
	if pending_card != null:
		return

	var active_player := get_active_player()
	if active_player == null or not active_player.hand.has(card):
		return
	if active_player.current_mana < card.mana_cost:
		if status_label != null:
			status_label.text = "Not enough mana to play this card."
		return

	if is_targetless_card(card):
		var context := _create_effect_context(card, Vector2i(-1, -1), null, active_player)
		if resolve_card_play(card, active_player, context):
			_show_targeting_prompt("")
		return

	pending_card = card
	pending_card_player = active_player
	_show_targeting_prompt(get_card_targeting_prompt(card))
	board.show_card_target_highlights(card, active_player)
	SignalBus.card_targeting_started.emit(card)

func _on_targeting_cell_selected(cell: Vector2i) -> void:
	if pending_card == null or pending_card_player == null or board == null:
		return
	if pending_card_player != get_active_player():
		cancel_card_targeting()
		return

	var target_unit := board.get_unit_at(cell)
	var context := _create_effect_context(pending_card, cell, target_unit, pending_card_player)
	var card_to_play := pending_card
	var owner_to_play := pending_card_player
	if not resolve_card_play(card_to_play, owner_to_play, context):
		_show_targeting_prompt("Invalid target. " + get_card_targeting_prompt(card_to_play))
		return
	cancel_card_targeting()

func cancel_card_targeting() -> void:
	var was_targeting := pending_card != null or pending_card_player != null
	pending_card = null
	pending_card_player = null
	if board != null:
		board.clear_highlights()
	_show_targeting_prompt("")
	if was_targeting:
		SignalBus.card_targeting_ended.emit()

func resolve_card_play(
	card: Card,
	caster: Player,
	context: EffectContext
) -> bool:
	if board == null or caster == null or caster != get_active_player() or game_over:
		return false
	if context == null or context.player != caster:
		return false
	if not validate_card_play(card, context):
		return false
	if not caster.spend_mana(card.mana_cost):
		return false

	caster.discard_card(card)
	card.play(context)
	if board != null:
		board.clear_highlights()
	update_ui()
	return true

func _on_draw_button_pressed() -> void:
	if player == null:
		return
	print("Hand size:", player.hand.size())
	print("UI children:", hand.card_container.get_child_count())
	var active_player := board.get_player(current_player) if board != null else player
	if active_player == null or current_player != active_player.team:
		return
	active_player.draw_card()

func _on_discard_pressed() -> void:
	if player == null or player.hand.is_empty():
		return
	player.discard_card(player.hand[-1])

func _on_hand_toggle_pressed() -> void:
	var hidden := hand.toggle_hidden()
	hand_toggle_button.text = "Show Cards" if hidden else "Hide Cards"
