class_name PlayerAlex
extends PlayerBase
## Alex (level 13): move with the arrows, shield on down, bow on up,
## attack combo with the accept/attack key.

@export var run_speed: float = 320.0
@export var acceleration: float = 2600.0
@export var jump_velocity: float = -740.0
@export var shield_move_speed: float = 60.0
@export var combo_damage: PackedInt32Array = [1, 1, 2]
@export var combo_window: float = 0.45
@export var attack_duration: float = 0.16
@export var arrow_scene: PackedScene
@export var arrow_cooldown: float = 0.7

var shielding: bool = false
var _combo_step: int = -1
var _combo_timer: float = 0.0
var _attack_time: float = 0.0
var _attack_damage: int = 1
var _arrow_cd: float = 0.0
var _coyote: float = 0.0
var _hit_this_swing: Array[Node] = []
var _attack_offset_x: float = 40.0
var _shield_offset_x: float = 20.0

@onready var attack_area: Area2D = $AttackArea
@onready var shield: Node2D = $Shield
@onready var swoosh: Node2D = get_node_or_null("AttackArea/Swoosh") as Node2D


func _ready() -> void:
	super._ready()
	_attack_offset_x = absf(attack_area.position.x)
	_shield_offset_x = absf(shield.position.x)
	shield.visible = false
	if swoosh:
		swoosh.visible = false


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	if is_on_floor():
		_coyote = 0.1
	else:
		_coyote -= delta

	var dir := 0.0
	if controls_enabled and _knock_timer <= 0.0 and not is_stunned():
		dir = Input.get_axis("move_left", "move_right")
	shielding = controls_enabled and Input.is_action_pressed("move_down") and is_on_floor()
	shield.visible = shielding

	if controls_enabled and not is_stunned() and not shielding and Input.is_action_just_pressed("jump") and _coyote > 0.0:
		velocity.y = jump_velocity
		_coyote = 0.0
		Sfx.play("jump")
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	if _knock_timer > 0.0:
		_knock_timer -= delta
	else:
		var speed := shield_move_speed if shielding else run_speed
		velocity.x = move_toward(velocity.x, dir * speed + push_x, acceleration * delta)

	if dir > 0.01:
		facing = 1
	elif dir < -0.01:
		facing = -1
	sprite.flip_h = facing < 0
	shield.position.x = _shield_offset_x * facing
	shield.scale.x = float(facing)
	attack_area.position.x = _attack_offset_x * facing

	# Baton combo.
	_combo_timer -= delta
	if controls_enabled and not is_stunned() and not shielding and Input.is_action_just_pressed("attack") and _attack_time <= 0.04:
		_start_attack()
	if _attack_time > 0.0:
		_attack_time -= delta
		_apply_attack_hits()
		if _attack_time <= 0.0 and swoosh:
			swoosh.visible = false

	# Bow.
	_arrow_cd -= delta
	if controls_enabled and not is_stunned() and not shielding and Input.is_action_just_pressed("move_up") and _arrow_cd <= 0.0:
		_shoot_arrow()

	if not velocity.is_finite():
		velocity = Vector2.ZERO
	update_hiding()
	move_and_slide()
	_update_animation()


func is_blocking_from(pos: Vector2) -> bool:
	if not shielding:
		return false
	var side := signf(pos.x - global_position.x)
	return side == 0.0 or int(side) == facing


func _start_attack() -> void:
	if _combo_timer > 0.0 and _combo_step < combo_damage.size() - 1:
		_combo_step += 1
	else:
		_combo_step = 0
	_attack_damage = combo_damage[_combo_step]
	var finisher := _combo_step == combo_damage.size() - 1
	_attack_time = attack_duration + (0.06 if finisher else 0.0)
	_combo_timer = combo_window
	_hit_this_swing.clear()
	if swoosh:
		swoosh.visible = true
		var s := 1.0 + 0.25 * float(_combo_step)
		swoosh.scale = Vector2(s * float(facing), s)
	velocity.x += facing * 120.0
	Sfx.play("swing")


func _apply_attack_hits() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body in _hit_this_swing:
			continue
		if body.has_method("take_hit"):
			_hit_this_swing.append(body)
			body.call("take_hit", _attack_damage, global_position, self, "melee")


func _shoot_arrow() -> void:
	if arrow_scene == null:
		return
	_arrow_cd = arrow_cooldown
	var arrow := arrow_scene.instantiate() as Projectile
	arrow.hostile = false
	arrow.direction = Vector2(float(facing), 0.0)
	arrow.shooter = self
	get_parent().add_child(arrow)
	arrow.global_position = global_position + Vector2(facing * 30.0, -12.0)
	Sfx.play("swing")


func _update_animation() -> void:
	if _knock_timer > 0.0:
		play_anim("hurt")
	elif shielding:
		play_anim("shield")
	elif _attack_time > 0.0:
		play_anim("attack")
	elif not is_on_floor():
		play_anim("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 20.0:
		play_anim("run")
	else:
		play_anim("idle")
