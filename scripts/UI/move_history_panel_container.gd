extends PanelContainer
class_name MoveHistoryPanelContainer

@onready var content_margin: MarginContainer = $MarginContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var moves_list_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MovesListContainer
@onready var side_button: Button = get_parent().get_node("SideButton") as Button

var move_history: Array[String] = []
var is_hidden: bool = false
var visible_x: float = 0.0
var hidden_x: float = 0.0
var history_tween: Tween = null

func _ready() -> void:
	call_deferred("_initialize_panel")

func _initialize_panel() -> void:
	show()
	custom_minimum_size = Vector2(240, 320)
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	moves_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moves_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_button.z_index = 10
	side_button.text = "Minimize"
	visible_x = position.x
	side_button.pressed.connect(_on_side_button_pressed)
	_update_button_position()
	update_history_view()

func add_move(move_text: String) -> void:
	move_history.append(move_text)
	update_history_view()
	call_deferred("_scroll_to_bottom")

func undo_last_move() -> void:
	if move_history.size() == 0:
		return
	move_history.pop_back()
	update_history_view()
	call_deferred("_scroll_to_bottom")

func clear_history() -> void:
	move_history.clear()
	update_history_view()

func update_history_view() -> void:
	for child in moves_list_container.get_children():
		child.queue_free()

	for index in range(move_history.size()):
		var label := Label.new()
		label.text = "%d. %s" % [index + 1, move_history[index]]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.custom_minimum_size = Vector2(0, 24)
		moves_list_container.add_child(label)

func _scroll_to_bottom() -> void:
	if scroll_container == null:
		return
	var v_scroll := scroll_container.get_v_scroll_bar()
	scroll_container.scroll_vertical = int(v_scroll.max_value)

func _on_side_button_pressed() -> void:
	is_hidden = not is_hidden
	if is_hidden:
		side_button.text = "Show"
	else:
		side_button.text = "Minimize"
	_animate_panel_slide(is_hidden)
	_update_button_position()

func _animate_panel_slide(hide: bool) -> void:
	if history_tween != null:
		history_tween.kill()
	history_tween = create_tween()
	var panel_width := size.x
	if panel_width <= 0:
		panel_width = custom_minimum_size.x
	var target_x := visible_x + (panel_width + 8.0 if hide else 0.0)
	history_tween.tween_property(self, "position:x", target_x, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	history_tween.connect("finished", Callable(self, "_on_animation_finished"))
	_update_button_position(target_x)

func _on_animation_finished() -> void:
	_update_button_position(position.x)

func _update_button_position(panel_x: float = -1.0) -> void:
	var panel_width : float = size.x
	if panel_width <= 0:
		panel_width = custom_minimum_size.x
	var button_x: float
	var button_width: float = side_button.custom_minimum_size.x
	if button_width <= 0.0:
		button_width = side_button.size.x
