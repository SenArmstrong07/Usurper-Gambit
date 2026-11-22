extends Node2D
class_name HealthComponent

@export var MAX_HEALTH: float = 10.0
var health: float

func _ready() -> void:
	health = MAX_HEALTH

func _process(delta: float) -> void:
	pass

func take_damage(amount: float) -> bool:
	if amount <= 0:
		return false
	health -= amount
	if health <= 0:
		health = 0
		kill()
		return true
	return false

func heal(amount: float) -> void:
	health = min(MAX_HEALTH, health + amount)

func kill() -> void:
	var unit := get_parent() as Unit
	if unit != null:
		unit.die()

	
func modify_stat(modifier: ModifyStatEffect.Modifier, amount: float) -> void:
	match modifier:
		ModifyStatEffect.Modifier.ADD:
			print("+HP")
			MAX_HEALTH += amount

		ModifyStatEffect.Modifier.SUBTRACT:
			print("-HP")
			MAX_HEALTH -= amount

		ModifyStatEffect.Modifier.MULTIPLY:
			print("*HP")
			MAX_HEALTH *= amount

func revive() -> void:
	health = MAX_HEALTH

func is_alive() -> bool:
	return health > 0

func get_current_health() -> float:
	return health
