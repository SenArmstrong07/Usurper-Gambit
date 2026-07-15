extends Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func get_valid_moves(board: Board) -> Array[Vector2i]:
	return [
		#DIFF IN X
		grid_pos + Vector2i(1, 2),
		grid_pos + Vector2i(2, 1),
		grid_pos + Vector2i(-1, 2),
		grid_pos + Vector2i(-2, 1),
		#DIFF IN Y
		grid_pos + Vector2i(1, -2),
		grid_pos + Vector2i(2, -1),
		grid_pos + Vector2i(-1, -2),
		grid_pos + Vector2i(-2, -1),
	]
