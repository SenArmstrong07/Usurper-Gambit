extends Resource
class_name Card

@export var card_name: String
@export var description: String
@export var mana_cost: int
@export var card_theme: CardTheme
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

@export var target_type: TargetType

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play(context: Dictionary = {}) -> void:
	var effect_name := _get_effect_name()
	print("A gameplay effect was executed: ", effect_name)
	SignalBus.gameplay_effect_triggered.emit(effect_name, context)

func _get_effect_name() -> String:
	if card_name == null:
		return "generic_card_effect"

	var name_lower := card_name.to_lower()
	if "promotion" in name_lower:
		return "promote_pawn"
	if "teleport" in name_lower:
		return "move_unit"
	if "trap" in name_lower:
		return "spawn_trap"
	return "generic_card_effect"
