extends Unit
class_name Queen

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	
#STRAIGHT+DIAGONALS
func get_valid_moves(board: Board) -> Array[Vector2i]:
	var directions : Array[Vector2i] = [
		Vector2i(0,1),
		Vector2i(0,-1),
		Vector2i(1,0),
		Vector2i(-1,0),
		Vector2i(1,1),
		Vector2i(-1,1),
		Vector2i(1,-1),
		Vector2i(-1,-1)
	]
	var moves : Array[Vector2i] = get_sliding_moves(board, directions)
	return filter_check_moves(board, moves)
