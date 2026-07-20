extends RefCounted
class_name MovementBehavior

func get_valid_moves(unit: Unit, board: Board) -> Array[Vector2i]:
	return []

func get_attack_targets(unit: Unit, board: Board, attack_component: AtkComponent) -> Array[Vector2i]:
	if attack_component == null:
		return []
	var pattern_name := attack_component.get_pattern_name()
	match pattern_name:
		"bishop_ray":
			return get_sliding_attack_targets(unit, board, [
				Vector2i(1, 1),
				Vector2i(-1, 1),
				Vector2i(1, -1),
				Vector2i(-1, -1)
			], attack_component)
		"rook_ray":
			return get_sliding_attack_targets(unit, board, [
				Vector2i(0, 1),
				Vector2i(0, -1),
				Vector2i(1, 0),
				Vector2i(-1, 0)
			], attack_component)
		"queen_ray":
			return get_sliding_attack_targets(unit, board, [
				Vector2i(0, 1),
				Vector2i(0, -1),
				Vector2i(1, 0),
				Vector2i(-1, 0),
				Vector2i(1, 1),
				Vector2i(-1, 1),
				Vector2i(1, -1),
				Vector2i(-1, -1)
			], attack_component)
		"knight_jump":
			return get_knight_attack_targets(unit, board, attack_component)
		"pawn_diagonal":
			return get_pawn_attack_targets(unit, board, attack_component)
		_:
			return get_adjacent_attack_targets(unit, board, attack_component)

func get_sliding_moves(unit: Unit, board: Board, directions: Array[Vector2i]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for direction in directions:
		var current := unit.grid_pos + direction
		while board.is_within_bounds(current):
			var occupant := board.get_unit_at(current)
			if occupant == null:
				moves.append(current)
			else:
				if occupant.team != unit.team:
					moves.append(current)
				break
			current += direction
	return moves

func get_knight_moves(unit: Unit, board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var offsets := [
		Vector2i(1, 2),
		Vector2i(2, 1),
		Vector2i(-1, 2),
		Vector2i(-2, 1),
		Vector2i(1, -2),
		Vector2i(2, -1),
		Vector2i(-1, -2),
		Vector2i(-2, -1)
	]
	for offset in offsets:
		var target: Vector2i = unit.grid_pos + offset
		if not board.is_within_bounds(target):
			continue
		var occupant := board.get_unit_at(target)
		if occupant == null or occupant.team != unit.team:
			moves.append(target)
	return moves

func get_adjacent_attack_targets(unit: Unit, board: Board, attack_component: AtkComponent) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var offsets := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1)
	]
	for offset in offsets:
		var cell : Vector2i = unit.grid_pos + offset
		if not board.is_within_bounds(cell):
			continue
		if is_valid_attack_cell(unit, board, cell, attack_component, 1):
			targets.append(cell)
	return targets

func get_knight_attack_targets(unit: Unit, board: Board, attack_component: AtkComponent) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var offsets := [
		Vector2i(1, 2),
		Vector2i(2, 1),
		Vector2i(-1, 2),
		Vector2i(-2, 1),
		Vector2i(1, -2),
		Vector2i(2, -1),
		Vector2i(-1, -2),
		Vector2i(-2, -1)
	]
	for offset in offsets:
		var cell : Vector2i = unit.grid_pos + offset
		if not board.is_within_bounds(cell):
			continue
		if is_valid_attack_cell(unit, board, cell, attack_component, 1):
			targets.append(cell)
	return targets

func get_pawn_attack_targets(unit: Unit, board: Board, attack_component: AtkComponent) -> Array[Vector2i]:
	var direction := -1 if unit.team == 0 else 1
	var targets: Array[Vector2i] = []
	for delta_x in [-1, 1]:
		var cell : Vector2i = unit.grid_pos + Vector2i(delta_x, direction)
		if not board.is_within_bounds(cell):
			continue
		if is_valid_attack_cell(unit, board, cell, attack_component, 1):
			targets.append(cell)
	return targets

func get_sliding_attack_targets(unit: Unit, board: Board, directions: Array[Vector2i], attack_component: AtkComponent) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var min_range := attack_component.get_minimum_range()
	var max_range := attack_component.get_maximum_range()
	for direction in directions:
		var current := unit.grid_pos + direction
		var step := 1
		while board.is_within_bounds(current) and step <= max_range:
			var occupant := board.get_unit_at(current)
			if step >= min_range and is_valid_attack_cell(unit, board, current, attack_component, step):
				targets.append(current)
			if attack_component.needs_line_of_sight and occupant != null:
				break
			current += direction
			step += 1
	return targets

func is_valid_attack_cell(unit: Unit, board: Board, cell: Vector2i, attack_component: AtkComponent, step: int) -> bool:
	if not board.is_within_bounds(cell):
		return false
	if cell == unit.grid_pos and not attack_component.can_hit_self:
		return false
	var occupant := board.get_unit_at(cell)
	if occupant != null and occupant.team == unit.team and not attack_component.can_hit_allies:
		return false
	return step >= attack_component.get_minimum_range() and step <= attack_component.get_maximum_range()

func filter_check_moves(unit: Unit, board: Board, moves: Array[Vector2i]) -> Array[Vector2i]:
	return unit.filter_check_moves(board, moves)
