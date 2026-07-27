extends Control
class_name CardUI

const SIZE := Vector2(200,278)
@export var card_stats: Card
@export var card_theme: CardTheme

@onready var card_ui: CardUI = $"." #reference to the parent node

#Frames
@onready var base_front: TextureRect = $BaseFront
@onready var canvas: TextureRect = $Canvas
@onready var artwork: TextureRect = $Artwork
@onready var banner: TextureRect = $Banner
@onready var desc_frame: TextureRect = $DescFrame
@onready var mana_frame: TextureRect = $ManaFrame

#Labels
@onready var card_name: Label = $Banner/CardName
@onready var card_desc: RichTextLabel = $DescFrame/CardDesc
@onready var mana_cost: Label = $ManaFrame/manaCost

@onready var art_image: Sprite2D = $Artwork/ArtImage #main art
@onready var mana_icon: Sprite2D = $ManaFrame/ManaIcon

var is_dragging: bool = false
var dragging_offset := Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + dragging_offset
		if Input.is_action_just_released("left_mouse"): #dropping the card
			is_dragging = false
			

func setup(cardData: Card):
	card_stats = cardData
	var theme := cardData.card_theme
	#Order from the backmost texture to the frontmost texture
	base_front.texture = theme.card_base_texture
	canvas.texture = theme.canvas_texture
	artwork.texture = theme.art_frame_texture
	art_image.texture = theme.art_image_sprite
	banner.texture = theme.banner_texture
	desc_frame.texture = theme.desc_texture
	mana_frame.texture = theme.mana_frame_texture
	mana_icon.texture = theme.mana_icon_texture
	
	art_image.z_index = 10
	mana_icon.scale = Vector2(2,1.8)
	mana_icon.z_index = 10
	
	card_name.text = cardData.card_name
	card_desc.text = cardData.description
	mana_cost.text = str(cardData.mana_cost)
	
	card_name.z_index = 10
	card_desc.z_index  = 10
	mana_cost.z_index = 10
	


func _on_mouse_entered() -> void:
	card_is_focused(true)


func _on_mouse_exited() -> void:
	card_is_focused(false)
	
func card_is_focused(value: bool):
	if value:
		z_index = 10
		await hover_anim(card_ui, 0)
	else:
		z_index = 0
		await hover_anim(card_ui, 1)
		
func _on_gui_input(event: InputEvent) -> void:
	if is_dragging:
		return
	if event.is_action_pressed("left_mouse"):
		is_dragging = true
		dragging_offset = global_position - get_global_mouse_position()

func hover_anim(parent_node: Control, type: int):
	var t: Tween = create_tween().set_parallel(true)
	for child in card_ui.get_children():
		if child is Control:
			match type:
				#Quick zoom-in (0)/zoom-out (1) effect
				0:
					t.tween_property(child, "scale", Vector2(1.2,1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				1:
					t.tween_property(child, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
