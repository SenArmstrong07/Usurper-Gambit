extends Node2D
class_name Unit

# STATS
@export var armor: int = 0
@export var team: int = 0
@export var piece_type: String = "pawn"

# LOCATION STUFF
var grid_pos: Vector2i = Vector2i.ZERO
var current_target: Unit
var board: Board
var has_moved: bool = false

# MOVEMENT STUFF
var movement_component: MovementComponent = null
const PawnMovement = preload("res://scripts/Unit/Movement/pawn_movement.gd")
const KnightMovement = preload("res://scripts/Unit/Movement/knight_movement.gd")
const BishopMovement = preload("res://scripts/Unit/Movement/bishop_movement.gd")
const RookMovement = preload("res://scripts/Unit/Movement/rook_movement.gd")
const QueenMovement = preload("res://scripts/Unit/Movement/queen_movement.gd")
const KingMovement = preload("res://scripts/Unit/Movement/king_movement.gd")

# UI STUFF
var is_dragging : bool = false
var input_pickable : bool = true
var drag_offset : Vector2 = Vector2.ZERO
var sprite_node: Sprite2D

func _ready() -> void:
	add_to_group("Unit")
	set_process_input(true)
	input_pickable = true
	if sprite_node == null:
		create_sprite()
	init_movement_component()
	init_attack_component()

func _process(delta: float) -> void:
	update_combat(delta)
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if board != null and board.game_over:
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if mouse_event.pressed:
		var mouse_position := get_global_mouse_position()
		if is_under_mouse(mouse_position):
			if board != null:
				board.select_unit(self)

func update_combat(delta):
	pass

func is_under_mouse(mouse_position: Vector2) -> bool:
	var rect := Rect2(global_position - Vector2(8, 8), Vector2(16, 16))
	return rect.has_point(mouse_position)

func create_sprite() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.name = "PieceSprite"
	sprite_node.centered = true
	sprite_node.position = Vector2.ZERO
	sprite_node.scale = Vector2(0.5, 0.5)
	add_child(sprite_node)

func apply_sprite() -> void:
	if sprite_node == null:
		create_sprite()

	var normalized_type := piece_type.to_lower()
	var team_name := "white" if team == 0 else "black"
	var texture_path := "res://assets/duo/%s_%s.png" % [team_name, normalized_type]
	var texture := load(texture_path) as Texture2D
	if texture != null:
		sprite_node.texture = texture
	else:
		sprite_node.texture = load("res://assets/duo/neutral_pawn.png")
	print(sprite_node.texture.get_size())
	print(sprite_node)
	print(sprite_node.get_path())

func get_piece_name() -> String:
	return piece_type.capitalize()

func is_enemy_in_range() -> bool:
	return false

func is_valid_move() -> bool:
	return false

func get_valid_moves(board: Board) -> Array[Vector2i]:
	if movement_component == null:
		return []
	return movement_component.get_valid_moves(board)

func set_movement(new_behavior: MovementBehavior) -> void:
	if movement_component == null:
		init_movement_component()
	movement_component.set_movement(new_behavior)

func init_movement_component() -> void:
	if has_node("MovementComponent"):
		movement_component = $MovementComponent
	else:
		movement_component = MovementComponent.new()
		add_child(movement_component)

	movement_component.set_movement(create_default_movement())

func init_attack_component() -> void:
	var attack_component := get_attack_component()
	if attack_component == null:
		return
	match piece_type.to_lower():
		"pawn":
			attack_component.damage = 2
			attack_component.minimum_range = 1
			attack_component.maximum_range = 1
			attack_component.pattern = "adjacent"
			attack_component.needs_line_of_sight = false
		"rook":
			attack_component.damage = 3
			attack_component.minimum_range = 1
			attack_component.maximum_range = 1
			attack_component.pattern = "adjacent"
			attack_component.needs_line_of_sight = false
		"knight":
			attack_component.damage = 5
			attack_component.minimum_range = 1
			attack_component.maximum_range = 1
			attack_component.pattern = "adjacent"
			attack_component.needs_line_of_sight = false
		"bishop":
			attack_component.damage = 4
			attack_component.minimum_range = 1
			attack_component.maximum_range = 6
			attack_component.pattern = "bishop_ray"
			attack_component.needs_line_of_sight = true
		"queen":
			attack_component.damage = 10
			attack_component.minimum_range = 1
			attack_component.maximum_range = 6
			attack_component.pattern = "queen_ray"
			attack_component.needs_line_of_sight = true
		"king":
			attack_component.damage = 2
			attack_component.minimum_range = 1
			attack_component.maximum_range = 1
			attack_component.pattern = "adjacent"
			attack_component.needs_line_of_sight = false
		_:
			attack_component.damage = 2
			attack_component.minimum_range = 1
			attack_component.maximum_range = 1
			attack_component.pattern = "adjacent"
			attack_component.needs_line_of_sight = false
	attack_component.current_atk = attack_component.damage

func create_default_movement() -> MovementBehavior:
	match piece_type.to_lower():
		"pawn":
			return PawnMovement.new()
		"knight":
			return KnightMovement.new()
		"bishop":
			return BishopMovement.new()
		"rook":
			return RookMovement.new()
		"queen":
			return QueenMovement.new()
		"king":
			return KingMovement.new()
		_:
			return MovementBehavior.new()

# Filter moves that would leave the king in check
func filter_check_moves(board: Board, moves: Array[Vector2i]) -> Array[Vector2i]:
	var safe_moves: Array[Vector2i] = []
	for move in moves:
		if not board.would_move_leave_king_in_check(self, move):
			safe_moves.append(move)
	return safe_moves

func update_check_visual(is_in_check: bool) -> void:
	print(piece_type, sprite_node, is_in_check)
	if sprite_node == null:
		return
	if piece_type.to_lower() != "king":
		return
	if is_in_check:
		sprite_node.modulate = Color.RED
	else:
		sprite_node.modulate = Color.WHITE
	print(piece_type, is_in_check)

func capture():
	print("Cell Captured")

func get_attack_component() -> AtkComponent:
	var attack_node := get_node_or_null("AtkComponent") as AtkComponent
	return attack_node

func get_health_component() -> HealthComponent:
	var health_node := get_node_or_null("HealthComponent") as HealthComponent
	return health_node

func get_attack_damage() -> int:
	var attack_component := get_attack_component()
	if attack_component == null:
		return 0
	return attack_component.get_damage_amount()

func get_attack_targets(board: Board) -> Array[Vector2i]:
	var attack_component := get_attack_component()
	if attack_component == null or movement_component == null:
		return []
	return movement_component.get_attack_targets(board, attack_component)

func can_attack_target(target: Unit) -> bool:
	if target == null or target == self or board == null:
		return false
	return target.grid_pos in get_attack_targets(board)

func can_attack_cell(target_cell: Vector2i) -> bool:
	if board == null:
		return false
	return target_cell in get_attack_targets(board)

func take_damage(amount: float) -> bool:
	var health_component := get_health_component()
	if health_component == null:
		return false
	return health_component.take_damage(amount)

func heal(amount: float) -> void:
	var health_component := get_health_component()
	if health_component != null:
		health_component.heal(amount)

func is_alive() -> bool:
	var health_component := get_health_component()
	if health_component == null:
		return true
	return health_component.is_alive()

func resolve_combat(target: Unit) -> String:
	if target == null or target == self:
		return "invalid"
	var attack_component := get_attack_component()
	var target_attack_component := target.get_attack_component()
	if attack_component == null or target_attack_component == null:
		return "invalid"

	target.take_damage(attack_component.get_damage_amount())
	if target.is_alive():
		take_damage(target_attack_component.get_damage_amount())

	if is_alive() and not target.is_alive():
		return "attacker_won"
	if not is_alive() and target.is_alive():
		return "defender_won"
	if not is_alive() and not target.is_alive():
		return "both_dead"
	return "draw"

func die() -> void:
	if board != null:
		board.remove_unit(self)
	else:
		queue_free()

func attack():
	print("Unit used an attack")

func find_target():
	print("Unit found target")

func move_to_target(new_pos: Vector2i):
	var pathway = board.get_pathway(self.grid_pos, current_target.grid_pos)
	print("Unit moved to target")
