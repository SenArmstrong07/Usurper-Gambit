extends Node
class_name HighlightManager

const HighlightScene = preload("res://scenes/UI/HighlightCells.tscn")
const HighlightAtkScene = preload("res://scenes/UI/HighlightAtk.tscn")

var chess_board: Node2D = null
var highlight_markers: Node2D = null
var highlighted_cells: Array = []

func init(_chess_board: Node2D, _highlight_markers: Node2D) -> void:
	chess_board = _chess_board
	highlight_markers = _highlight_markers
	highlighted_cells = []
	if highlight_markers != null:
		highlight_markers.visible = false

func show_move_tiles(cells: Array[Vector2i]) -> void:
	_show_tiles(cells, false)

func show_attack_tiles(cells: Array[Vector2i]) -> void:
	_show_tiles(cells, true)

func show_quadrant_outline(quadrant: int) -> void:
	if highlight_markers == null or chess_board == null:
		return
	if quadrant < 0 or quadrant >= 4:
		push_warning("HighlightManager: Invalid quadrant index %d." % quadrant)
		return

	clear()
	var start_cell := Vector2i((quadrant % 2) * 4, int(quadrant / 2) * 4)
	var center := _cell_center_in_markers(start_cell)
	var step_x := _cell_center_in_markers(start_cell + Vector2i(1, 0)) - center
	var step_y := _cell_center_in_markers(start_cell + Vector2i(0, 1)) - center

	var top_left := center - step_x * 0.5 - step_y * 0.5
	var top_right := _cell_center_in_markers(start_cell + Vector2i(3, 0)) + step_x * 0.5 - step_y * 0.5
	var bottom_right := _cell_center_in_markers(start_cell + Vector2i(3, 3)) + step_x * 0.5 + step_y * 0.5
	var bottom_left := _cell_center_in_markers(start_cell + Vector2i(0, 3)) - step_x * 0.5 + step_y * 0.5

	var outline := Line2D.new()
	outline.points = PackedVector2Array([top_left, top_right, bottom_right, bottom_left])
	outline.closed = true
	outline.width = min(step_x.length(), step_y.length()) * 0.12
	outline.default_color = Color(1.0, 0.82, 0.15, 1.0)
	outline.antialiased = true
	highlight_markers.add_child(outline)
	highlighted_cells.append(outline)
	highlight_markers.visible = true

func clear() -> void:
	if highlight_markers == null:
		return
	for child in highlight_markers.get_children():
		child.queue_free()
	highlighted_cells.clear()
	highlight_markers.visible = false

func _cell_center_in_markers(cell: Vector2i) -> Vector2:
	return highlight_markers.to_local(chess_board.to_global(chess_board.map_to_local(cell)))

func _show_tiles(cells: Array[Vector2i], use_attack_texture: bool) -> void:
	clear()
	if highlight_markers == null or chess_board == null:
		return
	for cell in cells:
		var marker: Node2D
		if use_attack_texture:
			marker = HighlightAtkScene.instantiate() as Node2D
		else:
			marker = HighlightScene.instantiate() as Node2D
		marker.position = chess_board.map_to_local(cell)
		highlight_markers.add_child(marker)
		highlighted_cells.append(marker)
	highlight_markers.visible = highlighted_cells.size() > 0
