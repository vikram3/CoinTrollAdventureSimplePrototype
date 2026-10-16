class_name Chaser
extends Area2D
## Moving threat that kills on touch (the forest chaser, the sand wormfish).

@export var speed: float = 468.0
@export var start_delay: float = 1.0
@export var max_x: float = 1000000.0
@export var texture: Texture2D
@export var kill_message: String = "Caught!"

var _delay: float = 0.0
var _t: float = 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	_delay = start_delay
	if texture and sprite:
		sprite.texture = texture


func _physics_process(delta: float) -> void:
	_t += delta
	if sprite:
		sprite.position.y = sin(_t * 6.0) * 6.0
	if _delay > 0.0:
		_delay -= delta
		return
	position.x = minf(position.x + speed * delta, max_x)
	for b in get_overlapping_bodies():
		if b is PlayerBase:
			(b as PlayerBase).kill(kill_message)
