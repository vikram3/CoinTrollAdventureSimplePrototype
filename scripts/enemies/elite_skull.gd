class_name EliteSkull
extends EnemyBase
## Elite Skull: guards its post, chases, charges in corridors, attacks,
## retreats, and searches when it loses CT.

enum State { GUARD, CHASE, WINDUP, CHARGE, RETREAT, SEARCH }

@export var move_speed: float = 195.0
@export var charge_speed: float = 624.0
@export var detect_range: float = 380.0
@export var lose_range: float = 560.0
@export var charge_range: float = 260.0
@export var windup_time: float = 0.45
@export var charge_time: float = 0.45
@export var retreat_time: float = 0.6
@export var leash_distance: float = 420.0
@export_group("Lines")
@export var lines_chase: PackedStringArray = ["You're mine, troll!", "Elite guard, coming through!", "No one passes!"]
@export var lines_charge: PackedStringArray = ["CHAAARGE!", "Out of my corridor!", "Here I come!"]
@export var lines_attack: PackedStringArray = ["Take that!", "Ha! Too slow!", "Elite strike!"]
@export var lines_retreat: PackedStringArray = ["Regroup!", "Tactical step back.", "Just catching my breath..."]
@export var lines_search: PackedStringArray = ["Where are you hiding?", "I know you're here...", "Come out, coin thief!"]

var state: State = State.GUARD
var _timer: float = 0.0
var _origin_x: float = 0.0
var _charge_cd: float = 0.0


func _ready() -> void:
	super._ready()
	_origin_x = global_position.x
	ensure_edge_ray()


func _enemy_process(delta: float) -> void:
	apply_gravity(delta)
	_timer -= delta
	_charge_cd -= delta
	var p := get_player()
	var dist := INF
	var dir_to_p := 0
	if p:
		dist = global_position.distance_to(p.global_position)
		dir_to_p = int(signf(p.global_position.x - global_position.x))
	tint = Color.WHITE
	match state:
		State.GUARD:
			var home := signf(_origin_x - global_position.x)
			if absf(_origin_x - global_position.x) > 8.0:
				velocity.x = home * move_speed * 0.5
				face(int(home))
			else:
				velocity.x = 0.0
			if dist < detect_range and player_on_level(p):
				state = State.CHASE
				say_line(lines_chase, "chase", 2.0, true)
		State.CHASE:
			if dist > lose_range or absf(global_position.x - _origin_x) > leash_distance or not player_on_level(p):
				state = State.SEARCH
				_timer = 1.8
				say_line(lines_search, "search", 2.0, true)
			else:
				if dir_to_p != 0:
					face(dir_to_p)
				velocity.x = facing * move_speed
				if at_edge():
					velocity.x = 0.0
				if dist < charge_range and _charge_cd <= 0.0:
					state = State.WINDUP
					_timer = windup_time
					say_line(lines_charge, "charge", 1.6, true)
					Sfx.play("warning")
		State.WINDUP:
			velocity.x = 0.0
			tint = Color(1.0, 0.85, 0.3)
			if sprite:
				sprite.position.x = randf_range(-2.0, 2.0)
			if _timer <= 0.0:
				if sprite:
					sprite.position.x = 0.0
				state = State.CHARGE
				_timer = charge_time
		State.CHARGE:
			velocity.x = facing * charge_speed
			if _timer <= 0.0 or is_on_wall() or at_edge():
				state = State.RETREAT
				_timer = retreat_time
				_charge_cd = 1.6
				say_line(lines_retreat, "retreat", 1.6)
		State.RETREAT:
			velocity.x = -facing * move_speed * 0.8
			if _timer <= 0.0:
				state = State.CHASE
		State.SEARCH:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if dist < detect_range and absf(global_position.x - _origin_x) < leash_distance and player_on_level(p):
				state = State.CHASE
			elif _timer <= 0.0:
				state = State.GUARD


func _on_hit_player(_p: PlayerBase) -> void:
	say_line(lines_attack, "attack", 1.6, true)
