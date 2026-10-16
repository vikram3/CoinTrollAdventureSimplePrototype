class_name SkullTopDown
extends EnemyBase
## Top-down skull for the checkpoint 01 maze. Walks a fixed path of points
## (relative to its start) and briefly follows CT when he gets close.

@export var patrol_points: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(192, 0)])
@export var patrol_speed: float = 91.0
@export var chase_speed: float = 136.5
@export var detect_range: float = 170.0
@export var leash_range: float = 300.0
@export_group("Barks")
@export var lines_detected: PackedStringArray = ["Hey! What do you think you're doing?", "Who goes there?", "A troll? In MY maze?"]
@export var lines_patrol: PackedStringArray = ["Hedges, hedges, hedges...", "Quiet night.", "Did I leave the crypt unlocked?"]
@export var lines_give_up: PackedStringArray = ["Hmph. Back to my rounds.", "Not worth it.", "He'll get lost anyway."]

var _origin: Vector2 = Vector2.ZERO
var _index: int = 1
var _chasing: bool = false


func _ready() -> void:
	use_gravity = false
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_origin = global_position
	if patrol_points.size() < 2:
		patrol_points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])


func _enemy_process(_delta: float) -> void:
	var p := get_player()
	var chase := false
	if p:
		var d := global_position.distance_to(p.global_position)
		if d < detect_range and global_position.distance_to(_origin) < leash_range:
			chase = true
	if chase and not _chasing:
		say_line(lines_detected, "detected", 2.2, true)
	elif not chase and _chasing:
		say_line(lines_give_up, "give_up", 2.0, true)
	_chasing = chase
	var target: Vector2 = _origin + patrol_points[_index]
	if chase:
		target = p.global_position
	var to := target - global_position
	if not chase and to.length() < 6.0:
		_index = (_index + 1) % patrol_points.size()
	var spd := chase_speed if chase else patrol_speed
	velocity = to.normalized() * spd if to.length() > 1.0 else Vector2.ZERO
	if absf(velocity.x) > 1.0:
		face(int(signf(velocity.x)))
	if randf() < 0.001:
		say_line(lines_patrol, "patrol")
