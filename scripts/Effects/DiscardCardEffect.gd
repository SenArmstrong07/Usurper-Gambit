extends BaseEffect
class_name DiscardCardEffect

@export var amount: int = 2

func execute(context: EffectContext):
	for i in amount:
		context.target_player.discard_at_random(i)
