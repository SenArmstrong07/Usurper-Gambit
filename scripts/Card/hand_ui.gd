extends Control
class_name HandUI

var card_res := load("res://scripts/Card/PromotionCard.tres") as Card
const card_scene = preload("res://scenes/Card/CardUI.tscn")

var cards: Array[Card] = []

@export var hand_curve: Curve
@export var rotation_curve: Curve

@export var max_rotation_degrees:= 5
@export var x_sep := 10 #separation of the cards in the x axis
@export var y_min:= 0
@export var y_max  := -15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_card() -> void:
	var new_card_ui = card_scene.instantiate() as CardUI
	$CardContainer.add_child(new_card_ui)
	new_card_ui.setup(card_res)
	print("Drew a new card!")
	_update_cards()

func discard_card() -> void:
	if $CardContainer.get_child_count() < 1:
		return
	
	var child = $CardContainer.get_child(-1)
	child.reparent(get_tree().root)
	child.queue_free()
	print("Discarded a card!")
	_update_cards()
	
func rebuild_hand() -> void:
	for child in $CardContainer.get_children():
		child.queue_free() #free all cards
		
	for card in cards:
		var ui = card_res.instantiate()
		ui.setup(card)
		$CardContainer.add_child(ui)
		
func _update_cards() -> void:
	var card_nodes := $CardContainer.get_children()
	
	var all_cards_size = CardUI.SIZE.x * card_nodes.size() + x_sep * (card_nodes.size() - 1)
	var final_x_sep := x_sep
	
	if card_nodes.size() > 1 and all_cards_size > size.x:
		var divisor : int = max(1, card_nodes.size() - 1)
		final_x_sep = (size.x - CardUI.SIZE.x * card_nodes.size()) / divisor
		all_cards_size = size.x
	
	var offset : int = (size.x - all_cards_size) / 2
	
	for c in card_nodes.size():
		var card := card_nodes[c]
		var sample_pos := 0.0
		if card_nodes.size() > 1:
			sample_pos = 1.0 / (card_nodes.size() - 1) * c
		
		var y_multiplier := hand_curve.sample(sample_pos)
		var rot_multiplier := rotation_curve.sample(sample_pos)
		
		if card_nodes.size() == 1:
			y_multiplier = 0.0
			rot_multiplier = 0.0
		
		var final_x: float = offset + CardUI.SIZE.x * c + final_x_sep * c
		var final_y: float = y_min + y_max * y_multiplier
		
		card.position = Vector2(final_x, final_y)
		card.rotation_degrees = max_rotation_degrees * rot_multiplier
