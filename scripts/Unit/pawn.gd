extends Unit
class_name Pawn

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)

func get_valid_moves(board: Board) -> Array[Vector2i]:
	var moves : Array[Vector2i] = get_pawn_moves(board)
	return filter_check_moves(board, moves)
