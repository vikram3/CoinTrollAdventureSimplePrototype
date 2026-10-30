class_name HideSpot
extends Area2D
## A bush or crate CT can hide in. CT hides automatically while his centre is inside it.
## Hidden CT is ignored by enemies and can't be hurt. While CT is inside, the bush is solid for skulls.

## Physics layer used by occupied bushes. Skulls collide with it; CT does not.
const BUSH_BLOCK_LAYER := 16

@export var size: Vector2 = Vector2(120, 110)
@export var hint: String = "Get inside to hide!"

## True while CT is hiding inside this bush.
var occupied: bool = false
var _said: bool = false
var _blocker: StaticBody2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		var shape := RectangleShape2D.new()
		shape.size = size
		cs.shape = shape
	add_to_group("hide_spot")
	_blocker = StaticBody2D.new()
	_blocker.collision_layer = 0
	_blocker.collision_mask = 0
	var bcs := CollisionShape2D.new()
	var bshape := RectangleShape2D.new()
	bshape.size = size
	bcs.shape = bshape
	_blocker.add_child(bcs)
	add_child(_blocker)
	body_entered.connect(_on_body_entered)
	z_index = 1
	var label := Label.new()
	label.text = "SHELTER"
	label.position = Vector2(-size.x * 0.5, -size.y * 0.5 - 26)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	queue_redraw()


func _draw() -> void:
	var area := Rect2(-size * 0.5, size)
	draw_rect(area, Color(0.12, 0.55, 0.32, 0.25), true)
	draw_rect(area, Color("78e8ac") if occupied else Color("77a88a"), false, 3.0)


func rect() -> Rect2:
	return Rect2(global_position - size * 0.5, size)


## True only when the point (CT's centre) is inside the bush itself, not just touching its edge.
func contains_point(world_pos: Vector2) -> bool:
	return rect().has_point(world_pos)


func _physics_process(_delta: float) -> void:
	var ct := get_tree().get_first_node_in_group("player") as PlayerBase
	occupied = ct != null and not ct.is_dead and contains_point(ct.global_position)
	queue_redraw()
	_blocker.set_deferred("collision_layer", BUSH_BLOCK_LAYER if occupied else 0)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBase and not _said:
		_said = true
		(body as PlayerBase).say(hint, 2.0)
