extends Unit
class_name Bishop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)

#DIAGONALS
func get_valid_moves(board: Board) -> Array[Vector2i]:
	var directions : Array[Vector2i] = [
		Vector2i(1,1),
		Vector2i(-1,1),
		Vector2i(1,-1),
		Vector2i(-1,-1)
	]
	var moves : Array[Vector2i] = get_sliding_moves(board, directions)
	return filter_check_moves(board, moves)
