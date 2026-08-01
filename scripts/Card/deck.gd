extends RefCounted
class_name Deck

signal deck_shuffled
signal deck_refilled

var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []

func initialize(resource: DeckResource) -> void:
	if resource == null:
		return
	draw_pile = []
	discard_pile = []
	if resource.starting_cards != null:
		draw_pile = resource.starting_cards.duplicate()
	shuffle()

func shuffle() -> void:
	if draw_pile.is_empty():
		return
	draw_pile.shuffle()
	deck_shuffled.emit()

func add_card(card: Card) -> void:
	if card == null:
		return
	draw_pile.append(card)

func remove_card(card: Card) -> void:
	if card == null:
		return
	draw_pile.erase(card)
	discard_pile.erase(card)

func is_empty() -> bool:
	return draw_pile.is_empty() and discard_pile.is_empty()

func remaining_cards() -> int:
	return draw_pile.size() + discard_pile.size()

func draw() -> Card:
	if draw_pile.is_empty():
		refill_from_discard()
	if draw_pile.is_empty():
		return null
	return draw_pile.pop_back()

func discard(card: Card) -> void:
	if card == null:
		return
	discard_pile.append(card)

func refill_from_discard() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle()
	deck_refilled.emit()
