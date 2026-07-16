extends Unit
class_name King

func _ready() -> void:
	super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)

func get_valid_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var directions := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1)
	]
	for direction in directions:
		var target: Vector2i = grid_pos + direction
		if not board.is_within_bounds(target):
			continue
		var occupant := board.get_unit_at(target)
		if occupant == null or occupant.team != team:
			# Filter out moves that would leave king in check
			if not board.would_move_leave_king_in_check(self, target):
				moves.append(target)

	if not has_moved:
		for offset in [-1, 1]:
			var rook_pos := grid_pos + Vector2i(offset * 3, 0)
			var rook_target := grid_pos + Vector2i(offset * 2, 0)
			var path_clear := true
			for step in range(1, 3):
				var path_cell := grid_pos + Vector2i(offset * step, 0)
				if board.is_cell_occupied(path_cell) or not board.is_within_bounds(path_cell):
					path_clear = false
					break
			if path_clear and board.is_within_bounds(rook_pos):
				var rook := board.get_unit_at(rook_pos)
				if rook != null and rook.piece_type.to_lower() == "rook" and rook.team == team and not rook.has_moved:
					# Filter castling moves that would leave king in check
					if not board.would_move_leave_king_in_check(self, rook_target):
						moves.append(rook_target)

	return moves
