class_name BigBird
extends EnemyBase
## Big Bird (Sacavuelo): throws boomerangs that track the player, is weak at
## close range and hops away. Projectile pressure rises the longer the fight lasts.

@export var boomerang_scene: PackedScene
@export var throw_interval_start: float = 2.6
@export var throw_interval_min: float = 1.0
@export var pressure_ramp: float = 0.025
@export var max_boomerangs_start: int = 1
@export var max_boomerangs_late: int = 2
@export var late_fight_time: float = 30.0
@export var close_range: float = 230.0
@export var hop_speed: float = 442.0
@export var hop_cooldown: float = 2.2
@export var arena_min_x: float = -100000.0
@export var arena_max_x: float = 100000.0
@export_group("Lines")
@export var lines_throw: PackedStringArray = ["Catch!", "Boomerang time!", "Comes back every time!"]
@export var lines_close: PackedStringArray = ["Too close! Back off!", "Personal space!", "Hey, no fair!"]
@export var lines_deflect: PackedStringArray = ["Arrows? Cute.", "Swat!", "Try harder, shield boy."]

var _throw_cd: float = 1.5
var _hop_cd: float = 0.0
var _elapsed: float = 0.0
var _active: int = 0


func _enemy_process(delta: float) -> void:
	apply_gravity(delta)
	_elapsed += delta
	_throw_cd -= delta
	_hop_cd -= delta
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	var p := get_player()
	if p == null:
		return
	var dx := p.global_position.x - global_position.x
	if absf(dx) > 1.0:
		face(int(signf(dx)))
	var dist := global_position.distance_to(p.global_position)
	if dist < close_range:
		tint = Color(1.0, 0.85, 0.85)
		if _hop_cd <= 0.0 and is_on_floor():
			_hop_cd = hop_cooldown
			var away := -signf(dx) if dx != 0.0 else 1.0
			if (away < 0.0 and global_position.x < arena_min_x + 150.0) or (away > 0.0 and global_position.x > arena_max_x - 150.0):
				away = -away
			velocity = Vector2(away * hop_speed, -560.0)
			say_line(lines_close, "close", 1.6)
	else:
		tint = Color.WHITE
	var max_active := max_boomerangs_late if _elapsed > late_fight_time else max_boomerangs_start
	if _throw_cd <= 0.0 and _active < max_active and dist > close_range * 0.6:
		_throw_cd = maxf(throw_interval_start - _elapsed * pressure_ramp, throw_interval_min)
		_throw(p)
	global_position.x = clampf(global_position.x, arena_min_x, arena_max_x)


func _throw(p: PlayerBase) -> void:
	if boomerang_scene == null:
		return
	var b := boomerang_scene.instantiate() as Boomerang
	b.thrower = self
	b.target = p
	get_parent().add_child(b)
	b.global_position = global_position + Vector2(facing * 40.0, -30.0)
	b.launch()
	_active += 1
	say_line(lines_throw, "throw", 1.4)
	Sfx.play("swing")


func boomerang_returned() -> void:
	_active = maxi(_active - 1, 0)


func take_hit(amount: int, from_position: Vector2, attacker: Node = null, kind: String = "melee") -> void:
	if disabled:
		return
	if kind == "arrow" and attacker is Node2D:
		var shooter_dist := (attacker as Node2D).global_position.distance_to(global_position)
		if shooter_dist > close_range * 1.6:
			Sfx.play("block")
			say_line(lines_deflect, "deflect", 1.4)
			return
	super.take_hit(amount, from_position, attacker, kind)
