class_name Boomerang
extends Area2D
## Big Bird's boomerang: tracks the target on the way out, then flies home.
## Alex's shield sends it straight back.

@export var speed: float = 559.0
@export var turn_rate: float = 2.4
@export var out_time: float = 1.7
@export var damage: int = 1
@export var knockback: Vector2 = Vector2(260, -240)
@export var max_lifetime: float = 7.0

var thrower: Node2D = null
var target: Node2D = null
var _velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _returning: bool = false
var _has_hit: bool = false
var _finished: bool = false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func launch() -> void:
	var aim := Vector2.RIGHT
	if is_instance_valid(target):
		aim = (target.global_position - global_position).normalized()
	_velocity = aim * speed


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_t += delta
	rotation += 14.0 * delta
	if _t > max_lifetime:
		_finish()
		return
	if not _returning:
		if is_instance_valid(target):
			var desired := (target.global_position - global_position).normalized()
			var ang := _velocity.angle_to(desired)
			_velocity = _velocity.rotated(clampf(ang, -turn_rate * delta, turn_rate * delta))
		if _t > out_time:
			_returning = true
	else:
		if not is_instance_valid(thrower):
			_finish()
			return
		var to := thrower.global_position - global_position
		if to.length() < 40.0:
			_finish()
			return
		_velocity = _velocity.lerp(to.normalized() * speed * 1.15, minf(6.0 * delta, 1.0))
	global_position += _velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if _finished or _has_hit:
		return
	var p := body as PlayerBase
	if p == null:
		return
	if p.is_blocking_from(global_position):
		Sfx.play("block")
		_returning = true
		_has_hit = true
		_velocity = -_velocity
		return
	if p.take_damage(damage, global_position, knockback, "boomerang"):
		_has_hit = true
		_returning = true


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if is_instance_valid(thrower) and thrower.has_method("boomerang_returned"):
		thrower.call("boomerang_returned")
	queue_free()
