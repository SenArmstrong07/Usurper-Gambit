extends BaseEffect
class_name DrawCardEffect

@export var amount: int = 2
var player: Player

func can_execute(context: EffectContext) -> bool:
	if context == null:
		return false
	if context.owner_player == null:
		return false
	if amount <= 0:
		return false
	if context.owner_player.get_deck().is_empty():
		return false
	if context.owner_player.is_hand_full():
		return false
	return true


func execute(context: EffectContext):
	player = context.owner_player
	for card in amount:
		player.draw_card()
