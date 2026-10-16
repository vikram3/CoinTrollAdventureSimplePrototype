@tool
class_name Block
extends StaticBody2D
## Plain sprite-based environment piece (no tilesets). Set the size and the
## texture in the inspector; the sprite region and collision follow.

@export var size: Vector2 = Vector2(256, 64):
	set(value):
		size = value
		_apply()
@export var tile_texture: Texture2D:
	set(value):
		tile_texture = value
		_apply()
@export var one_way: bool = false:
	set(value):
		one_way = value
		_apply()
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if spr:
		if tile_texture:
			spr.texture = tile_texture
		spr.centered = true
		spr.region_enabled = true
		spr.region_rect = Rect2(Vector2.ZERO, size)
		spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		spr.self_modulate = tint
	if col:
		var shape := RectangleShape2D.new()
		shape.size = size
		col.shape = shape
		col.one_way_collision = one_way
