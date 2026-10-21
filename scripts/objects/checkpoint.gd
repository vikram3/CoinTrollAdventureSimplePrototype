class_name Checkpoint
extends Area2D
## Mid-level checkpoint flag. The node's position is where CT stands when he respawns here.
## Touching it makes this the spot CT returns to after a fall or a defeat (instead of restarting the level).

@export var checkpoint_size: Vector2 = Vector2(64, 160)

var active: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = checkpoint_size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -checkpoint_size.y * 0.5)
	add_child(cs)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func set_active(on: bool) -> void:
	active = on
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if active or not (body is PlayerBase):
		return
	var lvl := get_tree().get_first_node_in_group("level") as Level
	if lvl:
		lvl.set_checkpoint(self)


func _draw() -> void:
	var top := -checkpoint_size.y
	var flag := Color(0.35, 0.9, 0.45) if active else Color(0.6, 0.6, 0.6)
	draw_line(Vector2(0, 0), Vector2(0, top), Color(0.85, 0.85, 0.8), 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, top), Vector2(44, top + 16), Vector2(0, top + 32)]), flag)
