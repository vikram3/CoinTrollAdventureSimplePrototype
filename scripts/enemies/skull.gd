class_name Skull
extends EnemyBase
## Skull: patrols a fixed path and chases CT when close. Can also march toward
## a target x (used by the checkpoint 05 reinforcement waves).

signal reached_target(skull: Skull)

enum State { PATROL, CHASE, SEARCH }

@export var patrol_speed: float = 91.0
@export var chase_speed: float = 195.0
@export var patrol_distance: float = 160.0
@export var detect_range: float = 260.0
@export var lose_range: float = 420.0
@export var march_mode: bool = false
@export var march_target_x: float = 0.0
@export_group("Barks")
@export var lines_detected: PackedStringArray = ["Hey! What do you think you're doing?", "Intruder!", "I see you, green bean!", "Who let the troll in?"]
@export var lines_patrol: PackedStringArray = ["Left, right, left, right...", "Another quiet night.", "I miss having skin.", "Hmm hmm hmm..."]
@export var lines_chase: PackedStringArray = ["Get back here!", "You can't outrun bones!", "Rattle rattle!", "Stop, thief!"]
@export var lines_attack: PackedStringArray = ["Gotcha!", "Bonk!", "Skull bash!"]
@export var lines_lost: PackedStringArray = ["Where'd he go?", "Huh? Lost him.", "Was that a troll?"]
@export var lines_give_up: PackedStringArray = ["Forget it, back to patrol.", "Not paid enough for this.", "Eh, he'll be back."]

var state: State = State.PATROL
var _origin_x: float = 0.0
var _search_time: float = 0.0
var _turn_cd: float = 0.0
var _reached: bool = false


func _ready() -> void:
	super._ready()
	_origin_x = global_position.x
	ensure_edge_ray()


func _enemy_process(delta: float) -> void:
	apply_gravity(delta)
	_turn_cd -= delta
	var p := get_player()
	var dist := INF
	if p:
		dist = global_position.distance_to(p.global_position)
	match state:
		State.PATROL:
			if march_mode:
				_march()
			else:
				_patrol()
			if randf() < 0.0015:
				say_line(lines_patrol, "patrol")
			if dist < detect_range and player_on_level(p):
				state = State.CHASE
				say_line(lines_detected, "detected", 2.2, true)
		State.CHASE:
			if p == null or dist > lose_range or not player_on_level(p):
				state = State.SEARCH
				_search_time = 1.6
				say_line(lines_lost, "lost", 2.0, true)
			else:
				var dir := int(signf(p.global_position.x - global_position.x))
				if dir != 0:
					face(dir)
				velocity.x = facing * chase_speed
				if at_edge():
					velocity.x = 0.0
				if randf() < 0.003:
					say_line(lines_chase, "chase")
		State.SEARCH:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			_search_time -= delta
			if dist < detect_range and player_on_level(p):
				state = State.CHASE
			elif _search_time <= 0.0:
				state = State.PATROL
				say_line(lines_give_up, "give_up", 2.0, true)


func _patrol() -> void:
	if global_position.x > _origin_x + patrol_distance:
		face(-1)
	elif global_position.x < _origin_x - patrol_distance:
		face(1)
	if (is_on_wall() or at_edge()) and _turn_cd <= 0.0:
		face(-facing)
		_turn_cd = 0.4
	velocity.x = facing * patrol_speed


func _march() -> void:
	var dir := int(signf(march_target_x - global_position.x))
	if dir != 0:
		face(dir)
	velocity.x = facing * patrol_speed
	if not _reached and absf(march_target_x - global_position.x) < 12.0:
		_reached = true
		reached_target.emit(self)


func _on_hit_player(_p: PlayerBase) -> void:
	say_line(lines_attack, "attack", 1.8, true)
