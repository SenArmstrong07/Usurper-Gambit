extends Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#STRAIGHT
func get_valid_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []

	var directions = [
		Vector2i(0,1), #DOWN
		Vector2i(0,-1),#UP 
		Vector2i(1,0), #RIGHT
		Vector2i(-1,0) #LEFT
	]
	
	#for loop to check other coords that follow along the diagonals
	#if the next coord is free, append it to the available moves
	for direction in directions:
		var current = grid_pos + direction

		while board.is_inside_board(current):
			if !board.is_cell_occupied(current):
				moves.append(current)
			else:
				break

			current += direction

	return moves
