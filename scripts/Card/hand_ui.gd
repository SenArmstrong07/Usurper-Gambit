extends Control
class_name HandUI

const card_scene = preload("res://scenes/Card/CardUI.tscn")

@onready var card_container: Control = $CardContainer

var player: Player = null
var deck_ui: Control
var _draw_queue: Array[Card] = []
var _is_drawing_opening_hand: bool = false
signal card_selected(card: Card)
signal card_requested(card: Card, mouse_pos: Vector2)
signal opening_draw_started
signal opening_draw_completed
@export var hand_curve: Curve
@export var rotation_curve: Curve

@export var max_rotation_degrees:= 5
@export var x_sep := 10 # separation of the cards in the x axis
@export var min_sep := 30.0 # minimum spacing to avoid overlap
@export var y_min:= 0
@export var y_max  := -15

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_cards()

func _input(event):
	if event is InputEventMouseMotion:
		var hovered := get_viewport().gui_get_hovered_control()
		print(hovered)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_cards()
	if what == NOTIFICATION_MOUSE_ENTER:
		for card in card_container.get_children():
			print(card, " enter")
	elif what == NOTIFICATION_MOUSE_EXIT:
		for card in card_container.get_children():
			print(card, " enter")

func set_player(new_player: Player) -> void:
	if player != null:
		if player.hand_changed.is_connected(_on_player_hand_changed):
			player.hand_changed.disconnect(_on_player_hand_changed)
		if player.card_drawn.is_connected(_on_player_card_drawn):
			player.card_drawn.disconnect(_on_player_card_drawn)
		if player.card_discarded.is_connected(_on_player_card_discarded):
			player.card_discarded.disconnect(_on_player_card_discarded)

	player = new_player

	if player != null:
		player.hand_changed.connect(_on_player_hand_changed)
		player.card_drawn.connect(_on_player_card_drawn)
		player.card_discarded.connect(_on_player_card_discarded)

	refresh()

func set_deck_ui(deck: Control) -> void:
	deck_ui = deck

func _on_player_hand_changed() -> void:
	print("HAND CHANGED SIGNAL")
	if player == null:
		return
	if _is_drawing_opening_hand:
		return
	refresh()

func _on_player_card_drawn(card: Card) -> void:
	_draw_queue.append(card)
	if not _is_drawing_opening_hand:
		_is_drawing_opening_hand = true
		emit_signal("opening_draw_started")
		await _process_draw_queue()

func _on_player_card_discarded(card: Card) -> void:
	refresh()

func _update_cards() -> void:
	if card_container == null:
		return

	var card_nodes := card_container.get_children()
	var count := card_nodes.size()
	if count == 0:
		return

	var container_width := card_container.size.x
	if container_width <= 0:
		container_width = get_viewport_rect().size.x

	var card_scale := 1.0
	var final_x_sep := x_sep
	if count > 1:
		var total_width := CardUI.SIZE.x * count + x_sep * (count - 1)
		if total_width > container_width:
			card_scale = clamp(container_width / total_width, 0.5, 1.0)
			final_x_sep = x_sep * card_scale
		else:
			var available_space := container_width - CardUI.SIZE.x * count
			var target_sep := available_space / (count - 1)
			final_x_sep = clamp(target_sep, 0.0, x_sep)
	
	var card_width := CardUI.SIZE.x * card_scale
	var spacing := card_width + final_x_sep
	var hand_width := spacing * (count - 1) + card_width
	var center_x : float = container_width * 0.5
	var first_card_x := (container_width - hand_width) * 0.5
	print("----------------")
	print("Player hand:", player.hand.size())
	print("UI children:", card_container.get_child_count())
	for c in count:
		var card := card_nodes[c]
		var sample_pos := 0.0
		if count > 1:
			sample_pos = 1.0 / (count - 1) * c
		
		var y_multiplier := hand_curve.sample(sample_pos)
		var rot_multiplier := rotation_curve.sample(sample_pos)
		
		if count == 1:
			y_multiplier = 0.0
			rot_multiplier = 0.0
		
		var final_x: float = first_card_x + spacing * c
		var final_y: float = y_min + y_max * y_multiplier
		
		card.scale = Vector2(card_scale, card_scale)
		var target_position = Vector2(final_x, final_y)
		card.position = target_position
		card.z_index = c
		if card is CardUI:
			card.default_z_index = c
			card.set_base_position(target_position)
		card.rotation_degrees = max_rotation_degrees * rot_multiplier
	
	print("HandLayout: ", count, "cards, container_width=", container_width, "sep=", final_x_sep, "scale=", card_scale)
	var mouse_pos := get_global_mouse_position()
	print("DEBUG mouse position=", mouse_pos)
	for debug_card in card_nodes:
		var rect = debug_card.get_global_rect()
		if debug_card is CardUI:
			print("    ", debug_card.name, "pos=", debug_card.position, "global=", debug_card.global_position, "scale=", debug_card.scale, "z=", debug_card.z_index, "rect=", rect, "hit=", rect.has_point(mouse_pos))
		else:
			print("    ", debug_card, "pos=", debug_card.position, "global=", debug_card.global_position, "z=", debug_card.z_index, "rect=", rect, "hit=", rect.has_point(mouse_pos))

func _on_card_selected(card: Card) -> void:
	card_selected.emit(card)

func _on_card_dropped(card: Card) -> void:
	print("Card dropped, requesting play for: ", card.card_name)
	card_requested.emit(card, get_global_mouse_position())

func add_card_ui(card: Card) -> CardUI:
	var ui := card_scene.instantiate() as CardUI

	ui.size = CardUI.SIZE
	ui.position = Vector2.ZERO
	ui.mouse_filter = Control.MOUSE_FILTER_STOP

	card_container.add_child(ui)
	ui.name = "CardUI_%d" % card_container.get_child_count()

	ui.setup(card)
	ui.card_clicked.connect(_on_card_selected)
	ui.card_dropped.connect(_on_card_dropped)

	_update_cards()
	if ui is CardUI:
		ui.set_base_position(ui.position)

	return ui

func _process_draw_queue() -> void:
	while _draw_queue.size() > 0:
		var card: Card = _draw_queue.pop_front()
		await animate_draw(card)
	_is_drawing_opening_hand = false
	emit_signal("opening_draw_completed")

func animate_draw(card: Card):
	print("--- Before draw ---")
	for child in card_container.get_children():
		print(child)
	if deck_ui == null:
		push_error("Deck UI not assigned!")
		return

	var ui := add_card_ui(card)
	ui.show_back()
	
	# Ensure the card UI has its final layout before animating from the deck.
	_update_cards()
	var target := ui.global_position
	ui.global_position = deck_ui.global_position
	ui.show_back()
	
	await ui.play_draw_animation(target)
	print(
	ui.name,
	" scale=", ui.scale,
	" size=", ui.size,
	" rect=", ui.get_global_rect()
	)
	
func _get_next_card_position() -> Vector2:

	var count := card_container.get_child_count()

	var spacing := 120.0
	var local_pos := Vector2(count * spacing, 0)
	
	var target_global = card_container.global_position
	return target_global
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_viewport().get_mouse_position()
		var hits := []
		for child in card_container.get_children():
			if child is CardUI:
				var rect : Rect2 = child.get_global_rect()
				if rect.has_point(mouse_pos):
					hits.append({"name": child.name, "z": child.z_index, "rect": rect})
		if hits.size() == 0:
			print("DEBUG click: no card hit at", mouse_pos)
		else:
			hits.sort_custom(Callable(self, "_sort_hits_by_z"))
			print("DEBUG click: mouse=", mouse_pos, "hits=")
			for hit in hits:
				print("    ", hit["name"], "z=", hit["z"], "rect=", hit["rect"])

func _sort_hits_by_z(a: Dictionary, b: Dictionary) -> int:
	return int(b["z"] - a["z"])

func refresh() -> void:
	if player == null:
		print("Player is null")
		return

	for child in card_container.get_children():
		if child is CardUI:
			if child.card_clicked.is_connected(_on_card_selected):
				child.card_clicked.disconnect(_on_card_selected)
			child.free()

	print("Hand size:", player.hand.size())
	print("REFRESH CALLED")
	for card in player.hand:
		print("Creating UI for:", card)
		var ui := card_scene.instantiate() as CardUI
		print("UI instance:", ui)

		ui.size = CardUI.SIZE
		ui.position = Vector2.ZERO
		ui.mouse_filter = Control.MOUSE_FILTER_STOP
		card_container.add_child(ui)
		ui.name = "CardUI_%d" % card_container.get_child_count()
		ui.setup(card)
		ui.card_clicked.connect(_on_card_selected)
		ui.card_dropped.connect(_on_card_dropped)
	print("Children after refresh:", card_container.get_child_count())
	_update_cards()

func remove_card_ui(card: Card) -> void:
	if card == null or card_container == null:
		return

	for child in card_container.get_children():
		if child is CardUI and child.card_stats == card:
			if child.card_clicked.is_connected(_on_card_selected):
				child.card_clicked.disconnect(_on_card_selected)
			card_container.remove_child(child)
			child.call_deferred("free")
			_update_cards()
			return

	print("No card UI found for: ", card.card_name)
