extends Resource
class_name Card

@export var card_name: String = "Card"
@export var description: String = ""
@export var mana_cost: int = 0
@export var card_theme: CardTheme
@export var play_conditions: Array[String] = []
@export var effects: Array[BaseEffect] = []
enum TargetType
{
NONE,
ALLY_UNIT,
ENEMY_UNIT,
ANY_UNIT,
EMPTY_CELL,
ANY_CELL,
SELF,
ALL_ALLIES,
ALL_ENEMIES
}

@export var target_type: TargetType = TargetType.NONE

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func play(context: Dictionary = {}) -> void:
	var effect_name := _get_effect_name()
	print("A gameplay effect was executed: ", effect_name)
	SignalBus.gameplay_effect_triggered.emit(effect_name, context)

func has_play_condition(condition: String) -> bool:
	if condition == null:
		return false
	var normalized := condition.strip_edges().to_lower()
	for item in play_conditions:
		if item != null and item.strip_edges().to_lower() == normalized:
			return true
	return false

func _get_effect_name() -> String:
	if card_name == null:
		return "generic_card_effect"

	var name_lower := card_name.to_lower()
	if "promotion" in name_lower:
		return "promote_piece"
	if "action" in name_lower:
		return "move_piece"
	if "trap" in name_lower:
		return "spawn_trap"
	return "generic_card_effect"
