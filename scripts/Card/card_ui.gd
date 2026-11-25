extends Control
class_name CardUI

const SIZE := Vector2(200,278)
signal card_clicked(card: Card)
signal card_dropped(card: Card)
@export var card_stats: Card
@export var card_theme: CardTheme

@onready var card_ui: CardUI = $"." #reference to the parent node
@onready var visuals: Control = $Visuals
#Frames
@onready var base_back: TextureRect = $Visuals/BaseBack
@onready var base_front: TextureRect = $Visuals/BaseFront
@onready var canvas: TextureRect = $Visuals/Canvas
@onready var artwork: TextureRect = $Visuals/Artwork
@onready var banner: TextureRect = $Visuals/Banner
@onready var desc_frame: TextureRect = $Visuals/DescFrame
@onready var mana_frame: TextureRect = $Visuals/ManaFrame

#Labels
@onready var card_name: Label = $Visuals/Banner/CardName
@onready var card_desc: RichTextLabel = $Visuals/DescFrame/CardDesc
@onready var mana_cost: Label = $Visuals/ManaFrame/manaCost

@onready var art_image: Sprite2D = $Visuals/Artwork/ArtImage #main art
@onready var mana_icon: Sprite2D = $Visuals/ManaFrame/ManaIcon

var is_dragging: bool = false
var dragging_offset := Vector2.ZERO
var default_z_index: int = 0
var base_position: Vector2 = Vector2.ZERO
var discard_highlight: Panel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.pivot_offset = SIZE / 2.0
	_set_children_mouse_filter(self)
	_setup_discard_highlight()
	default_z_index = z_index
	base_position = position

func _setup_discard_highlight() -> void:
	discard_highlight = Panel.new()
	discard_highlight.name = "DiscardHighlight"
	discard_highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	discard_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	discard_highlight.z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1, 0.1, 0.1, 1)
	style.set_border_width_all(6)
	style.set_corner_radius_all(4)
	discard_highlight.add_theme_stylebox_override("panel", style)
	discard_highlight.visible = false
	add_child(discard_highlight)

func set_discard_highlight(enabled: bool) -> void:
	if discard_highlight != null:
		discard_highlight.visible = enabled


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + dragging_offset

func setup(cardData: Card):
	card_stats = cardData
	if cardData == null:
		return

	var theme: CardTheme = null
	if cardData.card_theme == null:
		print("NO THEME ASSIGNED")
		return
	if cardData.has_method("get") and cardData.get("card_theme") != null:
		theme = cardData.card_theme

	if theme == null:
		push_warning("CardUI setup called without a valid CardTheme.")
		return

	#Order from the backmost texture to the frontmost texture
	if base_front != null:
		base_front.texture = theme.card_base_texture
	if canvas != null:
		canvas.texture = theme.canvas_texture
	if artwork != null:
		artwork.texture = theme.art_frame_texture
	if art_image != null:
		art_image.texture = theme.art_image_sprite
	if banner != null:
		banner.texture = theme.banner_texture
	if desc_frame != null:
		desc_frame.texture = theme.desc_texture
	if mana_frame != null:
		mana_frame.texture = theme.mana_frame_texture
	if mana_icon != null:
		mana_icon.texture = theme.mana_icon_texture
	
	if art_image != null:
		art_image.z_index = 10
	if mana_icon != null:
		mana_icon.scale = Vector2(2,1.8)
		mana_icon.z_index = 10
	
	if card_name != null:
		card_name.text = cardData.card_name
	if card_desc != null:
		card_desc.text = cardData.description
	if mana_cost != null:
		mana_cost.text = str(cardData.mana_cost)
	
	if card_name != null:
		card_name.z_index = 10
	if card_desc != null:
		card_desc.z_index = 10
	if mana_cost != null:
		mana_cost.z_index = 10
	


func _on_mouse_entered() -> void:
	print("hover", self.name)
	card_is_focused(true)

func show_back():
	base_back.visible = true

	base_front.visible = false
	canvas.visible = false
	artwork.visible = false
	banner.visible = false
	desc_frame.visible = false
	mana_frame.visible = false

	card_name.visible = false
	card_desc.visible = false
	mana_cost.visible = false

	art_image.visible = false
	mana_icon.visible = false

func show_front():
	base_back.visible = false

	base_front.visible = true
	canvas.visible = true
	artwork.visible = true
	banner.visible = true
	desc_frame.visible = true
	mana_frame.visible = true

	card_name.visible = true
	card_desc.visible = true
	mana_cost.visible = true

	art_image.visible = true
	mana_icon.visible = true

func _on_mouse_exited() -> void:
	card_is_focused(false)
	
func play_draw_animation(target_pos: Vector2):
	var flip_duration : float = 0.13
	var travel_duration : float = 0.20
	show_back()

	scale.x = 1.0

	var tween := create_tween()

	tween.parallel().tween_property(self, "global_position", target_pos, travel_duration)

	tween.tween_property(self, "scale:x", 0.0, flip_duration)

	tween.tween_callback(show_front)

	tween.tween_property(self, "scale:x", 1.0, flip_duration)
	
	await tween.finished

func card_is_focused(value: bool) -> void:
	if value:
		z_index = 100
		hover_anim(0)
	else:
		z_index = default_z_index
		hover_anim(1)
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_dragging:
				return
			is_dragging = true
			dragging_offset = global_position - get_global_mouse_position()
			print("Drag started for: ", card_stats.card_name)
		else:
			if not is_dragging:
				return
			var was_dropped_on_board := _is_over_board()
			is_dragging = false
			if was_dropped_on_board:
				print("Card released on board: ", card_stats.card_name)
				card_dropped.emit(card_stats)
				var return_tween := create_tween()
				return_tween.tween_property(self, "position", base_position, 0.2)
				return_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)
			else:
				print("Card released outside board: ", card_stats.card_name)
				card_clicked.emit(card_stats)
	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() + dragging_offset

func _is_over_board() -> bool:
	var board := get_tree().get_root().get_node_or_null("Game/Board") as Board
	if board == null:
		return false

	var board_child := board.get_node_or_null("chessBoard")
	if board_child is TileMapLayer:
		var local_mouse: Vector2 = board_child.get_local_mouse_position()
		var cell: Vector2i = board_child.local_to_map(local_mouse)
		return board.is_within_bounds(cell)

	return false

func hover_anim(type: int):
	var zoom_in_scale : Vector2 = Vector2(1.08, 1.08)
	var zoom_out_scale : Vector2 = Vector2.ONE
	var t: Tween = create_tween().set_parallel(true)
	match type:
		#Quick zoom-in (0)/zoom-out (1) effect
		0:
			t.tween_property(self, "scale", zoom_in_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			t.tween_property(self, "position", Vector2(base_position.x, base_position.y - 20.0), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		1:
			t.tween_property(self, "scale", zoom_out_scale, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			t.tween_property(self, "position", base_position, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_children_mouse_filter(node: Node) -> void:
	for child in node.get_children():
		if "mouse_filter" in child:
			child.set("mouse_filter", Control.MOUSE_FILTER_IGNORE)
		_set_children_mouse_filter(child)

func debug_mouse_filter_info() -> void:
	print("DEBUG card:", name, "mouse_filter=", mouse_filter, "global_rect=", get_global_rect())
	_debug_mouse_filter_recursive(self, 0)

func _debug_mouse_filter_recursive(node: Node, depth: int) -> void:
	for child in node.get_children():
		var indent := " ".repeat(depth * 2)
		if child is Control:
			print(indent, "child:", child.name, child.get_class(), "mouse_filter=", (child as Control).mouse_filter)
		else:
			print(indent, "child:", child.name, child.get_class())
		_debug_mouse_filter_recursive(child, depth + 1)

func set_base_position(value: Vector2) -> void:
	base_position = value
