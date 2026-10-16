class_name RestartZone
extends Area2D
## Sends the player back to the checkpoint start (pits, fall zones, quicksand).

@export var size: Vector2 = Vector2(400, 200)
@export var message: String = "Waaah!"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		var shape := RectangleShape2D.new()
		shape.size = size
		cs.shape = shape
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBase:
		var lvl := get_tree().get_first_node_in_group("level") as Level
		if lvl:
			lvl.handle_fall(message)
