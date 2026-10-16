extends Node2D
## Fires light projectiles in a fixed direction on a timer (deck hazards).

@export var projectile_scene: PackedScene
@export var direction: Vector2 = Vector2.LEFT
@export var interval: float = 3.5
@export var first_delay: float = 2.0
@export var speed: float = 220.0
@export var lifetime: float = 14.0

var _cd: float = 0.0


func _ready() -> void:
	_cd = first_delay


func _physics_process(delta: float) -> void:
	_cd -= delta
	if _cd > 0.0 or projectile_scene == null:
		return
	_cd = interval
	var proj := projectile_scene.instantiate() as Projectile
	proj.direction = direction.normalized()
	proj.speed = speed
	proj.lifetime = lifetime
	proj.shooter = self
	get_parent().add_child(proj)
	proj.global_position = global_position
