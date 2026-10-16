class_name PlayerCTTopDown
extends PlayerBase
## Naked CT for checkpoint 01: top-down movement through the hedge maze.

@export var move_speed: float = 260.0
@export var acceleration: float = 2400.0


func _ready() -> void:
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _knock_timer > 0.0:
		_knock_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
	else:
		velocity = velocity.move_toward(input * move_speed, acceleration * delta)
	if input.x > 0.01:
		facing = 1
	elif input.x < -0.01:
		facing = -1
	sprite.flip_h = facing < 0
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	move_and_slide()
	if _knock_timer > 0.0:
		play_anim("hurt")
	elif velocity.length() > 20.0:
		play_anim("run")
	else:
		play_anim("idle")


func _apply_knockback(from_position: Vector2, knockback: Vector2, source: String) -> void:
	if source != "":
		_last_knocker = source
		_last_knock_time = _now()
	if from_position == Vector2.INF:
		return
	var dir := (global_position - from_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	velocity = dir * absf(knockback.x)
	_knock_timer = 0.2
