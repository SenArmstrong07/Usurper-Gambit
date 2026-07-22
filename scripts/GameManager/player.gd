extends RefCounted
class_name Player

var team: int = 0
var royal_unit: Unit = null
var royal_assigned: bool = false
var royal_defeated: bool = false

func _init(team_id: int = 0) -> void:
	team = team_id

func get_royal_unit() -> Unit:
	return royal_unit

func has_active_royalty() -> bool:
	return royal_unit != null and is_instance_valid(royal_unit) and royal_unit.is_royal and not royal_defeated

func assign_royal_unit(unit: Unit) -> void:
	royal_unit = unit
	royal_assigned = true
	royal_defeated = false
	if unit != null:
		unit.assign_royalty()

func clear_royal_unit() -> void:
	royal_unit = null
	royal_assigned = false
	royal_defeated = false

func mark_royal_defeated() -> void:
	royal_defeated = true
