extends Node

# Game Flow
signal battle_started
signal battle_ended
signal round_started(round)
signal round_ended(round)
signal preparation_started

# Player events
signal player_has_confirmed(cell: Vector2i)
signal cell_selected(cell: Vector2i)
signal player_has_deselected(cell: Vector2i)
signal player_defeated(player)
signal game_over(winner)

signal unit_placed(unit)
signal unit_moved(unit, from_cell, to_cell)
signal turn_wait_confirmed(unit, from_cell, to_cell)
signal move_history_undone()
signal unit_removed(unit)
signal unit_combined(unit)
signal unit_selected(unit)
signal unit_drag_started(unit)
signal unit_dragged(unit)
signal unit_dropped(unit: Unit, cell: Vector2i)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
