extends CanvasLayer
class_name BattleScene

signal battle_resolved(result: String)

@onready var attacker_sprite: Sprite2D = $Panel/VBoxContainer/Arena/AttackerSprite
@onready var target_sprite: Sprite2D = $Panel/VBoxContainer/Arena/TargetSprite
@onready var attacker_health_bar: ProgressBar = $Panel/VBoxContainer/HealthHBox/AttackerVBox/AttackerHealthBar
@onready var target_health_bar: ProgressBar = $Panel/VBoxContainer/HealthHBox/TargetVBox/TargetHealthBar
@onready var attacker_label: Label = $Panel/VBoxContainer/HealthHBox/AttackerVBox/AttackerLabel
@onready var target_label: Label = $Panel/VBoxContainer/HealthHBox/TargetVBox/TargetLabel
@onready var finish_button: Button = $Panel/VBoxContainer/FinishButton
@onready var arena: HBoxContainer = $Panel/VBoxContainer/Arena

var attacker_unit: Unit = null
var defender_unit: Unit = null
var tween: Tween
var banner_rect: ColorRect = null
var speedline_timer: Timer = null

func _ready() -> void:
	finish_button.visible = false
	finish_button.pressed.connect(_on_finish_pressed)
	if attacker_unit != null and defender_unit != null:
		populate_from_units()
		play_battle_animation()

func set_battle_units(attacker: Unit, defender: Unit) -> void:
	attacker_unit = attacker
	defender_unit = defender
	if is_inside_tree():
		populate_from_units()
		play_battle_animation()

func populate_from_units() -> void:
	if attacker_unit != null:
		attacker_label.text = "%s (Team %d)" % [attacker_unit.get_piece_name(), attacker_unit.team]
		if attacker_unit.sprite_node != null and attacker_unit.sprite_node.texture != null:
			attacker_sprite.texture = attacker_unit.sprite_node.texture
		update_health_bar(attacker_health_bar, attacker_unit.get_health_component())

	if defender_unit != null:
		target_label.text = "%s (Team %d)" % [defender_unit.get_piece_name(), defender_unit.team]
		if defender_unit.sprite_node != null and defender_unit.sprite_node.texture != null:
			target_sprite.texture = defender_unit.sprite_node.texture
		update_health_bar(target_health_bar, defender_unit.get_health_component())

func update_health_bar(bar: ProgressBar, health_component: HealthComponent) -> void:
	if health_component == null:
		return
	bar.max_value = health_component.MAX_HEALTH
	bar.value = health_component.health

func play_battle_animation() -> void:
	if attacker_unit == null or defender_unit == null:
		return
	if tween != null:
		tween.kill()
	attacker_sprite.modulate = Color.WHITE
	target_sprite.modulate = Color.WHITE
	# start centered and larger for visibility
	attacker_sprite.position = Vector2(300, 375)
	target_sprite.position = Vector2(900, 375)
	attacker_sprite.scale = Vector2(4, 4)
	target_sprite.scale = Vector2(4, 4)

	# create or refresh banner behind the sprites
	_create_banner()


	# spawn an initial burst of speed lines
	_spawn_initial_lines(banner_rect, banner_rect.custom_minimum_size.x, banner_rect.custom_minimum_size.y, banner_rect.color)

	# start a timer to keep spawning lines until the animation completes
	if speedline_timer != null and is_instance_valid(speedline_timer):
		speedline_timer.queue_free()
		speedline_timer = null
	speedline_timer = Timer.new()
	speedline_timer.wait_time = 0.12
	speedline_timer.one_shot = false
	add_child(speedline_timer)
	speedline_timer.start()
	speedline_timer.timeout.connect(_on_speedline_timer_timeout)

	# ensure attacker/defender are above the banner/lines
	attacker_sprite.z_index = 10
	target_sprite.z_index = 10

	tween = create_tween()
	# Wind-up: step back and lean
	tween.tween_property(attacker_sprite, "position", Vector2(150, 375), 0.18)
	tween.tween_property(attacker_sprite, "rotation_degrees", -12.0, 0.18)
	tween.tween_interval(0.08)
	# Dash forward towards target (impact)
	tween.tween_property(attacker_sprite, "position", Vector2(900, 375), 0.14)
	tween.tween_property(attacker_sprite, "rotation_degrees", 6.0, 0.14)
	tween.tween_property(attacker_sprite, "scale", Vector2(4.1, 3.9), 0.14)
	
	# Defender reaction: flash red and shake
	tween.tween_property(target_sprite, "modulate", Color(1.0, 0.4, 0.4, 1.0), 0.06)
	tween.tween_property(target_sprite, "position", Vector2(908, 375), 0.06)
	tween.tween_property(target_sprite, "position", Vector2(892, 375), 0.06)
	tween.tween_property(target_sprite, "position", Vector2(904, 375), 0.06)
	tween.tween_property(target_sprite, "position", Vector2(900, 375), 0.06)
	tween.tween_property(target_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)
	tween.tween_interval(0.06)
	
	# Retreat attacker back to origin
	tween.tween_property(attacker_sprite, "position", Vector2(300, 375), 0.16)
	tween.tween_property(attacker_sprite, "rotation_degrees", 0.0, 0.16)
	tween.tween_property(attacker_sprite, "scale", Vector2(4, 4), 0.16)
	tween.tween_callback(_on_animation_finished)


func _create_banner() -> void:
	# remove old banner if present
	if banner_rect != null and is_instance_valid(banner_rect):
		banner_rect.queue_free()
		banner_rect = null

	# banner vertical center is between the sprites, width spans the viewport with margin
	var banner_h := 160
	var viewport_size := get_viewport().get_visible_rect().size
	var margin := 1
	var banner_w := int(max(8, viewport_size.x - margin * 2))
	var center_y := (attacker_sprite.global_position.y + target_sprite.global_position.y) * 0.5

	# Create a ColorRect banner control 
	banner_rect = ColorRect.new()
	banner_rect.custom_minimum_size = Vector2(banner_w, banner_h)
	# horizontal: stick to margins; vertical: center between sprites
	banner_rect.position = Vector2(margin, center_y - banner_h * 0.5)
	banner_rect.z_index = -5
	# color depends on attacking team: assume team 0 = white, else black
	if attacker_unit != null and attacker_unit.team == 0:
		banner_rect.color = Color(0.2, 0.45, 0.95, 1.0) # blue for white attacker
	else:
		banner_rect.color = Color(0.95, 0.25, 0.25, 1.0) # red for black attacker

	# add to this CanvasLayer so container layout won't resize it
	add_child(banner_rect)

	# spawn animated horizontal speed lines across the banner (use banner as parent)
	_spawn_speed_lines(banner_rect, banner_w, banner_h, banner_rect.color)


func _spawn_speed_lines(banner: ColorRect, banner_w: int, banner_h: int, color: Color) -> void:
	var line_h := 8
	var line_w := int(banner_w * 0.45)
	if line_w < 2:
		line_w = 2

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# spawn several lines at top and bottom of the banner (use ColorRect children)
	for i in 3:
		for side in [ -1, 1 ]: # -1 top, 1 bottom
			# spawn a single fast line for more visual impact
			_spawn_speed_line(banner, banner_w, banner_h, color, side)

func _spawn_initial_lines(banner: ColorRect, banner_w: int, banner_h: int, color: Color) -> void:
	# spawn a larger initial burst
	for i in 6:
		_spawn_speed_line(banner, banner_w, banner_h, color, -1)
		_spawn_speed_line(banner, banner_w, banner_h, color, 1)

func _spawn_speed_line(banner: ColorRect, banner_w: int, banner_h: int, color: Color, side: int) -> void:
	var line_h := 6
	var line_w := int(banner_w * 0.35)
	if line_w < 2:
		line_w = 2

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(line_w, line_h)
	line.z_index = 0
	line.color = color.lerp(Color(1,1,1,1), 0.45)

	var y_off := 0
	if side == -1:
		y_off = int(rng.randf_range(6, 28))
	else:
		y_off = int(banner_h - line_h - rng.randf_range(6, 28))

	var start_x_local := -rng.randi_range(40, 160)
	var end_x_local := banner_w + rng.randi_range(40, 160)
	line.position = Vector2(start_x_local, y_off)
	banner.add_child(line)

	# faster durations for speedy effect
	var dur := rng.randf_range(0.18, 0.34)
	var t := create_tween()
	t.tween_property(line, "position:x", end_x_local, dur).from(start_x_local)
	t.tween_property(line, "modulate:a", 0.0, 0.08).set_delay(dur - 0.08)
	t.tween_callback(Callable(line, "queue_free")).set_delay(dur)


func _on_animation_finished() -> void:
	var result: String = "draw"
	if attacker_unit != null and defender_unit != null:
		result = attacker_unit.resolve_combat(defender_unit)
	update_health_bar(attacker_health_bar, attacker_unit.get_health_component())
	update_health_bar(target_health_bar, defender_unit.get_health_component())
	emit_signal("battle_resolved", result)
	finish_button.visible = true
	finish_button.text = "Continue"

	# stop spawning extra speed lines when animation fully finished
	if speedline_timer != null and is_instance_valid(speedline_timer):
		speedline_timer.stop()
		speedline_timer.queue_free()
		speedline_timer = null

func _on_finish_pressed() -> void:
	queue_free()

func _on_speedline_timer_timeout() -> void:
	# spawn a few quick lines each tick to maintain motion while timer is running
	if banner_rect != null and is_instance_valid(banner_rect):
		_spawn_speed_line(banner_rect, banner_rect.custom_minimum_size.x, banner_rect.custom_minimum_size.y, banner_rect.color, -1)
		_spawn_speed_line(banner_rect, banner_rect.custom_minimum_size.x, banner_rect.custom_minimum_size.y, banner_rect.color, 1)
