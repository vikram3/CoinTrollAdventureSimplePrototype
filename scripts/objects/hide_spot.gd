class_name HideSpot
extends Area2D
## A bush or crate CT can hide in. Stand inside and hold DOWN (or HIDE on touch).
## Hidden CT is ignored by enemies and can't be hurt.

@export var size: Vector2 = Vector2(120, 110)
@export var hint: String = "Hold DOWN to hide!"

var _said: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		var shape := RectangleShape2D.new()
		shape.size = size
		cs.shape = shape
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBase:
		var p := body as PlayerBase
		p.can_hide = true
		if not _said:
			_said = true
			p.say(hint, 2.0)


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerBase:
		(body as PlayerBase).can_hide = false
