extends BaseEffect
class_name DamageEffect

@export var damage : int = 2

func execute(context: EffectContext):
	if context.target_unit == null:
		return
		
	return context.target_unit.get_health_component().take_damage(damage)
