extends Node2D
class_name AtkComponent

@export var ATTACK_DMG: int
@export var ATTACK_RANGE: int = 1
var current_atk: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_atk = ATTACK_DMG


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
