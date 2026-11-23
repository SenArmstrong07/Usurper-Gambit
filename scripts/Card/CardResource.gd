extends Resource
class_name Card

@export var card_name: String = "Card"
@export var description: String = ""
@export var mana_cost: int = 0
@export var card_theme: CardTheme
@export var gameplay_effect_name: String = ""
@export var play_conditions: Array[String] = []
@export var effects: Array[BaseEffect] = []
enum TargetType
{

NONE,

#UNITS
ALLY_UNIT,
ENEMY_UNIT,
ANY_UNIT,

#CELLS/QUADRANTS
EMPTY_CELL,
ANY_CELL,
ANY_QUADRANT,
SELF_QUADRANT,
ENEMY_QUADRANT,

SELF,
ALL_ALLIES,
ALL_ENEMIES
}

@export var target_type: TargetType = TargetType.NONE

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func can_execute(context: EffectContext) -> bool:
	if context == null:
		return false
	context.card = self
	if effects.is_empty():
		return false

	for effect in effects:
		if effect == null:
			push_warning("Card '%s' contains a null effect." % card_name)
			return false
		if not effect.can_execute(context):
			print("The effect '%s' cannot be executed in the current context." % effect)
			return false

	return true

func play(context: EffectContext) -> void:
	if context == null:
		push_error("EffectContext is null. Cannot play card.")
		return

	context.card = self
	var effect_name := _get_effect_name()
	print("A gameplay effect was executed: ", effect_name)
	
	for effect in effects:
		if effect == null:
			push_warning("Card '%s' contains a null effect." % card_name)
			continue
		effect.execute(context)
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
	if not gameplay_effect_name.is_empty():
		return gameplay_effect_name
	return "generic_card_effect"
