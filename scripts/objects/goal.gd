class_name Goal
extends Area2D
## Exit / goal marker (maze exit, glowing chest, safety zone, mayor's bag).

@export var label_text: String = "EXIT"
@export var texture: Texture2D
@export var sprite_scale: float = 1.0
## Turn off to hide the goal art (the level can draw its own treasure box instead).
@export var show_sprite: bool = true

var _t: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = get_node_or_null("Label") as Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	if texture:
		sprite.texture = texture
	sprite.visible = show_sprite
	if label:
		label.text = label_text
	z_index = 4
	queue_redraw()


func _draw() -> void:
	# A consistent destination marker remains readable over the scenery.
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -92), Vector2(16, -92), Vector2(0, -68)]), Color("ffe273"))
	draw_arc(Vector2.ZERO, 36.0, 0, TAU, 32, Color(1, 0.85, 0.3, 0.8), 3.0)


func _process(delta: float) -> void:
	_t += delta
	sprite.scale = Vector2.ONE * sprite_scale * (1.0 + sin(_t * 3.0) * 0.05)
	sprite.modulate = Color.WHITE.lerp(Color(1.0, 1.0, 0.55), (sin(_t * 4.0) + 1.0) * 0.5)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBase:
		var lvl := get_tree().get_first_node_in_group("level") as Level
		if lvl:
			lvl.on_goal_reached()
