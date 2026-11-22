extends Node
class_name CardEffectManager

var active_card: Card
var active_context: EffectContext
var is_targeting: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func request_play(card: Card) -> void:
	if card == null:
		return

	active_card = card

	if card.target_type == Card.TargetType.NONE:
		_execute_card_without_target()
	else:
		_begin_targeting(card)
		
		
func _execute_card_without_target():
	pass
	
func _begin_targeting(card: Card):
	pass
