extends BaseEffect
class_name DiscardCardEffect

@export var amount: int = 2
var player: Player
func execute(context: EffectContext):
	player = context.owner_player
	for i in amount:
		player.discard_at_random(i)
