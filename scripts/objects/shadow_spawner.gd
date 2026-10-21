class_name ShadowSpawner
extends Node2D
## Picks one of its Marker2D children, flashes a warning there for 2 seconds,
## then a shadow avatar teleports in with a shockwave.

signal burst_finished(hit_player: bool)

@export var avatar_scene: PackedScene
@export var interval: float = 3.4
@export var first_delay: float = 2.0
@export var max_active: int = 3
## Burst right beside CT (instead of at the marker points), so the shockwave lands on him.
@export var burst_near_player: bool = true
@export var near_min: float = 120.0
@export var near_max: float = 220.0

var _cd: float = 0.0
var _active: int = 0
var _last_marker: int = -1


func _ready() -> void:
	_cd = first_delay


func _physics_process(delta: float) -> void:
	_cd -= delta
	if _cd <= 0.0:
		_cd = interval
		if _active < max_active:
			_spawn()


func _spawn() -> void:
	if avatar_scene == null:
		return
	var spawn_pos := Vector2.ZERO
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if burst_near_player and player != null:
		var side := 1.0 if randf() < 0.5 else -1.0
		spawn_pos = player.global_position + Vector2(side * randf_range(near_min, near_max), randf_range(-90.0, -20.0))
	else:
		var markers: Array[Node2D] = []
		for c in get_children():
			if c is Marker2D:
				markers.append(c as Node2D)
		if markers.is_empty():
			return
		var idx := randi() % markers.size()
		if idx == _last_marker and markers.size() > 1:
			idx = (idx + 1) % markers.size()
		_last_marker = idx
		spawn_pos = markers[idx].global_position
	var a := avatar_scene.instantiate() as ShadowAvatar
	get_parent().add_child(a)
	a.global_position = spawn_pos
	_active += 1
	a.burst_finished.connect(_on_burst)
	a.tree_exited.connect(_on_avatar_gone)


func _on_burst(_avatar: ShadowAvatar, hit_player: bool) -> void:
	burst_finished.emit(hit_player)


func _on_avatar_gone() -> void:
	_active = maxi(_active - 1, 0)
