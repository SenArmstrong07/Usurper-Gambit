extends Node2D
class_name Board

const BOARD_SIZE = 8
var occupied_cells: Dictionary[Vector2i, Unit] = {}
var selected_unit: Unit = null
var dragging_unit: Unit = null
var current_turn: int = 0
var last_move_from: Vector2i = Vector2i.ZERO
var last_move_to: Vector2i = Vector2i.ZERO
var last_move_piece: Unit = null

@onready var units: Node2D = $Units
@onready var chess_board: TileMapLayer = $chessBoard
@onready var highlight_markers: Node2D = $HighlightMarkers
const HighlightScene = preload("res://scenes/UI/HighlightCells.tscn")
var highlighted_cells: Array

enum BoardState {
	IDLE,
	SELECTING,
	MOVING,
	COMBAT
}

var board_state = BoardState.IDLE

func _ready() -> void:
	add_to_group("Board")
	highlight_markers.visible = false
	
	print(chess_board.get_used_rect())
	print("Tile size:", chess_board.tile_set.tile_size)
	print("map_to_local(0,0):", chess_board.map_to_local(Vector2i(0,0)))
	print("map_to_local(1,0):", chess_board.map_to_local(Vector2i(1,0)))
	print("Board scale:", scale)
	print("TileMap scale:", chess_board.scale)
	print("Units scale:", units.scale)
	SignalBus.unit_dropped.connect(_on_unit_dropped)
	#SignalBus.cell_selected.connect(highlight_cells)
	clear_highlights()

func _process(delta: float) -> void:
	#queue_redraw()
	pass

# func _draw():
# 	draw_rect(Rect2(Vector2.ZERO, Vector2(128,128)), Color.RED, false)

#Mouse Handlers
func _input(event: InputEvent) -> void:
	if board_state == BoardState.COMBAT:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse_pos := chess_board.get_local_mouse_position()
		var clicked_cell := chess_board.local_to_map(local_mouse_pos)
		handle_click(clicked_cell)
		print("Selected Cell: ", clicked_cell)

func handle_click(cell: Vector2i) -> void:
	var unit := get_unit_at(cell)
	if unit != null and unit.team == current_turn:
		select_unit(unit)
		return

	if selected_unit != null:
		if can_move_to(selected_unit, cell):
			move_unit(selected_unit, cell)
			selected_unit = null
			clear_highlights()
		else:
			deselect()

func select_unit(unit: Unit) -> void:
	if unit.team != current_turn:
		return
	selected_unit = unit
	var moves := unit.get_valid_moves(self)
	highlight_cells(moves)
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
	if unit == null:
		return
	if unit.team != current_turn:
		unit.position = chess_board.map_to_local(unit.grid_pos)
		deselect()
		return
	if can_move_to(unit, cell):
		move_unit(unit, cell)
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
func highlight_cells(cells: Array[Vector2i]) -> void:
	clear_highlights()
	for cell in cells:
		var marker = HighlightScene.instantiate()
		marker.position = chess_board.map_to_local(cell)
		#var world_pos := chess_board.to_global(chess_board.map_to_local(cell))
		highlight_markers.add_child(marker)
		highlighted_cells.append(marker)
	highlight_markers.visible = true

func setup_initial_pieces() -> void:
	clear_board()
	for x in range(BOARD_SIZE):
		spawn_piece("pawn", 0, Vector2i(x, 6))
		spawn_piece("pawn", 1, Vector2i(x, 1))

	var white_back_rank := ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
	var black_back_rank := ["rook", "knight", "bishop", "king", "queen", "bishop", "knight", "rook"]
	for index in range(BOARD_SIZE):
		spawn_piece(white_back_rank[index], 0, Vector2i(index, 7))
		spawn_piece(black_back_rank[index], 1, Vector2i(index, 0))

func clear_board() -> void:
	for child in units.get_children():
		if child is Unit:
			child.queue_free()
	occupied_cells.clear()
	selected_unit = null
	dragging_unit = null
	clear_highlights()

func spawn_piece(piece_type: String, team: int, grid_pos: Vector2i) -> Unit:
	var scene_path := "res://scenes/Unit/Unit.tscn"
	if piece_type.to_lower() == "king":
		scene_path = "res://scenes/Unit/king.tscn"
	var unit_scene: PackedScene = load(scene_path)
	var unit := unit_scene.instantiate() as Unit
	place_piece(unit, piece_type, team, grid_pos)
	print("Board global:", global_position)
	print("TileMap global:", chess_board.global_position)
	print("Units global:", units.global_position)
	print("Unit global:", unit.global_position)
	print("Sprite global:", unit.sprite_node.global_position)
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

func move_unit(unit: Unit, destination: Vector2i) -> void:
	if not is_within_bounds(destination):
		return

	var start_pos := unit.grid_pos
	var captured_piece: Unit = null
	var rook_to_move: Unit = null
	var rook_from: Vector2i = Vector2i.ZERO
	var rook_to: Vector2i = Vector2i.ZERO
	var en_passant_capture := false
	var piece_name := unit.piece_type.to_lower()

	if piece_name == "pawn":
		var direction := -1 if unit.team == 0 else 1
		var one_step := start_pos + Vector2i(0, direction)
		var two_step := start_pos + Vector2i(0, direction * 2)
		var left_capture := start_pos + Vector2i(-1, direction)
		var right_capture := start_pos + Vector2i(1, direction)

		if destination == one_step:
			if get_unit_at(destination) != null:
				return
		elif destination == two_step:
			if get_unit_at(one_step) != null or get_unit_at(destination) != null:
				return
		elif destination == left_capture or destination == right_capture:
			var target := get_unit_at(destination)
			if target != null and target.team != unit.team:
				captured_piece = target
			elif target == null and last_move_piece != null and last_move_piece.piece_type.to_lower() == "pawn" and abs(last_move_from.y - last_move_to.y) == 2 and last_move_to.y == start_pos.y and last_move_to.x == start_pos.x + (1 if destination.x > start_pos.x else -1):
				captured_piece = last_move_piece
				en_passant_capture = true
			else:
				return
		else:
			return
	elif piece_name == "king" and abs(destination.x - start_pos.x) == 2 and start_pos.y == destination.y:
		var rook_direction := -1 if destination.x < start_pos.x else 1
		rook_from = start_pos + Vector2i(rook_direction * 3, 0)
		rook_to = start_pos + Vector2i(rook_direction * 1, 0)
		rook_to_move = get_unit_at(rook_from)
		var path_clear := true
		for step in range(1, 3):
			var path_cell := start_pos + Vector2i(rook_direction * step, 0)
			if not is_within_bounds(path_cell) or is_cell_occupied(path_cell):
				path_clear = false
				break
		if not path_clear or rook_to_move == null or rook_to_move.piece_type.to_lower() != "rook" or rook_to_move.team != unit.team or rook_to_move.has_moved or unit.has_moved:
			return

	# Handle captures for any piece (non-pawn pieces like queen, rook, bishop, knight)
	if captured_piece == null:
		var target_at_destination := get_unit_at(destination)
		if target_at_destination != null and target_at_destination.team != unit.team:
			captured_piece = target_at_destination

	occupied_cells.erase(start_pos)
	if captured_piece != null:
		remove_unit(captured_piece)
	if en_passant_capture:
		occupied_cells.erase(last_move_to)
		remove_unit(captured_piece)
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

	if piece_name == "pawn" and (destination.y == 0 or destination.y == 7):
		unit.piece_type = "queen"
		unit.apply_sprite()
		print("Unit position:", position)
		print("Sprite position:", unit.sprite_node.position)
		print("Sprite offset:", unit.sprite_node.offset)
		print("Centered:", unit.sprite_node.centered)

	last_move_from = start_pos
	last_move_to = destination
	last_move_piece = unit

	SignalBus.unit_moved.emit(unit, start_pos, destination)

func remove_unit(unit: Unit) -> void:
	if unit == null:
		return
	occupied_cells.erase(unit.grid_pos)
	if unit.is_inside_tree():
		units.remove_child(unit)
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

func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)
