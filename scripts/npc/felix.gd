class_name Felix
extends CharacterBody2D
## Felix (Flex): follows CT, gives tips and idle comments, never fights.

@export var follow_offset: float = 90.0
@export var run_speed: float = 430.0
@export var jump_velocity: float = -760.0
@export var gravity: float = 1900.0
@export var teleport_distance: float = 650.0
@export var bubble_height: float = 62.0
@export_group("Lines")
@export var opening_lines: PackedStringArray = []
@export var opening_interval: float = 4.0
@export var idle_lines: PackedStringArray = ["Nice forest, huh? Mostly nice.", "You always this shiny?", "I hear coins jingling. Is that you?", "Stay close, troll."]
@export var idle_interval_min: float = 8.0
@export var idle_interval_max: float = 13.0
@export var warning_lines: PackedStringArray = ["Heads up, enemy ahead!", "Careful!", "Watch out!"]

var _talk_timer: float = 1.5
var _opening_index: int = 0
var _warn_cd: float = 4.0
var _picker := SpeechPicker.new()

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("companion")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	var p := get_tree().get_first_node_in_group("player") as PlayerBase
	if p:
		_follow(p, delta)
		_talk(delta)
		_warn(delta, p)
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	move_and_slide()


func _follow(p: PlayerBase, delta: float) -> void:
	var target_x := p.global_position.x - p.facing * follow_offset
	var dx := target_x - global_position.x
	if absf(dx) > 24.0:
		velocity.x = move_toward(velocity.x, signf(dx) * run_speed, 2600.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 2600.0 * delta)
	var to_player := p.global_position.x - global_position.x
	if absf(to_player) > 4.0:
		sprite.flip_h = to_player < 0.0
	var player_above := p.global_position.y < global_position.y - 90.0 and p.is_on_floor() and absf(to_player) < 260.0
	if is_on_floor() and ((is_on_wall() and absf(dx) > 24.0) or player_above):
		velocity.y = jump_velocity
	if global_position.distance_to(p.global_position) > teleport_distance or global_position.y > p.global_position.y + 600.0:
		global_position = p.global_position + Vector2(-p.facing * follow_offset, -10.0)
		velocity = Vector2.ZERO


func _talk(delta: float) -> void:
	_talk_timer -= delta
	if _talk_timer > 0.0:
		return
	if _opening_index < opening_lines.size():
		say(opening_lines[_opening_index], 3.4)
		_opening_index += 1
		_talk_timer = opening_interval
	elif not idle_lines.is_empty():
		say(_picker.pick("idle", idle_lines), 2.8)
		_talk_timer = randf_range(idle_interval_min, idle_interval_max)
	else:
		_talk_timer = 5.0


func _warn(delta: float, p: PlayerBase) -> void:
	_warn_cd -= delta
	if _warn_cd > 0.0 or warning_lines.is_empty():
		return
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as EnemyBase
		if e and not e.disabled and e.global_position.distance_to(p.global_position) < 320.0:
			say(_picker.pick("warn", warning_lines), 2.0)
			_warn_cd = 9.0
			_talk_timer = maxf(_talk_timer, 2.5)
			return


func say(text: String, duration: float = 2.5) -> void:
	SpeechBubble.say(self, text, duration, bubble_height)
