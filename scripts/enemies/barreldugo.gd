class_name Barreldugo
extends EnemyBase
## Barreldugo: stays at range and fires projectiles. Weak up close -
## when CT gets in close it panics and stops firing.

@export var projectile_scene: PackedScene
@export var fire_interval: float = 2.0
@export var fire_range: float = 760.0
@export var panic_range: float = 130.0
@export var projectile_speed: float = 390.0
@export var first_shot_delay: float = 1.0
@export_group("Lines")
@export var lines_fire: PackedStringArray = ["Boom!", "Barrel blast!", "Incoming!"]
@export var lines_panic: PackedStringArray = ["Too close! Too close!", "Back off, I'm a long-range guy!", "Eep!"]

var _cd: float = 1.0

@onready var muzzle: Marker2D = get_node_or_null("Muzzle") as Marker2D


func _ready() -> void:
	super._ready()
	_cd = first_shot_delay


func _enemy_process(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	var p := get_player()
	if p == null:
		return
	var dx := p.global_position.x - global_position.x
	if absf(dx) > 1.0:
		face(int(signf(dx)))
	var dist := global_position.distance_to(p.global_position)
	_cd -= delta
	if dist < panic_range:
		tint = Color(0.8, 0.8, 1.0)
		say_line(lines_panic, "panic", 1.5)
		return
	tint = Color.WHITE
	if dist < fire_range and _cd <= 0.0:
		_cd = fire_interval
		_fire(p)


func _fire(p: PlayerBase) -> void:
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate() as Projectile
	var origin := global_position + Vector2(28.0 * facing, -14.0)
	if muzzle:
		origin = global_position + Vector2(absf(muzzle.position.x) * facing, muzzle.position.y)
	proj.direction = (p.global_position + Vector2(0, -10) - origin).normalized()
	proj.speed = projectile_speed
	proj.shooter = self
	get_parent().add_child(proj)
	proj.global_position = origin
	say_line(lines_fire, "fire")
	Sfx.play("swing")
