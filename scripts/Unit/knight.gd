extends Unit
class_name Knight

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	
func get_valid_moves(board: Board) -> Array[Vector2i]:
	var moves : Array[Vector2i] = get_knight_moves(board)
	return filter_check_moves(board, moves)
