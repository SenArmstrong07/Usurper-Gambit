extends RefCounted
class_name EffectContext

var owner_player: Player
var source_unit: Unit

var target_unit: Unit
var target_player: Player
var target_cell: Vector2i
var target_quadrant: int = -1

var board: Board
var game: Game
var player: Player
var card: Card

func _init(
	game_ref: Game = null,
	board_ref: Board = null,
	player_ref: Player = null,
	card_ref: Card = null
	) -> void:
		game = game_ref
		board = board_ref
		player = player_ref
		card = card_ref
	
