extends Node2D
class_name Game

var selected_piece: Vector2
var board: Board
var current_player: int = 0
var move_history: Array[String] = []
var turn_label: Label
var moves_label: Label
var game_over_label: Label
var reset_button: Button
var game_over: bool = false

func _ready() -> void:
	board = get_node_or_null("Board") as Board
	SignalBus.unit_moved.connect(_on_unit_moved)
	SignalBus.game_over.connect(_on_game_over)
	add_ui()
	if board != null:
		start_battle()

func _process(delta: float) -> void:
	pass

func start_battle() -> void:
	if board == null:
		return
	board.current_turn = current_player
	board.game_over = false
	game_over = false
	if game_over_label:
		game_over_label.visible = false
	board.setup_initial_pieces()
	update_ui()

func check_for_win_condition() -> void:
	print("checking for winner")

func _on_unit_moved(unit: Unit, from_cell: Vector2i, to_cell: Vector2i) -> void:
	if game_over:
		return
	var notation := format_move(unit, from_cell, to_cell)
	move_history.append(notation)
	# Turn switching is now handled in board.check_game_state()
	update_ui()

func _on_game_over(winner: int) -> void:
	game_over = true
	if winner == -1:
		game_over_label.text = "Draw by stalemate!"
	else:
		var winner_name := "White" if winner == 0 else "Black"
		game_over_label.text = "%s wins by checkmate!" % winner_name
	game_over_label.visible = true
	reset_button.visible = true
	update_ui()

func _on_reset_pressed() -> void:
	reset_button.visible = false
	game_over_label.visible = false
	move_history.clear()
	current_player = 0
	board.current_turn = current_player
	board.game_over = false
	board.board_state = board.BoardState.IDLE
	board.clear_board()
	board.setup_initial_pieces()
	update_ui()

func format_move(unit: Unit, from_cell: Vector2i, to_cell: Vector2i) -> String:
	var piece_name := unit.piece_type.capitalize()
	var from_notation := coordinate_to_notation(from_cell)
	var to_notation := coordinate_to_notation(to_cell)
	var prefix := "White" if unit.team == 0 else "Black"
	if piece_name == "Pawn":
		piece_name = ""
	return "%s: %s%s -> %s" % [prefix, piece_name, from_notation, to_notation]

func coordinate_to_notation(cell: Vector2i) -> String:
	var files := "abcdefgh"
	return files[cell.x] + str(8 - cell.y)

func add_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "GameUI"
	add_child(canvas)

	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.position = Vector2(20, 20)
	turn_label.scale = Vector2(1.2, 1.2)
	canvas.add_child(turn_label)

	moves_label = Label.new()
	moves_label.name = "MovesLabel"
	moves_label.position = Vector2(20, 60)
	moves_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	moves_label.size = Vector2(320, 220)
	canvas.add_child(moves_label)

	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.position = Vector2(20, 300)
	game_over_label.scale = Vector2(1.5, 1.5)
	game_over_label.visible = false
	game_over_label.modulate = Color.RED
	canvas.add_child(game_over_label)

	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "Replay"
	reset_button.position = Vector2(20, 360)
	reset_button.visible = false
	reset_button.pressed.connect(_on_reset_pressed)
	canvas.add_child(reset_button)

func update_ui() -> void:
	# Sync current_player with board's turn
	current_player = board.current_turn
	var player_name := "White" if current_player == 0 else "Black"
	turn_label.text = "Turn: %s" % player_name
	var history_text := "Moves:\n"
	for index in range(move_history.size()):
		history_text += "%d. %s\n" % [index + 1, move_history[index]]
	moves_label.text = history_text
