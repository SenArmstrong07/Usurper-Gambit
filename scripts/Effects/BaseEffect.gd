extends Resource
class_name BaseEffect


func can_execute(context: EffectContext) -> bool:
	return context != null


func execute(context: EffectContext):
	pass
