class_name BigBoss
extends EnemyBase
## Big Boss: idle, jump, fall, windup, slam, slash, stagger, story.
## Every attack is telegraphed (0.8 s by default) before it lands.
## In level 06 he targets Pink Girl only (target_group = "pink_girl").

signal attack_landed(target: Node)

enum State { IDLE, WINDUP, SLASH, JUMP, FALL, RECOVER, STAGGER, STORY, DROP }

@export var target_group: String = "player"
@export var ignore_player: bool = false
@export var sword_wave_scene: PackedScene
@export var shockwave_scene: PackedScene
@export var telegraph_time: float = 0.8
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 2.0
@export var walk_speed: float = 143.0
@export var preferred_distance: float = 300.0
@export var jump_velocity: float = -950.0
@export var recover_time: float = 0.9
@export var stagger_time: float = 1.4
@export var slam_chance: float = 0.45
@export var feet_offset: float = 70.0
@export var arena_min_x: float = -100000.0
@export var arena_max_x: float = 100000.0
@export var story_mode: bool = false
## Chance per attack that Big Boss leaves a fading illusion copy of himself behind.
## Cosmetic only for now: the copy never hits anything.
@export var illusion_chance: float = 0.0
## Leap: when the target is this far away (px) in IDLE, Big Boss leaps in a jump arc and lands on the target.
## 0 disables it.
@export var teleport_distance: float = 0.0
@export var teleport_cooldown: float = 4.0
var _teleport_cd: float = 0.0
@export_group("Lines")
@export var lines_stagger: PackedStringArray = ["Grrh... lucky shot!", "What?! How?", "You'll pay for that!"]

var state: State = State.IDLE
var _timer: float = 1.5
var _next_attack: String = "slash"
var _slam_target_x: float = 0.0
var _air_time: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _slam_target_y: float = 0.0
var _drop_goal_y: float = 0.0

@onready var warning: CanvasItem = get_node_or_null("Warning") as CanvasItem
@onready var slam_marker: Node2D = get_node_or_null("SlamMarker") as Node2D


func _ready() -> void:
	walk_speed *= GameState.speed_mult()
	super._ready()
	_spawn_position = global_position
	if warning:
		warning.visible = false
	if slam_marker:
		slam_marker.top_level = true
		slam_marker.visible = false
	if story_mode:
		state = State.STORY


func get_target() -> Node2D:
	var t := get_tree().get_first_node_in_group(target_group) as Node2D
	if t is PlayerBase and ((t as PlayerBase).is_dead or (t as PlayerBase).is_hidden):
		return null
	return t


func is_telegraphing() -> bool:
	return state == State.WINDUP or state == State.JUMP or state == State.FALL


func _enemy_process(delta: float) -> void:
	apply_gravity(delta)
	_timer -= delta
	_watch_airborne(delta)
	if global_position.y > 1600.0 or ((state == State.JUMP or state == State.FALL) and global_position.y > _spawn_position.y + 600.0):
		_respawn()
		return
	var target := get_target()
	tint = Color.WHITE
	_teleport_cd = maxf(_teleport_cd - delta, 0.0)
	match state:
		State.DROP:
			velocity.x = 0.0
			if global_position.y >= _drop_goal_y or _timer <= 0.0:
				global_position.y = minf(global_position.y, _drop_goal_y)
				collision_mask = 1
				_to_idle()
		State.STORY:
			velocity.x = 0.0
		State.IDLE:
			if target:
				var dx := target.global_position.x - global_position.x
				if absf(dx) > 1.0:
					face(int(signf(dx)))
				if absf(dx) > preferred_distance:
					velocity.x = signf(dx) * walk_speed
				elif absf(dx) < preferred_distance * 0.5:
					velocity.x = -signf(dx) * walk_speed * 0.6
				else:
					velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			else:
				velocity.x = 0.0
			if target and teleport_distance > 0.0 and _teleport_cd <= 0.0 and is_on_floor() \
					and absf(target.global_position.x - global_position.x) > teleport_distance:
				_teleport_onto(target)
				return
			if randf() < 0.002:
				say_line(lines_idle, "idle")
			if target and is_on_floor() and _goal_y(target) - global_position.y > 60.0:
				_start_drop(_goal_y(target))
				return
			if _timer <= 0.0 and target:
				_begin_windup(target)
		State.WINDUP:
			velocity.x = 0.0
			tint = Color(1.0, 0.45, 0.35) if int(_timer * 10.0) % 2 == 0 else Color.WHITE
			if _timer <= 0.0:
				if warning:
					warning.visible = false
				if _next_attack == "slash":
					_do_slash()
				else:
					_do_jump()
		State.JUMP:
			if velocity.y >= 0.0:
				state = State.FALL
		State.FALL:
			if is_on_floor():
				_do_slam()
		State.SLASH, State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
			if _timer <= 0.0:
				_to_idle()
		State.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
			tint = Color(0.7, 0.7, 1.0)
			if sprite:
				sprite.rotation = sin(_timer * 20.0) * 0.08
			if _timer <= 0.0:
				if sprite:
					sprite.rotation = 0.0
				_to_idle()
	global_position.x = clampf(global_position.x, arena_min_x, arena_max_x)


## Boss height when standing on the target's floor.
func _goal_y(target: Node2D) -> float:
	return target.global_position.y + 44.0 - feet_offset


## Passes down through one-way ledges until level with the target's floor.
func _start_drop(goal_y: float) -> void:
	state = State.DROP
	_drop_goal_y = goal_y
	_timer = 2.5
	collision_mask = 0


## Watchdog: a jump or fall that never finds the floor (ledge edge, wall corner) used to leave the
## boss frozen in JUMP/FALL forever. After 2.2 s in the air it recovers and falls back to normal play.
func _watch_airborne(delta: float) -> void:
	if is_on_floor():
		_air_time = 0.0
		return
	_air_time += delta
	if _air_time > 2.2 and (state == State.JUMP or state == State.FALL):
		_air_time = 0.0
		velocity.x = 0.0
		state = State.RECOVER
		_timer = recover_time
		if slam_marker:
			slam_marker.visible = false
		if warning:
			warning.visible = false


## Safety net: if the boss ever falls out of the arena, put it back on the spawn floor.
func _respawn() -> void:
	global_position = Vector2(clampf(_spawn_position.x, arena_min_x, arena_max_x), _spawn_position.y)
	velocity = Vector2.ZERO
	_air_time = 0.0
	_to_idle()


## Leaps from where he is in a jump arc and lands on the target, coming in from the side he was on.
## The landing spot shows the slam marker, and the landing hits like a slam.
func _teleport_onto(target: Node2D) -> void:
	var from_x := global_position.x
	var side := signf(from_x - target.global_position.x)
	if side == 0.0:
		side = 1.0
	var land_x := clampf(target.global_position.x + side * 40.0, arena_min_x, arena_max_x)
	var land_y := _goal_y(target)
	if not _has_floor_at(land_x, land_y):
		_teleport_cd = 1.0
		return
	var dy := land_y - global_position.y
	var rise := clampf(maxf(120.0, 60.0 - dy), 120.0, 260.0)
	var vy := -sqrt(2.0 * gravity * rise)
	var disc := maxf(vy * vy + 2.0 * gravity * dy, 0.0)
	var flight := (-vy + sqrt(disc)) / gravity
	velocity.y = vy
	velocity.x = clampf((land_x - from_x) / maxf(flight, 0.2), -1100.0, 1100.0)
	state = State.JUMP
	_teleport_cd = teleport_cooldown
	_slam_target_x = land_x
	_slam_target_y = target.global_position.y + 44.0
	if slam_marker:
		slam_marker.visible = true
		slam_marker.global_position = Vector2(_slam_target_x, _slam_target_y)
	if warning:
		warning.visible = false
	Sfx.play("swing")


## True when there is solid ground under x near y (so a leap never lands in a pit or in the air).
func _has_floor_at(x: float, y: float) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, y - 200.0), Vector2(x, y + 160.0), 1)
	q.exclude = [get_rid()]
	return not space.intersect_ray(q).is_empty()


func _begin_windup(target: Node2D) -> void:
	_next_attack = "slam" if randf() < slam_chance else "slash"
	if illusion_chance > 0.0 and randf() < illusion_chance:
		_spawn_illusion()
	state = State.WINDUP
	_timer = telegraph_time
	if warning:
		warning.visible = true
	Sfx.play("warning")
	if _next_attack == "slam":
		_slam_target_x = clampf(target.global_position.x, arena_min_x, arena_max_x)
		_slam_target_y = target.global_position.y + 44.0
		if slam_marker:
			slam_marker.visible = true
			slam_marker.global_position = Vector2(_slam_target_x, _slam_target_y)
	say_line(lines_combat, "combat", 1.6)


func _do_slash() -> void:
	state = State.RECOVER
	_timer = recover_time
	_spawn_wave(sword_wave_scene, facing, Vector2(60.0 * facing, feet_offset - 45.0))
	velocity.x = facing * 200.0
	Sfx.play("swing")


func _do_jump() -> void:
	state = State.JUMP
	var start_y: float = global_position.y
	var goal_y: float = _slam_target_y - feet_offset
	var dy: float = goal_y - start_y
	var rise: float = clampf(maxf(150.0, 60.0 - dy), 150.0, 230.0)
	var vy: float = -sqrt(2.0 * gravity * rise)
	var disc: float = maxf(vy * vy + 2.0 * gravity * dy, 0.0)
	var flight: float = (-vy + sqrt(disc)) / gravity
	velocity.y = vy
	velocity.x = clampf((_slam_target_x - global_position.x) / maxf(flight, 0.2), -1000.0, 1000.0)
	_notify_player("boss_smash")


func _do_slam() -> void:
	state = State.RECOVER
	_timer = recover_time
	velocity.x = 0.0
	if slam_marker:
		slam_marker.visible = false
	_spawn_wave(shockwave_scene, 1, Vector2(30.0, feet_offset - 16.0))
	_spawn_wave(shockwave_scene, -1, Vector2(-30.0, feet_offset - 16.0))
	Sfx.play("boom")
	var p := get_tree().get_first_node_in_group("player") as PlayerBase
	if p:
		p.shake_camera(14.0, 0.35)


func _spawn_wave(scene: PackedScene, dir: int, offset: Vector2) -> void:
	if scene == null:
		return
	var w := scene.instantiate() as BossWave
	w.direction = dir
	w.boss = self
	get_parent().add_child(w)
	w.global_position = global_position + offset


## A faded copy of Big Boss that drifts off and vanishes: the "illusion figure" from the comic.
func _spawn_illusion() -> void:
	if not sprite or not get_parent():
		return
	var ghost := Sprite2D.new()
	var src := sprite as Sprite2D
	if src:
		ghost.texture = src.texture
		ghost.hframes = src.hframes
		ghost.vframes = src.vframes
		ghost.frame = src.frame
		ghost.flip_h = src.flip_h
		ghost.scale = src.scale
	ghost.modulate = Color(0.8, 0.5, 1.0, 0.55)
	ghost.top_level = true
	get_parent().add_child(ghost)
	ghost.global_position = global_position + Vector2(randf_range(-90.0, 90.0), 0.0)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "global_position:x", ghost.global_position.x + 60.0 * (1.0 if randf() < 0.5 else -1.0), 1.0)
	tw.parallel().tween_property(ghost, "modulate:a", 0.0, 1.0)
	tw.tween_callback(ghost.queue_free)


func _to_idle() -> void:
	state = State.IDLE
	if warning:
		warning.visible = false
	if slam_marker:
		slam_marker.visible = false
	_timer = randf_range(idle_time_min, idle_time_max)


func stagger() -> void:
	if disabled or state == State.STAGGER or state == State.STORY:
		return
	state = State.STAGGER
	_timer = stagger_time
	if warning:
		warning.visible = false
	if slam_marker:
		slam_marker.visible = false
	say_line(lines_stagger, "stagger", 2.0, true)


## Called by a wave when Pink Girl (or another target) blocks it: a counter.
func on_attack_blocked() -> void:
	stagger()


func on_attack_hit(target: Node) -> void:
	if target is PlayerBase:
		(target as PlayerBase).react("boss_hit")
	attack_landed.emit(target)


func take_hit(amount: int, from_position: Vector2, attacker: Node = null, kind: String = "melee") -> void:
	if disabled:
		return
	if ignore_player and attacker is PlayerBase:
		return
	if state == State.RECOVER and attacker is PlayerBase:
		stagger()
		(attacker as PlayerBase).react("boss_parry")
	super.take_hit(amount, from_position, attacker, kind)


func can_damage_player(_p: PlayerBase) -> bool:
	return not ignore_player


func _notify_player(key: String) -> void:
	if ignore_player:
		return
	var p := get_tree().get_first_node_in_group("player") as PlayerBase
	if p:
		p.react(key)
