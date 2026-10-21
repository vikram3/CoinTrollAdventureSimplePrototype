class_name PlayerCT
extends PlayerBase
## Side-scrolling CT: run, jump, attack and pick up coins.
## Used by the naked CT (level 03) and the suit CT (levels 04-19).
## Extras: double jump (jump again in the air), dash (Shift / C) and block
## (hold Q / Ctrl on the ground). Mouse: left click attacks, hold right click to block.
## Block stops hits from the front, like Alex's shield.

@export var run_speed: float = 440.0
@export var acceleration: float = 3000.0
@export var friction: float = 3400.0
@export var air_control: float = 0.75
@export var jump_velocity: float = -760.0
@export var jump_cut_multiplier: float = 0.5
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var can_attack: bool = true
@export var attack_damage: int = 1
@export var attack_duration: float = 0.16
@export var attack_cooldown: float = 0.3
@export_group("Double jump")
@export var can_double_jump: bool = true
@export var max_air_jumps: int = 1
@export var double_jump_velocity: float = -640.0
@export_group("Dash")
@export var can_dash: bool = true
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.6
@export_group("Block")
@export var can_block: bool = true
@export var block_move_speed: float = 90.0

var _coyote: float = 0.0
var _buffer: float = 0.0
var _attack_time: float = 0.0
var _attack_cd: float = 0.0
var _hit_this_swing: Array[Node] = []
var _attack_offset_x: float = 36.0
var _air_jumps_left: int = 0
var _dashing: bool = false
var _dash_time: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: int = 1
var _blocking: bool = false
var _mouse_attack: bool = false

@onready var attack_area: Area2D = $AttackArea
@onready var swoosh: Node2D = get_node_or_null("AttackArea/Swoosh") as Node2D


func _ready() -> void:
	super._ready()
	_attack_offset_x = absf(attack_area.position.x)
	if swoosh:
		swoosh.visible = false
	_setup_input_actions()


## Adds the dash and block keys without touching the project's input map.
func _setup_input_actions() -> void:
	_ensure_action("dash", [KEY_SHIFT, KEY_C])
	_ensure_action("block", [KEY_Q, KEY_CTRL])


func _ensure_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


func _unhandled_input(event: InputEvent) -> void:
	# Left click attacks. Clicks that a menu consumes never reach here.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_attack = true


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_dash_cd -= delta
	if not is_on_floor() and not _dashing:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	var dir := 0.0
	if controls_enabled and _knock_timer <= 0.0 and not is_stunned():
		dir = Input.get_axis("move_left", "move_right")

	# Block: hold on the ground. Blocking stops jumping, dashing and attacking.
	_blocking = can_block and controls_enabled and not is_stunned() and is_on_floor() and not _dashing and (Input.is_action_pressed("block") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
	self_modulate = Color(0.7, 0.85, 1.0) if _blocking else Color.WHITE

	# Dash: a short fast burst with no gravity. Dashing is invulnerable (see take_damage).
	if _dashing:
		_dash_time -= delta
		velocity.x = _dash_dir * dash_speed
		velocity.y = 0.0
		if _dash_time <= 0.0:
			_dashing = false
			velocity.x *= 0.4
	elif can_dash and controls_enabled and not is_stunned() and not _blocking and not is_hidden \
			and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		_start_dash(dir)

	# Jump with coyote time, input buffering and one extra jump in the air.
	if is_on_floor():
		_coyote = coyote_time
		_air_jumps_left = max_air_jumps if can_double_jump else 0
	else:
		_coyote -= delta
	var jump_pressed := controls_enabled and not is_stunned() and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up"))
	if jump_pressed:
		_buffer = jump_buffer_time
	else:
		_buffer -= delta
	if _buffer > 0.0 and not _blocking and not _dashing:
		if _coyote > 0.0:
			velocity.y = jump_velocity
			_buffer = 0.0
			_coyote = 0.0
			Sfx.play("jump")
		elif _air_jumps_left > 0:
			velocity.y = double_jump_velocity
			_air_jumps_left -= 1
			_buffer = 0.0
			Sfx.play("jump", 0.1)
	var jump_released := Input.is_action_just_released("jump") or Input.is_action_just_released("move_up")
	if jump_released and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# Horizontal movement (the dash sets its own velocity above).
	if _dashing:
		pass
	elif _knock_timer > 0.0:
		_knock_timer -= delta
	else:
		var speed := block_move_speed if _blocking else run_speed
		var target := dir * speed + push_x
		var rate := acceleration if absf(dir) > 0.01 else friction
		if not is_on_floor():
			rate *= air_control
		velocity.x = move_toward(velocity.x, target, rate * delta)

	if not _dashing:
		if dir > 0.01:
			facing = 1
		elif dir < -0.01:
			facing = -1
	sprite.flip_h = facing < 0
	attack_area.position.x = _attack_offset_x * facing
	if swoosh:
		swoosh.scale.x = float(facing)

	# Attack.
	if can_attack and controls_enabled and not is_stunned() and not _blocking and not _dashing and (Input.is_action_just_pressed("attack") or _mouse_attack) and _attack_cd <= 0.0:
		_start_attack()
	_attack_cd -= delta
	if _attack_time > 0.0:
		_attack_time -= delta
		_apply_attack_hits()
		if _attack_time <= 0.0 and swoosh:
			swoosh.visible = false

	_mouse_attack = false
	update_hiding()
	# Guard against NaN velocities (see open bugs in the design doc).
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	move_and_slide()
	_update_animation()


## Hits from the front are blocked while holding block. Hits from above
## (falling rocks, logs) still land.
func is_blocking_from(pos: Vector2) -> bool:
	if not _blocking:
		return false
	if pos.y < global_position.y - 20.0:
		return false
	var side := signf(pos.x - global_position.x)
	return side == 0.0 or int(side) == facing


func take_damage(amount: int, from_position: Vector2 = Vector2.INF, knockback: Vector2 = Vector2(260, -280), source: String = "") -> bool:
	if _dashing and not is_dead:
		return false
	if from_position != Vector2.INF and amount > 0 and not is_dead and not invincible and not is_hidden and is_blocking_from(from_position):
		Sfx.play("block")
		shake_camera(3.0, 0.1)
		return false
	return super.take_damage(amount, from_position, knockback, source)


func _start_dash(dir: float) -> void:
	_dashing = true
	_dash_time = dash_duration
	_dash_cd = dash_cooldown
	_dash_dir = facing
	if dir > 0.01:
		_dash_dir = 1
	elif dir < -0.01:
		_dash_dir = -1
	facing = _dash_dir
	Sfx.play("swing")


func _start_attack() -> void:
	_attack_time = attack_duration
	_attack_cd = attack_cooldown
	_hit_this_swing.clear()
	if swoosh:
		swoosh.visible = true
	Sfx.play("swing")


func _apply_attack_hits() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body in _hit_this_swing:
			continue
		if body.has_method("take_hit"):
			_hit_this_swing.append(body)
			body.call("take_hit", attack_damage, global_position, self, "melee")


func _update_animation() -> void:
	if _knock_timer > 0.0:
		play_anim("hurt")
	elif _attack_time > 0.0:
		play_anim("attack")
	elif _dashing:
		play_anim("run")
	elif not is_on_floor():
		play_anim("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 20.0:
		play_anim("run")
	else:
		play_anim("idle")
