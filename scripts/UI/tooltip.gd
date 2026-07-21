extends Panel
class_name TooltipUI

@onready var label := $MarginContainer/Label

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 100
	show()
	hide()

func show_tooltip(text: String, screen_pos: Vector2) -> void:
	if label != null:
		label.text = text
	var tip_size := get_minimum_size()
	size = tip_size
	var view_size := get_viewport().get_visible_rect().size
	position = Vector2(
		clamp(screen_pos.x, 0, view_size.x - tip_size.x),
		clamp(screen_pos.y, 0, view_size.y - tip_size.y)
	)
	show()

func hide_tooltip() -> void:
	hide()
