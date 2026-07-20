extends Node2D
class_name AtkComponent

@export var damage: int = 2
@export var minimum_range: int = 1
@export var maximum_range: int = 1
@export var pattern: String = "adjacent"
@export var needs_line_of_sight: bool = true
@export var can_hit_allies: bool = false
@export var can_hit_self: bool = false

@export var ATTACK_DMG: int = 2
@export var ATTACK_RANGE: int = 1
var current_atk: int

func _ready() -> void:
	if damage == 2 and ATTACK_DMG != 2:
		damage = ATTACK_DMG
	if maximum_range == 1 and ATTACK_RANGE != 1:
		maximum_range = ATTACK_RANGE
	current_atk = damage

func _process(delta: float) -> void:
	pass

func get_damage_amount() -> int:
	return damage

func can_attack(target: Unit) -> bool:
	return target != null and target.is_alive()

func get_pattern_name() -> String:
	return pattern.to_lower()

func get_minimum_range() -> int:
	return max(0, minimum_range)

func get_maximum_range() -> int:
	return max(get_minimum_range(), maximum_range)
