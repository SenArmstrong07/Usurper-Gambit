extends Node2D
class_name MovementComponent

var behavior: MovementBehavior = null

func _ready() -> void:
	if behavior == null:
		behavior = MovementBehavior.new()

func get_valid_moves(board: Board) -> Array[Vector2i]:
	if behavior == null:
		return []
	var unit := get_parent() as Unit
	if unit == null:
		return []
	return behavior.get_valid_moves(unit, board)

func set_movement(new_behavior: MovementBehavior) -> void:
	behavior = new_behavior

func replace_movement(new_behavior: MovementBehavior) -> void:
	behavior = new_behavior
