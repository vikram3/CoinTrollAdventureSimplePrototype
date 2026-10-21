class_name Coin
extends Area2D
## Coin collected by touch or pulled in by the magnet when CT gets close.
## Pickup: the coin pops and flashes, a chime climbs with every coin in a row,
## then a copy flies up to the coin counter and the counter bumps when it lands.
## Can also fall from the sky (coin rain) and land.

const MAGNET_RADIUS := 110.0
const MAGNET_START_SPEED := 420.0
const MAGNET_MAX_SPEED := 1500.0
const FLY_TIME := 0.42

@export var value: int = 1
@export var falling: bool = false
@export var fall_delay: float = 0.0
@export var fall_speed_max: float = 520.0
## Seconds before CT can pick this coin up (used for coins that spill out of CT).
@export var pickup_delay: float = 0.0
## Starting push for a falling coin: x sideways, y up (negative).
@export var drop_impulse: Vector2 = Vector2.ZERO
## If above 0, a falling coin lands this far below where it started, even with no floor (top-down levels).
@export var max_fall: float = 0.0

var _collected: bool = false
var _landed: bool = false
var _vy: float = 0.0
var _vx: float = 0.0
var _start_y: float = INF
var _t: float = 0.0
var _pull_speed: float = MAGNET_START_SPEED
var _player: Node2D = null

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("coin")
	collision_layer = 16
	collision_mask = 2 | (1 if falling else 0)
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU
	_vx = drop_impulse.x
	_vy = drop_impulse.y
	if falling and fall_delay > 0.0:
		visible = false


func _physics_process(delta: float) -> void:
	if _collected:
		return
	_t += delta
	if pickup_delay > 0.0:
		pickup_delay -= delta
	if falling and not _landed:
		if fall_delay > 0.0:
			fall_delay -= delta
			if fall_delay <= 0.0:
				visible = true
			return
		if _start_y == INF:
			_start_y = position.y
		_vy = minf(_vy + 900.0 * delta, fall_speed_max)
		_vx = move_toward(_vx, 0.0, 400.0 * delta)
		position.x += _vx * delta
		position.y += _vy * delta
		if max_fall > 0.0 and _vy > 0.0 and position.y >= _start_y + max_fall:
			_landed = true
			position.y = _start_y + max_fall
		sprite.position.y = 0.0
		if position.y > 4000.0:
			queue_free()
	else:
		sprite.position.y = sin(_t * 3.0) * 4.0
	sprite.scale.x = absf(cos(_t * 2.0)) * 0.45 + 0.55

	if visible and _update_magnet(delta):
		return


## Pulls the coin toward CT once she is close enough. Returns true if the coin was collected.
func _update_magnet(delta: float) -> bool:
	if pickup_delay > 0.0:
		return false
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return false
	var target := _player.global_position + Vector2(0, -20)
	var dist := global_position.distance_to(target)
	if dist > MAGNET_RADIUS and _pull_speed <= MAGNET_START_SPEED:
		return false
	_pull_speed = minf(_pull_speed + 2600.0 * delta, MAGNET_MAX_SPEED)
	global_position = global_position.move_toward(target, _pull_speed * delta)
	if global_position.distance_to(target) < 14.0:
		_collect()
	return true


func _on_body_entered(body: Node2D) -> void:
	if _collected or not visible:
		return
	if body is PlayerBase:
		if pickup_delay <= 0.0:
			_collect()
	elif falling and body is StaticBody2D:
		_landed = true


func _collect() -> void:
	if _collected:
		return
	_collected = true
	set_deferred("monitoring", false)
	var streak := GameState.next_coin_streak()
	var semitones := float(mini(streak - 1, 16))
	Sfx.play("chime", 0.02, pow(2.0, semitones / 12.0))
	Fx.burst(get_parent(), global_position, Color(1.0, 0.85, 0.2), 10, 140.0, 0.4)

	var canvas := get_viewport().get_canvas_transform()
	var start_screen := canvas * global_position
	var ghost_scale := sprite.global_scale * canvas.get_scale().x
	var tex := sprite.texture

	# Pop: scale up with a white flash, then shrink away.
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "self_modulate", Color(3.0, 3.0, 3.0, 1.0), 0.07)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_launch_fly.bind(start_screen, tex, ghost_scale))
	tw.tween_callback(queue_free)


func _launch_fly(start_screen: Vector2, tex: Texture2D, ghost_scale: Vector2) -> void:
	var hud := get_tree().get_first_node_in_group("hud") as GameHUD
	var layer := _fly_layer(get_tree().current_scene)
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.scale = ghost_scale
	ghost.position = start_screen
	layer.add_child(ghost)

	if hud == null:
		GameState.add_coins(value)
		ghost.queue_free()
		return

	var end_screen := hud.coin_screen_position()
	# Arc up and over toward the counter. The tween lives on the ghost, not on this coin,
	# because this coin is freed right after launching.
	var ctrl := Vector2((start_screen.x + end_screen.x) * 0.5, minf(start_screen.y, end_screen.y) - 120.0)
	var fly := ghost.create_tween()
	fly.tween_method(Coin._fly_step.bind(ghost, start_screen, ctrl, end_screen), 0.0, 1.0, FLY_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fly.tween_callback(Coin._arrive.bind(ghost, hud, end_screen, layer, value))


static func _fly_step(t: float, ghost: Sprite2D, a: Vector2, c: Vector2, b: Vector2) -> void:
	if not is_instance_valid(ghost):
		return
	var u := 1.0 - t
	ghost.position = u * u * a + 2.0 * u * t * c + t * t * b
	ghost.rotation = t * TAU * 2.0


static func _arrive(ghost: Sprite2D, hud: GameHUD, at: Vector2, layer: CanvasLayer, amount: int) -> void:
	GameState.add_coins(amount)
	if is_instance_valid(hud):
		hud.bump_coins()
	Sfx.play("coin", 0.03, 0.8)
	if is_instance_valid(layer):
		Fx.burst(layer, at, Color(1.0, 0.85, 0.2), 8, 120.0, 0.3)
	if is_instance_valid(ghost):
		ghost.queue_free()


static func _fly_layer(scene: Node) -> CanvasLayer:
	var layer := scene.get_node_or_null("CoinFlyLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "CoinFlyLayer"
		layer.layer = 9
		scene.add_child(layer)
	return layer
