extends Control
class_name CardUI

const SIZE := Vector2(200,278)
@export var CardStats: Card

#Frames
@onready var base_front: TextureRect = $BaseFront
@onready var canvas: TextureRect = $Canvas
@onready var artwork: TextureRect = $Artwork
@onready var banner: TextureRect = $Banner
@onready var desc_frame: TextureRect = $DescFrame


#Labels
@onready var card_name: Label = $CardName
@onready var card_desc: RichTextLabel = $CardDesc
@onready var mana_cost: Label = $manaCost


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(cardData: Card):
	CardStats = cardData
	#Order from the backmost texture to the frontmost texture
	base_front.texture = cardData.card_base_texture
	canvas.texture = cardData.canvas_texture
	artwork.texture = cardData.art_frame_texture
	banner.texture = cardData.banner_texture
	desc_frame.texture = cardData.desc_texture
	
	card_name.text = cardData.card_name
	card_desc.text = cardData.description
	mana_cost.text = str(cardData.mana_cost)
	
