extends Node2D
class_name Unit

# STATS
@export var max_hp: int = 100
var hp: int
@export var atk: int = 1
@export var atk_range: int = 1
@export var armor: int = 0
@export var is_captured: bool = false
@export var mana: int = 0
@export var max_mana: int = 20
@export var team: int = 0
@export var piece_type: String = "pawn"

# LOCATION STUFF
var grid_pos: Vector2i = Vector2i.ZERO
var current_target: Unit
var board: Board
var has_moved: bool = false

# UI STUFF
var is_dragging : bool = false
var input_pickable : bool = true
var drag_offset : Vector2 = Vector2.ZERO
var sprite_node: Sprite2D

func _ready() -> void:
	add_to_group("Unit")
	set_process_input(true)
	input_pickable = true
	hp = max_hp
	if sprite_node == null:
		create_sprite()

func _process(delta: float) -> void:
	update_combat(delta)
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if board != null and board.game_over:
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse_position := get_global_mouse_position()
	if mouse_event.pressed:
		if is_under_mouse(mouse_position):
			if board != null and board.dragging_unit != null and board.dragging_unit != self:
				return
			if board != null:
				board.dragging_unit = self
				board.select_unit(self)
			is_dragging = true
			drag_offset = global_position - mouse_position
			SignalBus.unit_drag_started.emit(self)
		return

	if is_dragging:
		is_dragging = false
		SignalBus.unit_dragged.emit(self)
		if board != null:
			board.dragging_unit = null
			SignalBus.unit_dropped.emit(self, board.world_to_grid(get_global_mouse_position()))
		else:
			SignalBus.unit_dropped.emit(self, grid_pos)

func update_combat(delta):
	pass

func is_under_mouse(mouse_position: Vector2) -> bool:
	var rect := Rect2(global_position - Vector2(8, 8), Vector2(16, 16))
	return rect.has_point(mouse_position)

func create_sprite() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.name = "PieceSprite"
	sprite_node.centered = true
	sprite_node.position = Vector2.ZERO
	sprite_node.scale = Vector2(0.5, 0.5)
	add_child(sprite_node)

func apply_sprite() -> void:
	if sprite_node == null:
		create_sprite()

	var normalized_type := piece_type.to_lower()
	var team_name := "white" if team == 0 else "black"
	var texture_path := "res://assets/duo/%s_%s.png" % [team_name, normalized_type]
	var texture := load(texture_path) as Texture2D
	if texture != null:
		sprite_node.texture = texture
	else:
		sprite_node.texture = load("res://assets/duo/neutral_pawn.png")
	print(sprite_node.texture.get_size())
	print(sprite_node)
	print(sprite_node.get_path())

func get_piece_name() -> String:
	return piece_type.capitalize()

func is_enemy_in_range() -> bool:
	return false

func is_valid_move() -> bool:
	return false


func get_valid_moves(board: Board) -> Array[Vector2i]:
	#var moves: Array[Vector2i] = []
	#var normalized_type := piece_type.to_lower()
#
	#match normalized_type:
		#"pawn":
			#moves = get_pawn_moves(board)
		#"rook":
			#moves = get_sliding_moves(board, [
				#Vector2i(0, 1),
				#Vector2i(0, -1),
				#Vector2i(1, 0),
				#Vector2i(-1, 0)
			#])
		#"bishop":
			#moves = get_sliding_moves(board, [
				#Vector2i(1, 1),
				#Vector2i(-1, 1),
				#Vector2i(1, -1),
				#Vector2i(-1, -1)
			#])
		#"queen":
			#moves = get_sliding_moves(board, [
				#Vector2i(0, 1),
				#Vector2i(0, -1),
				#Vector2i(1, 0),
				#Vector2i(-1, 0),
				#Vector2i(1, 1),
				#Vector2i(-1, 1),
				#Vector2i(1, -1),
				#Vector2i(-1, -1)
			#])
		#"knight":
			#moves = get_knight_moves(board)
		##"king":
			##moves = king.get_valid_moves(board)

	return []

func get_pawn_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var direction := -1 if team == 0 else 1
	var one_step := grid_pos + Vector2i(0, direction)
	var two_step := grid_pos + Vector2i(0, direction * 2)
	var start_row := 6 if team == 0 else 1

	if board.is_within_bounds(one_step) and not board.is_cell_occupied(one_step):
		moves.append(one_step)
		if grid_pos.y == start_row and board.is_within_bounds(two_step) and not board.is_cell_occupied(two_step):
			moves.append(two_step)

	for delta_x in [-1, 1]:
		var capture_cell := grid_pos + Vector2i(delta_x, direction)
		if not board.is_within_bounds(capture_cell):
			continue
		var target := board.get_unit_at(capture_cell)
		if target != null and target.team != team:
			moves.append(capture_cell)

	if board.last_move_piece != null and board.last_move_piece.piece_type.to_lower() == "pawn" and abs(board.last_move_from.y - board.last_move_to.y) == 2:
		var passant_target := grid_pos + Vector2i(board.last_move_to.x - grid_pos.x, direction)
		if abs(board.last_move_to.x - grid_pos.x) == 1 and board.last_move_to.y == grid_pos.y and destination_is_en_passant_target(board, passant_target, grid_pos, direction):
			moves.append(passant_target)

	return moves

func destination_is_en_passant_target(board: Board, cell: Vector2i, pawn_pos: Vector2i, pawn_direction: int) -> bool:
	if not board.is_within_bounds(cell):
		return false
	var target := board.get_unit_at(cell)
	return target == null and cell.x == board.last_move_to.x and cell.y == pawn_pos.y + pawn_direction

func get_sliding_moves(board: Board, directions: Array[Vector2i]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for direction in directions:
		var current := grid_pos + direction
		while board.is_within_bounds(current):
			var occupant := board.get_unit_at(current)
			if occupant == null:
				moves.append(current)
			else:
				if occupant.team != team:
					moves.append(current)
				break
			current += direction
	return moves

func get_knight_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var offsets := [
		Vector2i(1, 2),
		Vector2i(2, 1),
		Vector2i(-1, 2),
		Vector2i(-2, 1),
		Vector2i(1, -2),
		Vector2i(2, -1),
		Vector2i(-1, -2),
		Vector2i(-2, -1)
	]
	for offset in offsets:
		var target : Vector2i = grid_pos + offset
		if not board.is_within_bounds(target):
			continue
		var occupant := board.get_unit_at(target)
		if occupant == null or occupant.team != team:
			moves.append(target)
	return moves

# Filter moves that would leave the king in check
func filter_check_moves(board: Board, moves: Array[Vector2i]) -> Array[Vector2i]:
	var safe_moves: Array[Vector2i] = []
	for move in moves:
		if not board.would_move_leave_king_in_check(self, move):
			safe_moves.append(move)
	return safe_moves

func update_check_visual(is_in_check: bool) -> void:
	print(piece_type, sprite_node, is_in_check)
	if sprite_node == null:
		return
	if piece_type.to_lower() != "king":
		return
	if is_in_check:
		sprite_node.modulate = Color.RED
	else:
		sprite_node.modulate = Color.WHITE
	print(piece_type, is_in_check)

func capture():
	print("Cell Captured")

func attack():
	print("Unit used an attack")

func die():
	print("Unit has died")

func heal(amount):
	print("Unit's HP was replenished by: " + str(amount) + " points")

func find_target():
	print("Unit found target")

func move_to_target(new_pos: Vector2i):
	var pathway = board.get_pathway(self.grid_pos, current_target.grid_pos)
	print("Unit moved to target")
