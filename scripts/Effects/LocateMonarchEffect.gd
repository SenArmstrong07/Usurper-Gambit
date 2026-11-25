extends BaseEffect
class_name LocateMonarchEffect


func can_execute(context: EffectContext) -> bool:
	if context == null or context.board == null or context.game == null or context.owner_player == null:
		return false

	var opponent := context.board.get_player(1 - context.owner_player.team)
	if opponent == null or not opponent.has_active_royalty():
		return false

	var monarch := opponent.get_royal_unit()
	return monarch != null and context.board.get_unit_at(monarch.grid_pos) == monarch


func execute(context: EffectContext) -> void:
	if not can_execute(context):
		push_warning("LocateMonarchEffect: The opponent's monarch cannot be located.")
		return

	var opponent := context.board.get_player(1 - context.owner_player.team)
	context.game.show_monarch_location(opponent.get_royal_unit())
