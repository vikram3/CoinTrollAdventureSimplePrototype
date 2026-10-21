class_name Charger
extends EnemyBase
## Straight-line charging enemy: Horn, Bull and Minor bull.
## Rests, telegraphs (wind-up), charges, and turns after a collision.

signal charge_started(charger: Charger)
signal charge_finished(charger: Charger)

enum State { REST, WINDUP, CHARGE, STUN }

@export var charge_speed: float = 676.0
@export var windup_time: float = 0.7
@export var rest_time: float = 1.5
@export var stun_time: float = 0.6
@export var detect_range: float = 1100.0
@export var max_charge_time: float = 3.5
@export var stop_at_edges: bool = true
@export var min_x: float = -100000.0
@export var max_x: float = 100000.0
@export_group("Lines")
@export var lines_charge: PackedStringArray = []

var state: State = State.REST
var _timer: float = 0.0
var _charge_dir: int = 1

@onready var warning: CanvasItem = get_node_or_null("Warning") as CanvasItem


func _ready() -> void:
	charge_speed *= GameState.speed_mult()
	super._ready()
	ensure_edge_ray()
	edge_ray_ahead = 40.0
	_timer = rest_time * randf_range(0.6, 1.2)
	if warning:
		warning.visible = false


func _enemy_process(delta: float) -> void:
	apply_gravity(delta)
	_timer -= delta
	var p := get_player()
	match state:
		State.REST:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			tint = Color.WHITE
			if p:
				var d := int(signf(p.global_position.x - global_position.x))
				if d != 0:
					face(d)
			if _timer <= 0.0 and player_on_level(p) and global_position.distance_to(p.global_position) < detect_range:
				_begin_windup()
		State.WINDUP:
			velocity.x = 0.0
			tint = Color(1.0, 0.75, 0.3) if int(_timer * 12.0) % 2 == 0 else Color.WHITE
			if sprite:
				sprite.position.x = randf_range(-3.0, 3.0)
			if _timer <= 0.0:
				_begin_charge()
		State.CHARGE:
			velocity.x = _charge_dir * charge_speed
			var hit_bound := (global_position.x <= min_x and _charge_dir < 0) or (global_position.x >= max_x and _charge_dir > 0)
			if is_on_wall() or hit_bound or _timer <= 0.0 or (stop_at_edges and at_edge()):
				_end_charge()
		State.STUN:
			velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
			if _timer <= 0.0:
				state = State.REST
				_timer = rest_time


func _begin_windup() -> void:
	state = State.WINDUP
	_timer = windup_time
	if warning:
		warning.visible = true
	say_line(lines_charge, "charge", 1.5)
	Sfx.play("warning")


func _begin_charge() -> void:
	state = State.CHARGE
	_timer = max_charge_time
	_charge_dir = facing
	tint = Color.WHITE
	if sprite:
		sprite.position.x = 0.0
	if warning:
		warning.visible = false
	charge_started.emit(self)


func _end_charge() -> void:
	state = State.STUN
	_timer = stun_time
	if is_on_wall():
		face(-facing)
		var p := get_player()
		if p and global_position.distance_to(p.global_position) < 900.0:
			p.shake_camera(5.0, 0.2)
	velocity.x = 0.0
	global_position.x = clampf(global_position.x, min_x, max_x)
	charge_finished.emit(self)


func is_charging() -> bool:
	return state == State.CHARGE
