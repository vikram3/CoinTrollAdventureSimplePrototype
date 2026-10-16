class_name BossWave
extends Area2D
## Big Boss attack wave: the horizontal sword wave and the ground-slam shockwave.

@export var speed: float = 600.0
@export var lifetime: float = 1.6
@export var damage: int = 1
@export var knockback: Vector2 = Vector2(300, -320)

var direction: int = 1
var boss: BigBoss = null
var _hit: Array[Node] = []

@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2 | 64
	if sprite:
		sprite.flip_h = direction < 0


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if lifetime < 0.25:
		modulate.a = lifetime / 0.25
	for body in get_overlapping_bodies():
		if body in _hit:
			continue
		_hit.append(body)
		_hit_body(body)


func _hit_body(body: Node2D) -> void:
	var boss_ok := is_instance_valid(boss)
	if body is PlayerBase:
		if boss_ok and boss.ignore_player:
			return
		var p := body as PlayerBase
		if p.is_blocking_from(global_position):
			Sfx.play("block")
			return
		var from := global_position - Vector2(direction * 40.0, 0.0)
		if p.take_damage(damage, from, knockback, "big_boss") and boss_ok:
			boss.on_attack_hit(p)
	elif body.has_method("receive_attack"):
		if boss_ok and not body.is_in_group(boss.target_group):
			return
		var blocked: bool = body.call("receive_attack", damage, global_position)
		if boss_ok:
			if blocked:
				boss.on_attack_blocked()
			else:
				boss.on_attack_hit(body)
