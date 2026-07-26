extends Resource
class_name Card

@export var card_name: String
@export var description: String
@export var mana_cost: int
@export var card_base_texture: Texture2D
@export var canvas_texture : Texture2D
@export var art_frame_texture : Texture2D
@export var banner_texture : Texture2D
@export var desc_texture : Texture2D
enum TargetType
{
NONE,
ALLY_UNIT,
ENEMY_UNIT,
ANY_UNIT,
EMPTY_CELL,
ANY_CELL,
SELF,
ALL_ALLIES,
ALL_ENEMIES
}

@export var target_type: TargetType

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
