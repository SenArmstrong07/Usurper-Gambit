extends BaseEffect
class_name HealEffect

@export var amount: int = 3

func execute(context: EffectContext):
	if context.target_unit == null:
		return
	context.target_unit.get_health_component().heal(amount)
