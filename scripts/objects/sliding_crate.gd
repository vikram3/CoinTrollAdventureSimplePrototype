class_name SlidingCrate
extends CharacterBody2D
## Crate sliding down the tilting deck (level 16). Kills CT on touch.
## After its lifetime it returns to where it started and slides again.

@export var slide_direction: int = -1
@export var max_speed: float = 280.0
@export var acceleration: float = 220.0
@export var lifetime: float = 14.0
@export var start_delay: float = 1.0
@export var gravity: float = 1900.0

var _age: float = 0.0
var _delay: float = 0.0
var _spawn: Vector2 = Vector2.ZERO

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: Node2D = $Sprite


func _ready() -> void:
	add_to_group("hazard")
	_spawn = global_position
	_delay = start_delay


func _physics_process(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
		return
	_age += delta
	if _age >= lifetime or global_position.y > 2000.0:
		_respawn()
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	velocity.x = move_toward(velocity.x, slide_direction * max_speed, acceleration * delta)
	sprite.rotation = sin(_age * 9.0) * 0.04
	move_and_slide()
	for b in hurtbox.get_overlapping_bodies():
		if b is PlayerBase:
			(b as PlayerBase).kill("Flattened by a crate!")


func _respawn() -> void:
	global_position = _spawn
	velocity = Vector2.ZERO
	_age = 0.0
	_delay = 0.6
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
