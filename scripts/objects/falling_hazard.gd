class_name FallingHazard
extends Node2D
## Triggered falling hazard (rocks, logs, stones, hedge traps): hangs in place,
## shakes with a warning when CT passes below its trigger, then falls.
## Breaks on landing and can respawn.

enum State { IDLE, SHAKE, FALL, BROKEN }

@export var texture: Texture2D
@export var trigger_size: Vector2 = Vector2(160, 900)
@export var trigger_offset_x: float = 0.0
@export var shake_time: float = 0.55
@export var fall_gravity: float = 1700.0
@export var damage: int = 1
@export var lethal: bool = false
@export var knockback: Vector2 = Vector2(200, -200)
@export var respawn_time: float = -1.0
@export var hazard_name: String = "rock"
@export var debris_color: Color = Color(0.55, 0.45, 0.35)

var state: State = State.IDLE
var _timer: float = 0.0
var _vy: float = 0.0
var _start: Vector2 = Vector2.ZERO

@onready var body: Area2D = $Body
@onready var body_sprite: Sprite2D = $Body/Sprite
@onready var trigger: Area2D = $Trigger
@onready var warning: CanvasItem = get_node_or_null("Warning") as CanvasItem


func _ready() -> void:
	if respawn_time > 0.0:
		respawn_time *= GameState.hazard_timer_mult()
	if texture:
		body_sprite.texture = texture
	_start = body.position
	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	var cs := $Trigger/CollisionShape2D as CollisionShape2D
	cs.shape = shape
	cs.position = Vector2(trigger_offset_x, trigger_size.y * 0.5)
	body.body_entered.connect(_on_body_hit)
	if warning:
		warning.visible = false


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			for b in trigger.get_overlapping_bodies():
				if b is PlayerBase:
					_begin_shake()
					break
		State.SHAKE:
			_timer -= delta
			body.position = _start + Vector2(randf_range(-3.0, 3.0), randf_range(-1.0, 1.0))
			if warning:
				warning.modulate.a = 0.4 + 0.6 * absf(sin(_timer * 14.0))
			if _timer <= 0.0:
				state = State.FALL
				_vy = 0.0
				body.position = _start
				if warning:
					warning.visible = false
		State.FALL:
			_vy = minf(_vy + fall_gravity * delta, 1400.0)
			body.position.y += _vy * delta
			if body.position.y > _start.y + 3000.0:
				_break()
		State.BROKEN:
			if respawn_time > 0.0:
				_timer -= delta
				if _timer <= 0.0:
					_reset()


func _begin_shake() -> void:
	state = State.SHAKE
	_timer = shake_time
	Sfx.play("warning")
	if warning:
		warning.visible = true


func _on_body_hit(b: Node2D) -> void:
	if state != State.FALL:
		return
	if b is PlayerBase:
		var p := b as PlayerBase
		if lethal:
			p.kill("Crushed!")
		else:
			p.take_damage(damage, body.global_position, knockback, hazard_name)
		_break()
	elif b is StaticBody2D:
		_break()


func _break() -> void:
	state = State.BROKEN
	_timer = respawn_time
	body.visible = false
	body.set_deferred("monitoring", false)
	Fx.burst(self, body.global_position, debris_color, 14, 200.0, 0.6)
	Sfx.play("crash")


func _reset() -> void:
	state = State.IDLE
	body.position = _start
	body.visible = true
	body.modulate.a = 0.0
	body.set_deferred("monitoring", true)
	var tw := create_tween()
	tw.tween_property(body, "modulate:a", 1.0, 0.4)
