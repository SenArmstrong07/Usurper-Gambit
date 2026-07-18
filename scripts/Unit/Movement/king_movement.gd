extends MovementBehavior
class_name KingMovement

func get_valid_moves(unit: Unit, board: Board) -> Array[Vector2i]:
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
		var target: Vector2i = unit.grid_pos + direction
		if not board.is_within_bounds(target):
			continue
		var occupant := board.get_unit_at(target)
		if occupant == null or occupant.team != unit.team:
			if not board.would_move_leave_king_in_check(unit, target):
				moves.append(target)

	if not unit.has_moved:
		for offset in [-1, 1]:
			var rook_target := unit.grid_pos + Vector2i(offset * 2, 0)
			if board.is_castling_move_legal(unit, rook_target):
				moves.append(rook_target)

	return moves
