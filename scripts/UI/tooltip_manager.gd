extends Node
class_name TooltipManager

var tooltip: TooltipUI = null

func init(_tooltip: TooltipUI) -> void:
	tooltip = _tooltip

func show_unit_tooltip(unit: Node2D) -> void:
	if tooltip == null or unit == null or not unit.is_inside_tree():
		return
	if not unit.has_method("get_health_component") or not unit.has_method("get_attack_component"):
		return
	var health_comp = unit.get_health_component()
	var atk_comp = unit.get_attack_component()
	var hp_text 
	if health_comp != null:
		hp_text = str(health_comp.get_current_health()) 
	else:
		hp_text = "N/A"
	var atk_text 
	if atk_comp != null:
		atk_text = str(atk_comp.get_damage_amount()) 
	else:
		atk_text = "N/A"
	var text = "%s\nHP: %s  ATK: %s" % [unit.get_piece_name(), hp_text, atk_text]
	var screen_position = get_viewport().get_canvas_transform() * unit.global_position
	var offset = Vector2(25, -25)
	tooltip.show_tooltip(text, screen_position + offset)

func hide_tooltip() -> void:
	if tooltip == null:
		return
	tooltip.hide_tooltip()
