extends Node2D
class_name AtkComponent

@export var ATTACK_DMG: int = 2
@export var ATTACK_RANGE: int = 1
var current_atk: int

func _ready() -> void:
	current_atk = ATTACK_DMG

func _process(delta: float) -> void:
	pass

func get_damage_amount() -> int:
	return current_atk

func can_attack(target: Unit) -> bool:
	return target != null and target.is_alive()
