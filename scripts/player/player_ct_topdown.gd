class_name PlayerCTTopDown
extends PlayerBase
## Naked CT for checkpoint 01: top-down movement through the hedge maze.

@export var move_speed: float = 260.0
@export var acceleration: float = 2400.0


func _ready() -> void:
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Draw CT above the bushes so he stays visible (semi-transparent) while hiding.
	z_index = 2


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Inside a bush CT is hidden from sight: skulls can't spot or chase him.
	# He can still move inside the bush, and a skull that bumps into him still catches him.
	var in_bush := _in_any_bush()
	if in_bush != is_hidden:
		is_hidden = in_bush
		sprite.modulate.a = 0.35 if is_hidden else 1.0
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


## Hidden CT can still be caught by touch, so hidden only blocks being spotted.
func take_damage(amount: int, from_position: Vector2 = Vector2.INF, knockback: Vector2 = Vector2(260, -280), source: String = "") -> bool:
	var was_hidden := is_hidden
	is_hidden = false
	var hit := super.take_damage(amount, from_position, knockback, source)
	is_hidden = was_hidden
	return hit


func is_hidden_now() -> bool:
	return _in_any_bush()


## Hidden only when CT's centre is inside a bush (HideSpot), so standing on the grass beside it doesn't count.
func _in_any_bush() -> bool:
	if is_dead:
		return false
	for spot in get_tree().get_nodes_in_group("hide_spot"):
		if spot.has_method("contains_point") and spot.call("contains_point", global_position):
			return true
	return false


func coin_drop_limit() -> float:
	return 16.0


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
