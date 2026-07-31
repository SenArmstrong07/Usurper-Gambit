extends RefCounted
class_name Deck

var draw_pile : Array[Card] = []
var discard_pile : Array[Card] = []

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func shuffle():
	draw_pile.shuffle()

func initialize(resource : DeckResource):
	draw_pile = resource.starting_cards.duplicate()
	shuffle()

func draw() -> Card:
	if draw_pile.is_empty():
		reshuffle()

	if draw_pile.is_empty():
		return null

	return draw_pile.pop_back()
	
func discard(card : Card):
	discard_pile.append(card)
	
func reshuffle():
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile.shuffle()
