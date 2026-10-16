class_name WaveSpawner
extends Node2D
## Spawns enemy waves from its Marker2D children. A new wave starts when the
## previous one is cleared. Skulls can march toward a target x; if
## fail_on_reach is set, a skull reaching it fails the checkpoint.

signal wave_started(index: int)
signal wave_cleared(index: int)
signal all_waves_cleared

@export var enemy_scene: PackedScene
@export var wave_counts: PackedInt32Array = [2, 3, 4]
## When true, wave N uses marker N. Otherwise enemies are spread across markers.
@export var one_marker_per_wave: bool = false
@export var spread: float = 70.0
@export var start_delay: float = 1.5
@export var delay_between_waves: float = 2.5
@export var speed_bonus_per_wave: float = 12.0
@export var march: bool = false
@export var march_target_x: float = 0.0
@export var fail_on_reach: bool = false
@export var fail_message: String = "The skulls got through!"
@export var detect_range_override: float = -1.0

var current_wave: int = -1
var finished: bool = false
var _alive: int = 0


func _ready() -> void:
	_start_after(start_delay, 0)


func _start_after(delay: float, index: int) -> void:
	await get_tree().create_timer(delay, false).timeout
	if is_inside_tree():
		_start_wave(index)


func _markers() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	for c in get_children():
		if c is Marker2D:
			result.append(c as Marker2D)
	return result


func _start_wave(index: int) -> void:
	var markers := _markers()
	if markers.is_empty() or enemy_scene == null or index >= wave_counts.size():
		return
	current_wave = index
	var count := wave_counts[index]
	for k in count:
		var marker: Marker2D = markers[index % markers.size()] if one_marker_per_wave else markers[k % markers.size()]
		var e := enemy_scene.instantiate() as EnemyBase
		if e is Skull:
			var s := e as Skull
			s.march_mode = march
			s.march_target_x = march_target_x
			s.patrol_speed += speed_bonus_per_wave * index
			s.chase_speed += speed_bonus_per_wave * index
			if detect_range_override > 0.0:
				s.detect_range = detect_range_override
				s.lose_range = detect_range_override * 1.6
			s.reached_target.connect(_on_reached)
		get_parent().add_child(e)
		var offset_x := 0.0
		if one_marker_per_wave:
			offset_x = (float(k) - float(count - 1) * 0.5) * spread
		else:
			offset_x = float(k / markers.size()) * spread
		e.global_position = marker.global_position + Vector2(offset_x, 0.0)
		e.defeated.connect(_on_enemy_defeated)
		_alive += 1
	wave_started.emit(index)
	var lvl := get_tree().get_first_node_in_group("level") as Level
	if lvl:
		lvl.announce("Wave %d / %d" % [index + 1, wave_counts.size()])


func _on_enemy_defeated(_enemy: EnemyBase) -> void:
	_alive -= 1
	if _alive > 0 or finished:
		return
	wave_cleared.emit(current_wave)
	if current_wave + 1 < wave_counts.size():
		_start_after(delay_between_waves, current_wave + 1)
	else:
		finished = true
		all_waves_cleared.emit()
		var lvl := get_tree().get_first_node_in_group("level") as Level
		if lvl:
			lvl.announce("All waves cleared!")


func _on_reached(_skull: Skull) -> void:
	if not fail_on_reach:
		return
	var lvl := get_tree().get_first_node_in_group("level") as Level
	if lvl:
		lvl.fail(fail_message)
