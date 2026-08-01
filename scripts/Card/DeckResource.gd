extends Resource
class_name DeckResource

@export var deck_name: String = "Starter Deck"
@export var cover_texture: Texture2D
@export var starting_cards: Array[Card] = []
@export var opening_hand_size: int = 5

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass
