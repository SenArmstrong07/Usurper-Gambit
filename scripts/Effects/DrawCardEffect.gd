extends BaseEffect
class_name DrawCardEffect

@export var amount: int = 2

func execute(context: EffectContext):
	for card in amount:
		context.owner_player.draw_card()
