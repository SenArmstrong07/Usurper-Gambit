extends RefCounted
class_name MovementBehavior

func get_valid_moves(unit: Unit, board: Board) -> Array[Vector2i]:
	return []

func get_sliding_moves(unit: Unit, board: Board, directions: Array[Vector2i]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for direction in directions:
		var current := unit.grid_pos + direction
		while board.is_within_bounds(current):
			var occupant := board.get_unit_at(current)
			if occupant == null:
				moves.append(current)
			else:
				if occupant.team != unit.team:
					moves.append(current)
				break
			current += direction
	return moves

func get_knight_moves(unit: Unit, board: Board) -> Array[Vector2i]:
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
		var target: Vector2i = unit.grid_pos + offset
		if not board.is_within_bounds(target):
			continue
		var occupant := board.get_unit_at(target)
		if occupant == null or occupant.team != unit.team:
			moves.append(target)
	return moves

func filter_check_moves(unit: Unit, board: Board, moves: Array[Vector2i]) -> Array[Vector2i]:
	return unit.filter_check_moves(board, moves)
