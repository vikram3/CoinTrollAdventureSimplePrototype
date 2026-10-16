class_name PlayerCT
extends PlayerBase
## Side-scrolling CT: run, jump, attack and pick up coins.
## Used by the naked CT (checkpoint 02) and the suit CT (checkpoints 03-18).

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

var _coyote: float = 0.0
var _buffer: float = 0.0
var _attack_time: float = 0.0
var _attack_cd: float = 0.0
var _hit_this_swing: Array[Node] = []
var _attack_offset_x: float = 36.0

@onready var attack_area: Area2D = $AttackArea
@onready var swoosh: Node2D = get_node_or_null("AttackArea/Swoosh") as Node2D


func _ready() -> void:
	super._ready()
	_attack_offset_x = absf(attack_area.position.x)
	if swoosh:
		swoosh.visible = false


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	var dir := 0.0
	if controls_enabled and _knock_timer <= 0.0 and not is_stunned():
		dir = Input.get_axis("move_left", "move_right")

	# Jump with coyote time and input buffering.
	if is_on_floor():
		_coyote = coyote_time
	else:
		_coyote -= delta
	var jump_pressed := controls_enabled and not is_stunned() and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up"))
	if jump_pressed:
		_buffer = jump_buffer_time
	else:
		_buffer -= delta
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_buffer = 0.0
		_coyote = 0.0
		Sfx.play("jump")
	var jump_released := Input.is_action_just_released("jump") or Input.is_action_just_released("move_up")
	if jump_released and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# Horizontal movement.
	if _knock_timer > 0.0:
		_knock_timer -= delta
	else:
		var target := dir * run_speed + push_x
		var rate := acceleration if absf(dir) > 0.01 else friction
		if not is_on_floor():
			rate *= air_control
		velocity.x = move_toward(velocity.x, target, rate * delta)

	if dir > 0.01:
		facing = 1
	elif dir < -0.01:
		facing = -1
	sprite.flip_h = facing < 0
	attack_area.position.x = _attack_offset_x * facing
	if swoosh:
		swoosh.scale.x = float(facing)

	# Attack.
	if can_attack and controls_enabled and not is_stunned() and Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_start_attack()
	_attack_cd -= delta
	if _attack_time > 0.0:
		_attack_time -= delta
		_apply_attack_hits()
		if _attack_time <= 0.0 and swoosh:
			swoosh.visible = false

	update_hiding()
	# Guard against NaN velocities (see open bugs in the design doc).
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	move_and_slide()
	_update_animation()


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
	elif not is_on_floor():
		play_anim("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 20.0:
		play_anim("run")
	else:
		play_anim("idle")
