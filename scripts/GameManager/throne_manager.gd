extends Node
class_name ThroneManager

var throne_positions: Dictionary = {}

func _ready() -> void:
	add_to_group("ThroneManager")

func register_throne(team: int, cell: Vector2i) -> void:
	throne_positions[team] = cell

func get_throne(team: int) -> Vector2i:
	if throne_positions.has(team):
		return throne_positions[team]
	return Vector2i(-1, -1)

func is_enemy_throne(cell: Vector2i, team: int) -> bool:
	var enemy_team := 1 - team
	return cell == get_throne(enemy_team)
