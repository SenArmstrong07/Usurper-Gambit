extends MovementBehavior
class_name BishopMovement

func get_valid_moves(unit: Unit, board: Board) -> Array[Vector2i]:
	var directions : Array[Vector2i] = [
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1)
	]
	var moves : Array[Vector2i] = get_sliding_moves(unit, board, directions)
	return filter_check_moves(unit, board, moves)
