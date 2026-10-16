class_name Coin
extends Area2D
## Coin collected by touch. Can also fall from the sky (coin rain) and land.

@export var value: int = 1
@export var falling: bool = false
@export var fall_delay: float = 0.0
@export var fall_speed_max: float = 520.0

var _collected: bool = false
var _landed: bool = false
var _vy: float = 0.0
var _t: float = 0.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("coin")
	collision_layer = 16
	collision_mask = 2 | (1 if falling else 0)
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU
	if falling and fall_delay > 0.0:
		visible = false


func _physics_process(delta: float) -> void:
	_t += delta
	if falling and not _landed:
		if fall_delay > 0.0:
			fall_delay -= delta
			if fall_delay <= 0.0:
				visible = true
			return
		_vy = minf(_vy + 900.0 * delta, fall_speed_max)
		position.y += _vy * delta
		sprite.position.y = 0.0
		if position.y > 4000.0:
			queue_free()
	else:
		sprite.position.y = sin(_t * 3.0) * 4.0
	sprite.scale.x = absf(cos(_t * 2.0)) * 0.45 + 0.55


func _on_body_entered(body: Node2D) -> void:
	if _collected or not visible:
		return
	if body is PlayerBase:
		_collect()
	elif falling and body is StaticBody2D:
		_landed = true


func _collect() -> void:
	_collected = true
	GameState.add_coins(value)
	Sfx.play("coin", 0.08)
	Fx.burst(get_parent(), global_position, Color(1.0, 0.85, 0.2), 10, 140.0, 0.4)
	queue_free()
