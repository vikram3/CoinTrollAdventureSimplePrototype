class_name Projectile
extends Area2D
## Straight projectile. Hostile shots (Barreldugo, deck hazards) hurt the player;
## friendly shots (Alex's arrows) hurt enemies. Alex's shield reflects hostile shots.

@export var speed: float = 320.0
@export var damage: int = 1
@export var lifetime: float = 4.0
@export var hostile: bool = true
@export var knockback: Vector2 = Vector2(220, -220)
@export var source_name: String = "projectile"
@export var rotate_to_direction: bool = true
@export var reflectable: bool = true

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null
var _done: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if hostile:
		collision_layer = 8
		collision_mask = 1 | 2
	else:
		collision_layer = 32
		collision_mask = 1 | 4
	if rotate_to_direction:
		rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _done:
		return
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _done or body == shooter:
		return
	if hostile and body is PlayerBase:
		var p := body as PlayerBase
		if reflectable and p.is_blocking_from(global_position):
			_reflect(p)
			return
		p.take_damage(damage, global_position, knockback, source_name)
		_finish()
	elif not hostile and body is EnemyBase:
		(body as EnemyBase).take_hit(damage, global_position, shooter, "arrow")
		_finish()
	elif body is StaticBody2D:
		_finish()


func _reflect(by: Node) -> void:
	Sfx.play("block")
	hostile = false
	shooter = by
	direction = -direction
	if rotate_to_direction:
		rotation = direction.angle()
	set_deferred("collision_layer", 32)
	set_deferred("collision_mask", 1 | 4)


func _finish() -> void:
	_done = true
	Fx.burst(get_parent(), global_position, Color(0.9, 0.8, 0.6), 6, 90.0, 0.3)
	queue_free()
