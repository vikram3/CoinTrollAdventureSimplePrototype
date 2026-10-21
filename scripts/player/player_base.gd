class_name PlayerBase
extends CharacterBody2D
## Shared player logic: health, damage, knockback, death and speech.
## CT (top-down and platformer) and Alex extend this.

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 5
@export var invulnerable_time: float = 1.0
@export var stun_time: float = 0.5
@export var gravity: float = 1900.0
@export var max_fall_speed: float = 1100.0
@export var bubble_height: float = 64.0
@export_group("Reaction lines")
@export var react_boss_smash: PackedStringArray = ["WHOA, the floor!", "That nearly flattened my coins!", "Jump, jump, JUMP!"]
@export var react_boss_parry: PackedStringArray = ["Ha! Missed me!", "Did that just work?!", "Take that, big guy!"]
@export var react_boss_hit: PackedStringArray = ["OW! My suit!", "Not the face!", "He hits like a tax collector!"]

var health: int = 0
var facing: int = 1
var controls_enabled: bool = true
var invincible: bool = false
var is_dead: bool = false
## Set by HideSpot while CT stands inside one; hidden CT is ignored and can't be hurt.
var can_hide: bool = false
var is_hidden: bool = false
var death_message: String = ""
## Extra horizontal push from the world (used by the tilting ship).
var push_x: float = 0.0

var _invuln: float = 0.0
var _stun: float = 0.0
var _knock_timer: float = 0.0
var _last_knocker: String = ""
var _last_knock_time: float = -100.0
var _picker := SpeechPicker.new()

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D


func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)


const COIN_SCENE := preload("res://scenes/objects/coin.tscn")


## How far a spilled coin falls with no floor under it. 0 means it falls until it lands on a floor.
func coin_drop_limit() -> float:
	return 0.0


## Spill coins out of CT when he loses them. Each one pops out and can be picked up again after a moment.
func _drop_coins(amount: int) -> void:
	var parent := get_parent()
	if parent == null:
		return
	for i in amount:
		var c := COIN_SCENE.instantiate() as Coin
		c.falling = true
		c.max_fall = coin_drop_limit()
		c.pickup_delay = 0.9
		c.drop_impulse = Vector2(randf_range(-170.0, 170.0), randf_range(-330.0, -220.0))
		parent.add_child(c)
		c.global_position = global_position + Vector2(randf_range(-8.0, 8.0), -18.0)


func take_damage(amount: int, from_position: Vector2 = Vector2.INF, knockback: Vector2 = Vector2(260, -280), source: String = "") -> bool:
	if is_dead or invincible or is_hidden or _invuln > 0.0 or amount <= 0:
		return false
	health = maxi(health - amount, 0)
	_invuln = invulnerable_time
	_stun = stun_time
	_apply_knockback(from_position, knockback, source)
	Sfx.play("hit")
	shake_camera(8.0, 0.25)
	health_changed.emit(health, max_health)
	var lost := GameState.lose_share_of_coins()
	if lost > 0:
		say("Dropped %d coins!" % lost, 2.0)
		_drop_coins(lost)
	if health <= 0:
		die()
	return true


func kill(message: String = "") -> void:
	if is_dead or invincible:
		return
	death_message = message
	health = 0
	health_changed.emit(health, max_health)
	shake_camera(12.0, 0.3)
	die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	controls_enabled = false
	died.emit()


func heal_full() -> void:
	health = max_health
	health_changed.emit(health, max_health)


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled


## Overridden by Alex, whose shield blocks attacks from the front.
func is_blocking_from(_pos: Vector2) -> bool:
	return false


func was_recently_knocked_by(source: String, window: float = 3.0) -> bool:
	return _last_knocker == source and (_now() - _last_knock_time) <= window


func shake_camera(strength: float, duration: float) -> void:
	if camera and camera.has_method("shake"):
		camera.call("shake", strength, duration)


func say(text: String, duration: float = 2.5) -> void:
	SpeechBubble.say(self, text, duration, bubble_height)


func react(key: String) -> void:
	var pool: PackedStringArray
	match key:
		"boss_smash":
			pool = react_boss_smash
		"boss_parry":
			pool = react_boss_parry
		"boss_hit":
			pool = react_boss_hit
		_:
			return
	say(_picker.pick(key, pool), 2.0)


func play_anim(anim_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)


func _apply_knockback(from_position: Vector2, knockback: Vector2, source: String) -> void:
	if source != "":
		_last_knocker = source
		_last_knock_time = _now()
	if from_position == Vector2.INF:
		return
	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = float(-facing)
	velocity = Vector2(dir * knockback.x, knockback.y)
	_knock_timer = 0.25


func _tick_timers(delta: float) -> void:
	if _stun > 0.0:
		_stun = maxf(_stun - delta, 0.0)
		sprite.modulate = Color(1.0, 0.7, 0.35) if _stun > 0.0 else Color.WHITE
	if _invuln > 0.0:
		_invuln -= delta
		sprite.modulate.a = 0.35 if int(_invuln * 20.0) % 2 == 0 else 1.0
		if _invuln <= 0.0:
			sprite.modulate.a = 1.0


## Hold DOWN inside a hiding spot to hide. Hidden CT stays still.
func update_hiding() -> void:
	var want: bool = can_hide and controls_enabled and not is_dead and is_on_floor() and Input.is_action_pressed("move_down")
	if want != is_hidden:
		is_hidden = want
		sprite.modulate.a = 0.35 if is_hidden else 1.0
	if is_hidden:
		velocity.x = 0.0


## Enemies ask this directly each time they look for CT, so a hiding check can't lag a frame behind.
func is_hidden_now() -> bool:
	return is_hidden


func is_stunned() -> bool:
	return _stun > 0.0


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
