extends MovementBehavior
class_name PawnMovement

func get_valid_moves(unit: Unit, board: Board) -> Array[Vector2i]:
    var moves: Array[Vector2i] = []
    var direction := -1 if unit.team == 0 else 1
    var one_step := unit.grid_pos + Vector2i(0, direction)
    var two_step := unit.grid_pos + Vector2i(0, direction * 2)
    var start_row := 6 if unit.team == 0 else 1

    if board.is_within_bounds(one_step) and not board.is_cell_occupied(one_step):
        moves.append(one_step)
        if unit.grid_pos.y == start_row and board.is_within_bounds(two_step) and not board.is_cell_occupied(two_step):
            moves.append(two_step)

    for delta_x in [-1, 1]:
        var capture_cell := unit.grid_pos + Vector2i(delta_x, direction)
        if not board.is_within_bounds(capture_cell):
            continue
        var target := board.get_unit_at(capture_cell)
        if target != null and target.team != unit.team:
            moves.append(capture_cell)

    if board.last_move_piece != null and board.last_move_piece.piece_type.to_lower() == "pawn" and abs(board.last_move_from.y - board.last_move_to.y) == 2:
        var passant_target := unit.grid_pos + Vector2i(board.last_move_to.x - unit.grid_pos.x, direction)
        if abs(board.last_move_to.x - unit.grid_pos.x) == 1 and board.last_move_to.y == unit.grid_pos.y and destination_is_en_passant_target(board, passant_target, unit.grid_pos, direction):
            moves.append(passant_target)

    return filter_check_moves(unit, board, moves)

func destination_is_en_passant_target(board: Board, cell: Vector2i, pawn_pos: Vector2i, pawn_direction: int) -> bool:
    if not board.is_within_bounds(cell):
        return false
    var target := board.get_unit_at(cell)
    return target == null and cell.x == board.last_move_to.x and cell.y == pawn_pos.y + pawn_direction
