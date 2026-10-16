class_name ShadowAvatar
extends EnemyBase
## Shadow avatar: a 2-second warning flash, then it teleports in with an
## explosion shockwave. It drifts toward CT and despawns after 8 seconds.

signal burst_finished(avatar: ShadowAvatar, hit_player: bool)

enum Phase { WARN, SHOCK, ALIVE, GONE }

@export var warning_time: float = 2.0
@export var life_time: float = 8.0
@export var shock_radius: float = 170.0
@export var shock_time: float = 0.45
@export var shock_damage: int = 1
@export var drift_speed: float = 58.5
@export var ring_texture_radius: float = 64.0

var phase: Phase = Phase.WARN
var _timer: float = 0.0
var _hit_player: bool = false

@onready var flash: Node2D = $WarningFlash
@onready var ring: Node2D = $Ring


func _ready() -> void:
	use_gravity = false
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_timer = warning_time
	if sprite:
		sprite.visible = false
	ring.visible = false
	flash.visible = true
	collision_layer = 0
	Sfx.play("warning")


func _enemy_process(_delta: float) -> void:
	_timer -= get_physics_process_delta_time()
	match phase:
		Phase.WARN:
			velocity = Vector2.ZERO
			flash.modulate.a = 0.35 + 0.65 * absf(sin(_timer * 9.0))
			flash.scale = Vector2.ONE * (0.6 + (warning_time - _timer) / warning_time * 0.6)
			if _timer <= 0.0:
				_arrive()
		Phase.SHOCK:
			velocity = Vector2.ZERO
			var k := 1.0 - clampf(_timer / shock_time, 0.0, 1.0)
			var radius := shock_radius * k
			ring.scale = Vector2.ONE * maxf(radius / ring_texture_radius, 0.05)
			ring.modulate.a = 1.0 - k * 0.6
			var p := get_player()
			if p and not _hit_player and global_position.distance_to(p.global_position) < radius + 16.0:
				_hit_player = true
				p.take_damage(shock_damage, global_position, Vector2(320, -300), "shadow")
			if _timer <= 0.0:
				ring.visible = false
				phase = Phase.ALIVE
				_timer = life_time
				collision_layer = 4
				burst_finished.emit(self, _hit_player)
		Phase.ALIVE:
			var p2 := get_player()
			if p2:
				velocity = (p2.global_position - global_position).normalized() * drift_speed
			else:
				velocity = Vector2.ZERO
			if _timer <= 0.0:
				_despawn()
		Phase.GONE:
			velocity = Vector2.ZERO


func can_damage_player(_p: PlayerBase) -> bool:
	return phase == Phase.ALIVE


func _arrive() -> void:
	phase = Phase.SHOCK
	_timer = shock_time
	flash.visible = false
	if sprite:
		sprite.visible = true
	ring.visible = true
	ring.scale = Vector2.ONE * 0.05
	Sfx.play("boom")
	var p := get_player()
	if p:
		p.shake_camera(6.0, 0.2)


func _despawn() -> void:
	phase = Phase.GONE
	disabled = true
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
