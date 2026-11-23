extends BaseEffect
class_name HealEffect

@export var amount: int = 3
var health_component: HealthComponent

func can_execute(context: EffectContext) -> bool:
	if context == null:
		return false
	if context.target_unit == null:
		return false
	if amount <= 0:
		return false
	
	health_component = context.target_unit.get_health_component()
	return health_component != null

func execute(context: EffectContext):
	if context == null:
		push_error("HealEffect: cannot execute heal effect because EffectContext is null")
		return
	if context.target_unit == null:
		push_warning("HealEffect: No target unit was provided.")
		return
	health_component = context.target_unit.get_health_component()
	
	if health_component == null:
		push_warning("HealEffect: Target unit has no HealthComponent.")
		return

	if amount <= 0:
		push_warning("HealEffect: Healing amount must be greater than zero.")
		return
	health_component.heal(amount)
