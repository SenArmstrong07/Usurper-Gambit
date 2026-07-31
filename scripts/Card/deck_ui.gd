extends Control
class_name DeckUI

@export var deck_res: DeckResource

@onready var deck_cover: TextureRect = $DeckCover

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scale = Vector2(2,2)
	deck_cover.texture = deck_res.cover_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
