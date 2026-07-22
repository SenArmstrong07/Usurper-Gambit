extends Node2D
class_name Board

const BOARD_SIZE = 8
var occupied_cells: Dictionary[Vector2i, Unit] = {}
var selected_unit: Unit = null
var dragging_unit: Unit = null
var current_turn: int = 0
var game_over: bool = false
var last_move_from: Vector2i = Vector2i.ZERO
var last_move_to: Vector2i = Vector2i.ZERO
var last_move_piece: Unit = null
var last_action_piece: Unit = null
var last_action_from: Vector2i = Vector2i.ZERO
var last_action_to: Vector2i = Vector2i.ZERO
var last_action_turn: int = 0
var last_action_has_moved: bool = false

@onready var units: Node2D = $Units
@onready var chess_board: TileMapLayer = $chessBoard
@onready var highlight_markers: Node2D = $HighlightMarkers
@onready var _tooltip: TooltipUI = $TooltipLayer/Tooltip
var throne_manager: ThroneManager = null
var players: Array[Player] = []
var assignment_overlay_layer: CanvasLayer = null
var assignment_overlay_rect: ColorRect = null
var hovered_assignment_unit: Unit = null
const HighlightScene = preload("res://scenes/UI/HighlightCells.tscn")
const HighlightAtkScene = preload("res://scenes/UI/HighlightAtk.tscn")
const ActionPopupScene = preload("res://scenes/UI/ActionPopup.tscn")
const Battle_Scene = preload("res://scenes/GameManager/Battle/BattleScene.tscn")
var highlighted_cells: Array
var post_move_unit: Unit = null
var pending_attack_unit: Unit = null
var pending_attack_targets: Array[Vector2i] = []
var pending_battle_attacker: Unit = null
var pending_battle_defender: Unit = null
var pending_history_actions: Array = []
var royal_assignment_active: bool = false

enum BoardState {
	IDLE,
	SELECTING,
	MOVING,
	COMBAT,
	AWAITING_ACTION,
	AWAITING_ATTACK_TARGET,
	AWAITING_ROYAL_ASSIGNMENT
}

var board_state = BoardState.IDLE

func _ready() -> void:
	add_to_group("Board")
	highlight_markers.visible = false
	throne_manager = ThroneManager.new()
	add_child(throne_manager)
	players = [Player.new(0), Player.new(1)]
	register_initial_thrones()
	print(chess_board.get_used_rect())
	print("Tile size:", chess_board.tile_set.tile_size)
	print("map_to_local(0,0):", chess_board.map_to_local(Vector2i(0,0)))
	print("map_to_local(1,0):", chess_board.map_to_local(Vector2i(1,0)))
	print("Board scale:", scale)
	print("TileMap scale:", chess_board.scale)
	print("Units scale:", units.scale)
	SignalBus.unit_dropped.connect(_on_unit_dropped)
	clear_highlights()


func _process(delta: float) -> void:
	#queue_redraw()
	pass

# func _draw():
# 	draw_rect(Rect2(Vector2.ZERO, Vector2(128,128)), Color.RED, false)

#Mouse Handlers
func _input(event: InputEvent) -> void:
	if game_over or board_state == BoardState.COMBAT:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse_pos := chess_board.get_local_mouse_position()
		var clicked_cell := chess_board.local_to_map(local_mouse_pos)
		handle_click(clicked_cell)
		print("Selected Cell: ", clicked_cell)

func handle_click(cell: Vector2i) -> void:
	if board_state == BoardState.AWAITING_ROYAL_ASSIGNMENT:
		var unit := get_unit_at(cell)
		if unit != null and unit.team == current_turn:
			assign_monarch_for_current_player(unit)
		return

	if board_state == BoardState.AWAITING_ATTACK_TARGET:
		if pending_attack_unit != null and pending_attack_targets.has(cell):
			var target := get_unit_at(cell)
			if target != null and target.team != pending_attack_unit.team:
				show_battle_overlay(pending_attack_unit, target)
				return
		clear_highlights()
		pending_attack_unit = null
		pending_attack_targets.clear()
		board_state = BoardState.IDLE
		return

	if board_state != BoardState.IDLE and board_state != BoardState.SELECTING:
		return

	var unit := get_unit_at(cell)
	if unit != null and unit.team == current_turn:
		select_unit(unit)
		return

	if selected_unit != null:
		if can_move_to(selected_unit, cell):
			if move_unit(selected_unit, cell):
				var moved_unit := selected_unit
				selected_unit = null
				clear_highlights()
				request_post_move_action(moved_unit)
			else:
				# combat failed or move invalid
				selected_unit = null
				clear_highlights()
		else:
			deselect()

func select_unit(unit: Unit) -> void:
	# Do not allow normal selection during the royal assignment phase
	if board_state == BoardState.AWAITING_ROYAL_ASSIGNMENT:
		return
	if unit.team != current_turn:
		return
	selected_unit = unit
	clear_highlights()
	var attackable_enemies := get_attackable_enemies(unit)
	var move_targets := get_non_attack_moves(unit)
	if attackable_enemies.is_empty():
		board_state = BoardState.SELECTING
		highlight_cells(move_targets)
	else:
		board_state = BoardState.AWAITING_ACTION
		var can_move := move_targets.size() > 0
		var popup := ActionPopupScene.instantiate() as Window
		# Ensure no other action popups remain (prevents exclusive-window and duplicates)
		_remove_existing_action_popups()
		# Add the popup to the viewport root so it's positioned in screen/gui coordinates
		get_tree().get_root().add_child(popup)
		popup.configure(can_move, true, "Move or attack?", "Move", "Attack", "Undo", can_undo_last_action())
		popup.wait_selected.connect(_on_selection_move)
		popup.attack_selected.connect(_on_selection_attack)
		popup.undo_selected.connect(_on_action_undo)
		position_action_popup(popup, unit)
	SignalBus.unit_selected.emit(unit)

func deselect() -> void:
	selected_unit = null
	clear_highlights()

func clear_highlights() -> void:
	for child in highlight_markers.get_children():
		child.queue_free()
	highlighted_cells.clear()
	highlight_markers.visible = false

func _on_unit_dropped(unit: Unit, cell: Vector2i) -> void:
	if game_over or board_state == BoardState.AWAITING_ROYAL_ASSIGNMENT:
		unit.position = chess_board.map_to_local(unit.grid_pos)
		deselect()
		return
	if unit == null:
		return
	if unit.team != current_turn:
		unit.position = chess_board.map_to_local(unit.grid_pos)
		deselect()
		return
	if can_move_to(unit, cell):
		if move_unit(unit, cell):
			request_post_move_action(unit)
		else:
			unit.position = chess_board.map_to_local(unit.grid_pos)
	else:
		unit.position = chess_board.map_to_local(unit.grid_pos)
	deselect()

# Helper to check if a coordinate is inside the 8x8 grid
func is_within_bounds(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.x < BOARD_SIZE and coords.y >= 0 and coords.y < BOARD_SIZE

func is_inside_board(coords: Vector2i) -> bool:
	return is_within_bounds(coords)

func grid_to_local(cell: Vector2i) -> Vector2:
	return chess_board.map_to_local(cell)

func world_to_grid(pos: Vector2) -> Vector2i:
	return chess_board.local_to_map(chess_board.to_local(pos))

#choosing first
func highlight_cells(cells: Array[Vector2i], use_attack_texture: bool = false) -> void:
	clear_highlights()
	for cell in cells:
		var marker: Node2D
		if use_attack_texture:
			marker = HighlightAtkScene.instantiate()
		else:
			marker = HighlightScene.instantiate()
		marker.position = chess_board.map_to_local(cell)
		highlight_markers.add_child(marker)
		highlighted_cells.append(marker)
	highlight_markers.visible = true

func setup_initial_pieces() -> void:
	clear_board()
	for x in range(BOARD_SIZE):
		spawn_piece("pawn", 0, Vector2i(x, 6))
		spawn_piece("pawn", 1, Vector2i(x, 1))

	var white_back_rank := ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
	var black_back_rank := ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
	for index in range(BOARD_SIZE):
		spawn_piece(white_back_rank[index], 0, Vector2i(index, 7))
		spawn_piece(black_back_rank[index], 1, Vector2i(index, 0))
	begin_royal_assignment()
	update_king_check_visuals()

func register_initial_thrones() -> void:
	if throne_manager == null:
		return
	throne_manager.register_throne(0, Vector2i(4, 7))
	throne_manager.register_throne(1, Vector2i(4, 0))

func clear_board() -> void:
	var children := units.get_children()
	for child in children:
		if child is Unit:
			if child.is_inside_tree():
				child.get_parent().remove_child(child)
			child.free()
	occupied_cells.clear()
	selected_unit = null
	dragging_unit = null
	for player in players:
		if player != null:
			player.clear_royal_unit()
	clear_highlights()

func spawn_piece(piece_type: String, team: int, grid_pos: Vector2i) -> Unit:
	var unit_scene: PackedScene
	match piece_type:
		"pawn":
			unit_scene = preload("res://scenes/Unit/pawn.tscn")
		"rook":
			unit_scene = preload("res://scenes/Unit/rook.tscn")
		"bishop":
			unit_scene = preload("res://scenes/Unit/bishop.tscn")
		"knight":
			unit_scene = preload("res://scenes/Unit/knight.tscn")
		"queen":
			unit_scene = preload("res://scenes/Unit/queen.tscn")
		"king":
			unit_scene = preload("res://scenes/Unit/king.tscn")
	var unit := unit_scene.instantiate() as Unit
	place_piece(unit, piece_type, team, grid_pos)
	print("Board global:", global_position)
	print("TileMap global:", chess_board.global_position)
	print("Units global:", units.global_position)
	print("Unit global:", unit.global_position)
	#print("Sprite global:", unit.sprite_node.global_position)
	return unit

func spawn_unit(unit_scene: PackedScene, grid_pos: Vector2i) -> Unit:
	var unit := unit_scene.instantiate() as Unit
	place_unit(unit, grid_pos)
	return unit

func place_piece(unit: Unit, piece_type_name: String, team_id: int, grid_pos: Vector2i) -> void:
	if not is_within_bounds(grid_pos):
		return
	if is_cell_occupied(grid_pos):
		return

	unit.piece_type = piece_type_name
	unit.team = team_id
	units.add_child(unit)
	occupied_cells[grid_pos] = unit
	unit.board = self
	unit.grid_pos = grid_pos
	unit.position = chess_board.map_to_local(grid_pos)
	unit.apply_sprite()
	unit.init_movement_component()
	print(grid_pos, " -> ", chess_board.map_to_local(grid_pos))
	print("Unit position:", position)
	print("Sprite position:", unit.sprite_node.position)
	print("Sprite offset:", unit.sprite_node.offset)
	print("Centered:", unit.sprite_node.centered)
	print(chess_board.transform)
	print(units.transform)
	SignalBus.unit_placed.emit(unit)

func place_unit(unit: Unit, grid_pos: Vector2i) -> void:
	place_piece(unit, unit.piece_type, unit.team, grid_pos)

func is_castling_move_legal(king: Unit, destination: Vector2i) -> bool:
	if king == null or king.piece_type.to_lower() != "king" or king.has_moved:
		return false

	if abs(destination.x - king.grid_pos.x) != 2 or king.grid_pos.y != destination.y:
		return false

	var rook_direction := -1 if destination.x < king.grid_pos.x else 1
	var rook_from := king.grid_pos + Vector2i(rook_direction * (4 if rook_direction < 0 else 3), 0)
	var rook_to := king.grid_pos + Vector2i(rook_direction, 0)
	if not is_within_bounds(rook_from) or not is_within_bounds(rook_to):
		return false

	var rook := get_unit_at(rook_from)
	if rook == null or rook.piece_type.to_lower() != "rook" or rook.team != king.team or rook.has_moved:
		return false

	if is_king_in_check(king.team):
		return false

	var path_clear := true
	var path_cells: Array[Vector2i] = []
	var current_path_cell := king.grid_pos + Vector2i(rook_direction, 0)
	while is_within_bounds(current_path_cell) and current_path_cell != rook_from:
		path_cells.append(current_path_cell)
		current_path_cell += Vector2i(rook_direction, 0)

	for path_cell in path_cells:
		if is_cell_occupied(path_cell):
			path_clear = false
			break

	if not path_clear or is_cell_occupied(destination) or is_cell_occupied(rook_to):
		return false

	var squares_to_check := path_cells.duplicate()
	squares_to_check.append(destination)
	for square in squares_to_check:
		if is_cell_attacked_by_team(square, 1 - king.team):
			return false

	return true

func move_unit(unit: Unit, destination: Vector2i) -> bool:
	if not is_within_bounds(destination):
		return false

	var start_pos := unit.grid_pos
	var previous_turn := current_turn
	var previous_has_moved := unit.has_moved
	var rook_to_move: Unit = null
	var rook_from: Vector2i = Vector2i.ZERO
	var rook_to: Vector2i = Vector2i.ZERO
	var piece_name := unit.piece_type.to_lower()

	if piece_name == "pawn":
		var direction := -1 if unit.team == 0 else 1
		var one_step := start_pos + Vector2i(0, direction)
		var two_step := start_pos + Vector2i(0, direction * 2)
		var left_capture := start_pos + Vector2i(-1, direction)
		var right_capture := start_pos + Vector2i(1, direction)

		if destination == one_step:
			if get_unit_at(destination) != null:
				return false
		elif destination == two_step:
			if get_unit_at(one_step) != null or get_unit_at(destination) != null:
				return false
		elif destination == left_capture or destination == right_capture:
			var target := get_unit_at(destination)
			if target == null or target.team == unit.team:
				return false
			var combat_result := unit.resolve_combat(target)
			if combat_result != "attacker_won":
				return false
			occupied_cells.erase(start_pos)
			occupied_cells[destination] = unit
			unit.grid_pos = destination
			unit.position = chess_board.map_to_local(destination)
			unit.has_moved = true
			if piece_name == "pawn" and (destination.y == 0 or destination.y == 7):
				unit.piece_type = "queen"
				unit.apply_sprite()
			unit.init_movement_component()
			last_move_from = start_pos
			last_move_to = destination
			last_move_piece = unit
			if rook_to_move == null:
				last_action_piece = unit
				last_action_from = start_pos
				last_action_to = destination
				last_action_turn = previous_turn
				last_action_has_moved = previous_has_moved
				pending_history_actions.append({"unit": unit, "from": start_pos, "to": destination, "type": "move"})
			SignalBus.unit_moved.emit(unit, start_pos, destination)
			update_king_check_visuals()
			return true
		else:
			return false
	elif piece_name == "king" and abs(destination.x - start_pos.x) == 2 and start_pos.y == destination.y:
		if not is_castling_move_legal(unit, destination):
			return false
		var rook_direction := -1 if destination.x < start_pos.x else 1
		rook_from = start_pos + Vector2i(rook_direction * (4 if rook_direction < 0 else 3), 0)
		rook_to = start_pos + Vector2i(rook_direction * 1, 0)
		rook_to_move = get_unit_at(rook_from)

	var target_at_destination := get_unit_at(destination)
	if target_at_destination != null and target_at_destination.team != unit.team:
		var combat_result := unit.resolve_combat(target_at_destination)
		if combat_result != "attacker_won":
			return false

	occupied_cells.erase(start_pos)
	if rook_to_move != null:
		occupied_cells.erase(rook_from)
		rook_to_move.grid_pos = rook_to
		rook_to_move.position = chess_board.map_to_local(rook_to)
		occupied_cells[rook_to] = rook_to_move
		rook_to_move.has_moved = true

	occupied_cells[destination] = unit
	unit.grid_pos = destination
	unit.position = chess_board.map_to_local(destination)
	unit.has_moved = true

	if piece_name == "king" and rook_to_move != null:
		unit.has_moved = true

	if piece_name == "pawn" and (destination.y == 0 or destination.y == 7):
		unit.piece_type = "queen"
		unit.apply_sprite()
		unit.init_movement_component()

	last_move_from = start_pos
	last_move_to = destination
	last_move_piece = unit
	if rook_to_move == null:
		last_action_piece = unit
		last_action_from = start_pos
		last_action_to = destination
		last_action_turn = previous_turn
		last_action_has_moved = previous_has_moved
		pending_history_actions.append({"unit": unit, "from": start_pos, "to": destination, "type": "move"})

	SignalBus.unit_moved.emit(unit, start_pos, destination)
	update_king_check_visuals()
	return true

func remove_unit(unit: Unit) -> void:
	if unit == null:
		return
	if unit.grid_pos != Vector2i.ZERO and occupied_cells.has(unit.grid_pos):
		occupied_cells.erase(unit.grid_pos)
	if unit.is_inside_tree():
		units.remove_child(unit)
	if unit.is_royal:
		var player := get_player(unit.team)
		if player != null:
			player.mark_royal_defeated()
		unit.remove_royalty()
		SignalBus.royal_defeated.emit(unit)
	check_victory_conditions()
	unit.queue_free()

func get_unit_at(cell: Vector2i) -> Unit:
	if occupied_cells.has(cell):
		return occupied_cells[cell]
	return null

func find_path(current_grid_pos: Vector2i, new_grid_pos: Vector2i):
	return Vector2i.ZERO

func can_move_to(unit: Unit, destination: Vector2i) -> bool:
	if unit == null:
		return false
	return destination in unit.get_valid_moves(self)

func request_post_move_action(unit: Unit) -> void:
	if unit == null:
		return
	post_move_unit = unit
	board_state = BoardState.AWAITING_ACTION
	var can_attack := false
	for enemy in units.get_children():
		if not (enemy is Unit):
			continue
		if enemy.team == unit.team:
			continue
		if unit.can_attack_target(enemy):
			can_attack = true
			break
	# After checking enemies, show the popup once with the correct can_attack flag
	var popup := ActionPopupScene.instantiate() as Window
	# Ensure no other action popups remain (prevents exclusive-window and duplicates)
	_remove_existing_action_popups()
	# Add the popup to the viewport root so it's positioned in screen/gui coordinates
	get_tree().get_root().add_child(popup)
	popup.configure(true, can_attack, "Wait or attack?", "Wait", "Attack", "Undo", can_undo_last_action())
	popup.wait_selected.connect(_on_action_wait)
	popup.attack_selected.connect(_on_action_attack)
	popup.undo_selected.connect(_on_action_undo)
	position_action_popup(popup, unit)

func position_action_popup(popup: Window, anchor_unit: Unit) -> void:
	if popup == null or anchor_unit == null:
		return
	var popup_size := popup.size
	var anchor_position := anchor_unit.global_position
	# Convert the world (canvas) position to screen/gui coordinates using the viewport's canvas transform
	var screen_position := get_viewport().get_canvas_transform() * anchor_position
	popup.position = Vector2(screen_position.x + 32, screen_position.y - popup_size.y / 2)
	popup.popup()

func can_undo_last_action() -> bool:
	return last_action_piece != null and last_action_piece.is_inside_tree() and last_action_from != last_action_to and last_action_piece.grid_pos == last_action_to and last_action_piece.team == current_turn

func undo_last_action() -> void:
	if not can_undo_last_action():
		return
	var piece := last_action_piece
	if piece == null or piece.grid_pos != last_action_to:
		return
	# If the most recent action is still pending for this turn, drop it from the pending list
	var was_pending := false
	if pending_history_actions.size() > 0:
		var last_pending = pending_history_actions.back()
		if last_pending.has("unit") and last_pending["unit"] == piece and last_pending["to"] == last_action_to:
			pending_history_actions.pop_back()
			was_pending = true
	# Revert the piece position
	occupied_cells.erase(piece.grid_pos)
	occupied_cells[last_action_from] = piece
	piece.grid_pos = last_action_from
	piece.position = chess_board.map_to_local(last_action_from)
	piece.has_moved = last_action_has_moved
	last_move_from = Vector2i.ZERO
	last_move_to = Vector2i.ZERO
	last_move_piece = null
	last_action_piece = null
	last_action_from = Vector2i.ZERO
	last_action_to = Vector2i.ZERO
	last_action_turn = 0
	last_action_has_moved = false
	if not was_pending:
		# If it was already recorded, notify the history UI to remove the last recorded entry
		SignalBus.move_history_undone.emit()
	post_move_unit = null
	pending_attack_unit = null
	pending_attack_targets.clear()
	selected_unit = null
	clear_highlights()
	board_state = BoardState.IDLE

func show_tooltip_for_unit(unit: Unit) -> void:
	if unit == null or not unit.is_inside_tree() or self._tooltip == null:
		return
	if get_unit_at(unit.grid_pos) != unit:
		return
	var health_comp := unit.get_health_component()
	var atk_comp := unit.get_attack_component()
	var hp_text := "N/A"
	var atk_text := "N/A"
	if health_comp != null:
		hp_text = str(health_comp.get_current_health())
	if atk_comp != null:
		atk_text = str(atk_comp.get_damage_amount())
	var text := "%s\nHP: %s  ATK: %s" % [unit.get_piece_name(), hp_text, atk_text]
	var screen_position := get_viewport().get_canvas_transform() * unit.global_position
	var offset := Vector2(25, -25)
	self._tooltip.show_tooltip(text, screen_position + offset)

func hide_tooltip() -> void:
	if self._tooltip != null:
		self._tooltip.hide_tooltip()

func _remove_existing_action_popups() -> void:
	var root := get_tree().get_root()
	for child in root.get_children():
		if child is ActionPopup:
			child.queue_free()

func get_attackable_enemies(unit: Unit) -> Array[Unit]:
	var enemies: Array[Unit] = []
	if unit == null:
		return enemies
	for enemy in units.get_children():
		if not (enemy is Unit):
			continue
		if enemy.team == unit.team:
			continue
		if unit.can_attack_target(enemy):
			enemies.append(enemy)
	return enemies

func _on_selection_move() -> void:
	if selected_unit == null:
		board_state = BoardState.IDLE
		clear_highlights()
		return
	board_state = BoardState.SELECTING
	var moves := get_non_attack_moves(selected_unit)
	if moves.is_empty():
		selected_unit = null
		clear_highlights()
		board_state = BoardState.IDLE
		return
	highlight_cells(moves)

func _on_selection_attack() -> void:
	if selected_unit == null:
		board_state = BoardState.IDLE
		return
	var enemy_list := get_attackable_enemies(selected_unit)
	if enemy_list.is_empty():
		board_state = BoardState.IDLE
		return
	pending_attack_unit = selected_unit
	pending_attack_targets.clear()
	for enemy in enemy_list:
		pending_attack_targets.append(enemy.grid_pos)
	board_state = BoardState.AWAITING_ATTACK_TARGET
	var attack_targets := selected_unit.get_attack_targets(self)
	if attack_targets.is_empty():
		attack_targets = pending_attack_targets
	highlight_cells(attack_targets, true)

func get_non_attack_moves(unit: Unit) -> Array[Vector2i]:
	if unit == null:
		return []
	if unit.piece_type.to_lower() == "pawn":
		return get_pawn_forward_moves(unit)
	return get_empty_moves(unit)

func get_empty_moves(unit: Unit) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for destination in unit.get_valid_moves(self):
		if not is_cell_occupied(destination):
			moves.append(destination)
	return moves

func get_pawn_forward_moves(unit: Unit) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	if unit == null:
		return moves
	var direction := -1 if unit.team == 0 else 1
	var one_step := unit.grid_pos + Vector2i(0, direction)
	if is_within_bounds(one_step) and not is_cell_occupied(one_step):
		moves.append(one_step)
		var start_row := 6 if unit.team == 0 else 1
		var two_step := unit.grid_pos + Vector2i(0, direction * 2)
		if unit.grid_pos.y == start_row and is_within_bounds(two_step) and not is_cell_occupied(two_step):
			moves.append(two_step)
	return moves

func _on_action_wait() -> void:
	# Emit each pending per-turn action into the history when the player confirms their turn
	for action in pending_history_actions:
		if action.has("unit"):
			SignalBus.turn_wait_confirmed.emit(action["unit"], action["from"], action["to"])
	pending_history_actions.clear()
	board_state = BoardState.IDLE
	check_game_state()
	check_victory_conditions()

func _on_action_undo() -> void:
	undo_last_action()

func show_battle_overlay(attacker: Unit, defender: Unit) -> void:
	if attacker == null or defender == null:
		return
	pending_battle_attacker = attacker
	pending_battle_defender = defender
	pending_attack_unit = null
	pending_attack_targets.clear()
	clear_highlights()
	board_state = BoardState.COMBAT
	var battle_scene = Battle_Scene.instantiate()
	battle_scene.set_battle_units(attacker, defender)
	battle_scene.battle_resolved.connect(_on_battle_resolved)
	add_child(battle_scene)

	# Record the attack as a pending per-turn action. It will be emitted when the player confirms (Wait)
	pending_history_actions.append({"unit": attacker, "from": attacker.grid_pos, "to": defender.grid_pos, "type": "attack"})

func _on_battle_resolved(result: String) -> void:
	handle_combat_result(pending_battle_attacker, pending_battle_defender, result)
	# When a battle finishes and the attacker is the current player, ensure any pending actions
	# (including this attack) are recorded — if this ends the turn without an explicit Wait.
	if pending_battle_attacker != null and pending_battle_attacker.team == current_turn:
		# Ensure the attack action is present (it should already have been appended in show_battle_overlay)
		# Emit all pending actions as the turn is effectively ending
		for action in pending_history_actions:
			if action.has("unit"):
				SignalBus.turn_wait_confirmed.emit(action["unit"], action["from"], action["to"])
		pending_history_actions.clear()
	pending_battle_attacker = null
	pending_battle_defender = null
	post_move_unit = null
	board_state = BoardState.IDLE
	check_game_state()
	check_victory_conditions()

func _on_action_attack() -> void:
	if post_move_unit == null:
		board_state = BoardState.IDLE
		return
	var enemy_list := []
	for enemy in units.get_children():
		if not (enemy is Unit):
			continue
		if enemy.team == post_move_unit.team:
			continue
		if post_move_unit.can_attack_target(enemy):
			enemy_list.append(enemy)
	if enemy_list.is_empty():
		board_state = BoardState.IDLE
		check_game_state()
		return
	pending_attack_unit = post_move_unit
	pending_attack_targets.clear()
	for enemy in enemy_list:
		pending_attack_targets.append(enemy.grid_pos)
	board_state = BoardState.AWAITING_ATTACK_TARGET
	var attack_targets := post_move_unit.get_attack_targets(self)
	if attack_targets.is_empty():
		attack_targets = pending_attack_targets
	highlight_cells(attack_targets, true)

func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)

func update_king_check_visuals() -> void:
	for unit in units.get_children():
		if not (unit is Unit):
			continue
		if unit.piece_type.to_lower() != "king":
			continue
		unit.update_check_visual(is_king_in_check(unit.team))

# Check if a specific cell is under attack by any piece of the given team
func is_cell_attacked_by_team(cell: Vector2i, attacking_team: int) -> bool:
	for unit in units.get_children():
		if not (unit is Unit):
			continue
		if unit.team != attacking_team:
			continue
		if can_piece_attack_cell(unit, cell):
			return true
	return false

# Check if a piece can attack a specific cell using its attack pattern
func can_piece_attack_cell(piece: Unit, target_cell: Vector2i) -> bool:
	if piece == null:
		return false
	return piece.can_attack_cell(target_cell)

# Check if the king of a specific team is in check
func is_king_in_check(team: int) -> bool:
	var enemy_team := 1 - team
	for unit in units.get_children():
		if not (unit is Unit) or unit.piece_type.to_lower() != "king" or unit.team != team:
			continue
		return is_cell_attacked_by_team(unit.grid_pos, enemy_team)
	return false

# Check if a move would leave the king in check
func would_move_leave_king_in_check(piece: Unit, destination: Vector2i) -> bool:
	var original_pos := piece.grid_pos
	var captured_piece := get_unit_at(destination)
	var captured_original_pos := Vector2i.ZERO
	
	# Simulate the move
	occupied_cells.erase(original_pos)
	if captured_piece:
		captured_original_pos = captured_piece.grid_pos
		occupied_cells.erase(destination)
		captured_piece.grid_pos = Vector2i(-1, -1)
	
	occupied_cells[destination] = piece
	piece.grid_pos = destination
	
	# Check if king is now in check
	var in_check := is_king_in_check(piece.team)
	
	piece.grid_pos = original_pos
	
	# Undo the simulation
	occupied_cells.erase(destination)
	occupied_cells[original_pos] = piece
	if captured_piece:
		occupied_cells[destination] = captured_piece
		captured_piece.grid_pos = captured_original_pos
	
	return in_check

func begin_royal_assignment() -> void:
	royal_assignment_active = true
	current_turn = 0
	board_state = BoardState.AWAITING_ROYAL_ASSIGNMENT
	# Restrict input so only the active player's pieces may be clicked for assignment
	set_assignment_interaction(current_turn)
	show_assignment_overlay()

func assign_monarch_for_current_player(unit: Unit) -> void:
	if unit == null or not royal_assignment_active:
		return
	if unit.team != current_turn:
		return
	var player := get_player(unit.team)
	if player == null:
		return
	player.assign_royal_unit(unit)
	if current_turn == 0:
		current_turn = 1
		# update which units are interactive for the next player
		set_assignment_interaction(current_turn)
	else:
		royal_assignment_active = false
		current_turn = 0
		board_state = BoardState.IDLE
		finalize_royal_assignment()
		# restore full unit interaction now that assignment is complete
		set_assignment_interaction(-1)
	clear_highlights()

func finalize_royal_assignment() -> void:
	for player in players:
		if player == null:
			continue
		if player.has_active_royalty():
			continue
		var fallback_unit: Unit = null
		for unit in units.get_children():
			if not (unit is Unit):
				continue
			if unit.team != player.team:
				continue
			fallback_unit = unit
			break
		if fallback_unit != null:
			player.assign_royal_unit(fallback_unit)
	# Ensure all pieces are interactable again
	set_assignment_interaction(-1)
	royal_assignment_active = false
	board_state = BoardState.IDLE
	clear_highlights()
	hide_assignment_overlay()
	update_king_check_visuals()
	current_turn = 0


func show_assignment_overlay() -> void:
	if assignment_overlay_layer != null and is_instance_valid(assignment_overlay_layer):
		return
	assignment_overlay_layer = CanvasLayer.new()
	assignment_overlay_layer.layer = 100
	get_tree().get_root().call_deferred("add_child", assignment_overlay_layer)
	assignment_overlay_rect = ColorRect.new()
	assignment_overlay_rect.color = Color(0, 0, 0, 0.45)
	assignment_overlay_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	assignment_overlay_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	assignment_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Make it full-screen
	assignment_overlay_rect.size = get_viewport().get_visible_rect().size
	assignment_overlay_layer.add_child(assignment_overlay_rect)

func hide_assignment_overlay() -> void:
	if assignment_overlay_layer != null and is_instance_valid(assignment_overlay_layer):
		assignment_overlay_layer.queue_free()
		assignment_overlay_layer = null
		assignment_overlay_rect = null

func show_assignment_highlight(unit: Unit) -> void:
	if unit == null:
		return
	# Clear previous
	clear_assignment_highlight()
	hovered_assignment_unit = unit
	# Apply a bright modulate and slight scale to simulate a shine
	if unit.sprite_node != null:
		unit._original_modulate = unit.sprite_node.modulate
		unit.sprite_node.modulate = Color(1.25, 1.25, 0.9, 1)
		unit.sprite_node.scale = unit.sprite_node.scale * 1.08

func clear_assignment_highlight() -> void:
	if hovered_assignment_unit == null:
		return
	var u := hovered_assignment_unit
	hovered_assignment_unit = null
	if u != null and u.sprite_node != null:
		# restore
		u.sprite_node.modulate = u._original_modulate
		u.sprite_node.scale = u._original_scale
	

func set_assignment_interaction(team: int) -> void:
	# team == -1 -> enable all units; otherwise only enable units for the given team
	for u in units.get_children():
		if not (u is Unit):
			continue
		var unit := u as Unit
		var enable := false
		if team == -1:
			enable = true
		else:
			enable = unit.team == team
		# Allow hovering for all units during assignment, but only allow clicking/selection for the active team
		unit.input_pickable = enable
		if unit.hover_area != null:
			unit.hover_area.input_pickable = true

func assign_royal_units() -> void:
	finalize_royal_assignment()

func get_player(team: int) -> Player:
	if team < 0 or team >= players.size():
		return null
	return players[team]

func can_claim_throne(team: int) -> bool:
	if throne_manager == null:
		return false
	var enemy_team := 1 - team
	var throne_cell := throne_manager.get_throne(enemy_team)
	if throne_cell == Vector2i(-1, -1):
		return false
	var occupying_unit := get_unit_at(throne_cell)
	if occupying_unit == null or occupying_unit.team != team:
		return false
	var enemy_player := get_player(enemy_team)
	if enemy_player == null:
		return false
	return enemy_player.royal_defeated and occupying_unit != null and occupying_unit.team == team

func check_victory_conditions() -> void:
	if game_over:
		return
	for team in [0, 1]:
		if can_claim_throne(team):
			end_game(team)
			return

func handle_combat_result(attacker: Unit, defender: Unit, result: String) -> void:
	if attacker == null or defender == null:
		return
	if not defender.is_alive() and attacker != null:
		SignalBus.piece_defeated.emit(defender, attacker)
	elif not attacker.is_alive() and defender != null:
		SignalBus.piece_defeated.emit(attacker, defender)

func end_game(winning_team: int) -> void:
	if game_over:
		return
	game_over = true
	board_state = BoardState.COMBAT
	deselect()
	clear_highlights()
	SignalBus.game_over.emit(winning_team)

# Check if the king is in checkmate
func is_king_in_checkmate(team: int) -> bool:
	if not is_king_in_check(team):
		return false
	
	# King is in check; check if there are any valid moves
	for unit in units.get_children():
		if not (unit is Unit) or unit.team != team:
			continue
		var valid_moves : Array[Vector2i] = unit.get_valid_moves(self)
		if valid_moves.size() > 0:
			return false
	
	return true

# Check if the team is in stalemate
func is_team_in_stalemate(team: int) -> bool:
	if is_king_in_check(team):
		return false
	
	for unit in units.get_children():
		if not (unit is Unit) or unit.team != team:
			continue
		var valid_moves : Array[Vector2i] = unit.get_valid_moves(self)
		if valid_moves.size() > 0:
			return false
	
	return true

# Check game state after a move or combat action.
func check_game_state() -> void:
	if game_over:
		return
	var opponent_team := 1 - current_turn
	update_king_check_visuals()
	current_turn = opponent_team
