extends BaseEffect
class_name DamageEffect

@export var damage : int = 2
var health_component: HealthComponent

func can_execute(context: EffectContext) -> bool:
	if context == null:
		return false
	if context.target_unit == null:
		return false
	if damage <= 0:
		return false
	health_component = context.target_unit.get_health_component()
	return health_component != null

func execute(context: EffectContext):
	if context.target_unit == null:
		return
	health_component = context.target_unit.get_health_component()
	return health_component.take_damage(damage)
