extends MovementBehavior
class_name KnightMovement

func get_valid_moves(unit: Unit, board: Board) -> Array[Vector2i]:
    var moves: Array[Vector2i] = get_knight_moves(unit, board)
    return filter_check_moves(unit, board, moves)
