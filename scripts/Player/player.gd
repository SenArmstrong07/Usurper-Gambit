extends RefCounted
class_name Player

signal card_drawn(card: Card)
signal hand_changed

var team: int = 0

var royal_unit: Unit = null
var royal_assigned: bool = false
var royal_defeated: bool = false

var deck: Deck = null
var hand: Array[Card] = []

var mana: int = 0



func _init(team_id: int = 0) -> void:
	team = team_id
	initialize_deck()

func _create_default_deck_resource() -> DeckResource:
	var resource := DeckResource.new()
	resource.deck_name = "Starter Deck"
	resource.starting_cards = [
		load("res://scripts/Card/PromotionCard.tres") as Card,
		load("res://scripts/Card/PromotionCard.tres") as Card,
		load("res://scripts/Card/PromotionCard.tres") as Card]
	return resource

func initialize_deck(deck_node: Deck = null, resource: DeckResource = null) -> void:
	if deck_node != null:
		deck = deck_node
	elif deck == null:
		deck = Deck.new()

	if resource == null:
		resource = _create_default_deck_resource()

	if deck != null:
		deck.initialize(resource)

func get_royal_unit() -> Unit:
	return royal_unit

func has_active_royalty() -> bool:
	return royal_unit != null and is_instance_valid(royal_unit) and royal_unit.is_royal and not royal_defeated

func assign_royal_unit(unit: Unit) -> void:
	royal_unit = unit
	royal_assigned = true
	royal_defeated = false
	if unit != null:
		unit.assign_royalty()

func clear_royal_unit() -> void:
	royal_unit = null
	royal_assigned = false
	royal_defeated = false

func mark_royal_defeated() -> void:
	royal_defeated = true
	
func draw_card() -> Card:
	if deck == null:
		initialize_deck()

	var card := deck.draw()
	if card != null:
		hand.append(card)
		card_drawn.emit(card)
		#hand_changed.emit()
	return card

func discard_card(card: Card) -> void:
	if card == null:
		return

	if hand.has(card):
		hand.erase(card)
		if deck != null:
			deck.discard(card)
		hand_changed.emit()
