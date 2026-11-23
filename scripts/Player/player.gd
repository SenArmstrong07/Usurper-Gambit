extends RefCounted
class_name Player

signal card_drawn(card: Card)
signal card_discarded(card: Card)
signal hand_changed
signal deck_shuffled

var team: int = 0

var royal_unit: Unit = null
var royal_assigned: bool = false
var royal_defeated: bool = false

var deck: Deck = null
var hand: Array[Card] = []

var mana: int = 0
var current_mana: int = 0
var max_mana: int = 0
var hand_size_limit: int = 5
var opening_hand_size: int = 5
var suppress_hand_changed: bool = false

func _init(team_id: int = 0) -> void:
	team = team_id
	initialize_mana()
	initialize_deck()

func initialize_mana() -> void:
	current_mana = 10
	max_mana = 10
	mana = current_mana

func _create_default_deck_resource() -> DeckResource:
	var starter_path := "res://scripts/Card/StarterDeck.tres"
	if ResourceLoader.exists(starter_path):
		var resource := load(starter_path) as DeckResource
		if resource != null:
			return resource

	var resource := DeckResource.new()
	resource.deck_name = "Starter Deck"
	resource.opening_hand_size = 5
	resource.starting_cards = []
	var card_resource := load("res://scripts/Card/HealCard.tres") as Card
	if card_resource != null:
		for i in range(opening_hand_size):
			resource.starting_cards.append(card_resource)
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
		opening_hand_size = resource.opening_hand_size if resource.opening_hand_size > 0 else 5

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
		
	if not can_draw_card():
		print("Hand is full!")
		return
		
	if deck.is_empty():
		print("No cards left in deck!")
		return

	var card := deck.draw()
	if card != null:
		if hand.size() < hand_size_limit:
			hand.append(card)
			card_drawn.emit(card)
			if not suppress_hand_changed:
				hand_changed.emit()
		else:
			deck.discard(card)
	return card

func draw_opening_hand() -> void:
	for i in range(opening_hand_size):
		if is_hand_full():
			break
		draw_card()

func can_draw_card() -> bool:
	return hand.size() < hand_size_limit

func is_hand_full() -> bool:
	return hand.size() >= hand_size_limit

func discard_card(card: Card) -> void:
	if card == null:
		return

	if hand.has(card):
		hand.erase(card)
		if deck != null:
			deck.discard(card)
		card_discarded.emit(card)
		hand_changed.emit()

#Helper to discard cards based off of the amount instead of the card itself
func discard_at_random(amount: int) -> void:
	for i in range(min(amount, hand.size())):
		var random_card_idx := randi_range(0, hand.size() - 1)
		discard_card(hand[random_card_idx])

func shuffle_deck() -> void:
	if deck == null:
		initialize_deck()
	deck.shuffle()
	deck_shuffled.emit()

func begin_turn() -> void:
	max_mana = min(max_mana + 1, 10)
	current_mana = max_mana
	mana = current_mana
	draw_card()

func spend_mana(cost: int) -> bool:
	if cost <= 0:
		return true
	if current_mana < cost:
		return false
	current_mana -= cost
	mana = current_mana
	return true

func has_mana(cost: int) -> bool:
	return current_mana >= cost
