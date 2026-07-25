extends Node
class_name ActionPopupController

const ActionPopupScene = preload("res://scenes/UI/ActionPopup.tscn")
var current_popup: Window = null

func show_for(unit: Node2D, can_move: bool, can_attack: bool, undo_available: bool, on_wait: Callable, on_attack: Callable, on_undo: Callable, message: String = "Wait or attack?", first_text: String = "Wait", second_text: String = "Attack", undo_text: String = "Undo") -> void:
	_remove_existing_action_popup()
	var popup := ActionPopupScene.instantiate() as Window
	if popup == null:
		return
	get_tree().get_root().add_child(popup)
	popup.configure(can_move, can_attack, message, first_text, second_text, undo_text, undo_available)
	popup.wait_selected.connect(on_wait)
	popup.attack_selected.connect(on_attack)
	popup.undo_selected.connect(on_undo)
	_position_popup(popup, unit)
	current_popup = popup

func clear() -> void:
	_remove_existing_action_popup()
	current_popup = null

func _remove_existing_action_popup() -> void:
	var root := get_tree().get_root()
	for child in root.get_children():
		if child is ActionPopup:
			child.queue_free()

func _position_popup(popup: Window, anchor_unit: Node2D) -> void:
	if popup == null or anchor_unit == null:
		return
	var popup_size := popup.size
	var anchor_position := anchor_unit.global_position
	var screen_position := get_viewport().get_canvas_transform() * anchor_position
	popup.position = Vector2(screen_position.x + 32, screen_position.y - popup_size.y / 2)
	popup.popup()
