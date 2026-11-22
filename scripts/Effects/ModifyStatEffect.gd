extends BaseEffect
class_name ModifyStatEffect

@export var stat_to_mod: UnitStat = UnitStat.NONE
@export var modifier: Modifier = Modifier.NONE
@export var amount: float = 0

enum UnitStat
{
	NONE,
	ATK,
	MAX_HP,
	ARMOR
}

enum Modifier
{
	NONE,
	ADD,
	SUBTRACT,
	MULTIPLY
}

func execute(context: EffectContext):
	if context.target_unit == null:
		return
	
	match stat_to_mod:
		UnitStat.ATK:
			var atk_component := context.target_unit.get_attack_component()
			if atk_component == null:
				return
			atk_component.modify_stat(modifier, amount)
		UnitStat.MAX_HP:
			var health_component := context.target_unit.get_health_component()
			if health_component == null:
				return
			health_component.modify_stat(modifier, amount)
