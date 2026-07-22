extends Window
class_name ActionPopup
signal wait_selected
signal attack_selected
signal undo_selected

@onready var wait_button := $VBoxContainer/WaitButton
@onready var attack_button := $VBoxContainer/AttackButton
@onready var undo_button := $VBoxContainer/UndoButton
@onready var info_label := $VBoxContainer/InfoLabel

func _ready() -> void:
	wait_button.pressed.connect(_on_wait_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	undo_button.pressed.connect(_on_undo_pressed)

func configure(can_move: bool, can_attack: bool, message: String = "Choose an action", first_text: String = "Wait", second_text: String = "Attack", undo_text: String = "Undo", can_undo: bool = false) -> void:
	info_label.text = message
	wait_button.text = first_text
	attack_button.text = second_text
	undo_button.text = undo_text
	wait_button.disabled = not can_move
	attack_button.disabled = not can_attack
	undo_button.disabled = not can_undo

func _on_wait_pressed() -> void:
	emit_signal("wait_selected")
	hide()
	queue_free()

func _on_attack_pressed() -> void:
	emit_signal("attack_selected")
	hide()
	queue_free()

func _on_undo_pressed() -> void:
	emit_signal("undo_selected")
	hide()
	queue_free()
