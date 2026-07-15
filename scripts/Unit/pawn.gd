extends Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_valid_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] =[]
	
	moves.append(grid_pos + Vector2i(0, -1))
	return moves
