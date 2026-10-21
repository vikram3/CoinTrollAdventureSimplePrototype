class_name EnemyBase
extends CharacterBody2D
## Shared enemy base: health, a disabled state on death, an invulnerable flag,
## contact damage and speech pools (idle, combat, defeat).

signal defeated(enemy: EnemyBase)
signal damaged(enemy: EnemyBase, amount: int)

@export var max_health: int = 1
@export var invulnerable: bool = false
@export var contact_damage: int = 1
@export var contact_knockback: Vector2 = Vector2(260, -260)
## Used by objectives (for example "tank", "speed", "projectile").
@export var enemy_type: String = "generic"
@export var counts_for_objective: bool = true
@export var use_gravity: bool = true
@export var gravity: float = 1900.0
@export var bubble_height: float = 60.0
@export var sprite_faces_right: bool = true
@export var edge_ray_ahead: float = 22.0
@export_group("Speech pools")
@export var lines_idle: PackedStringArray = []
@export var lines_combat: PackedStringArray = []
@export var lines_defeat: PackedStringArray = []

var health: int = 1
var disabled: bool = false
var facing: int = 1
## Colour the sprite returns to when it is not flashing from a hit.
var tint: Color = Color.WHITE

var _flash: float = 0.0
var _bark_cd: float = 0.0
var _picker := SpeechPicker.new()
var _edge_ray: RayCast2D = null

@onready var sprite: Node2D = get_node_or_null("Sprite") as Node2D
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox") as Area2D


func _ready() -> void:
	add_to_group("enemy")
	max_health = GameState.enemy_health(max_health)
	contact_damage = GameState.enemy_contact_damage(contact_damage)
	health = max_health
	var lvl := get_tree().get_first_node_in_group("level")
	if lvl and lvl.has_method("register_enemy"):
		lvl.call("register_enemy", self)


func _physics_process(delta: float) -> void:
	if _bark_cd > 0.0:
		_bark_cd -= delta
	_update_flash(delta)
	if _edge_ray:
		_edge_ray.position.x = edge_ray_ahead * facing
	if disabled:
		if use_gravity:
			apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		move_and_slide()
		return
	_enemy_process(delta)
	check_contact()
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	move_and_slide()


## Override in subclasses for behaviour. Movement is applied afterwards.
func _enemy_process(delta: float) -> void:
	if use_gravity:
		apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 1100.0)


## True when the player is on roughly the same floor. Enemies ignore a player standing on a
## ledge above them (or in a pit below), so they don't chase along underneath and get stuck.
func player_on_level(p: PlayerBase, tolerance: float = 50.0) -> bool:
	return p != null and absf(p.global_position.y - global_position.y) < tolerance


func get_player() -> PlayerBase:
	var p := get_tree().get_first_node_in_group("player") as PlayerBase
	if p and not p.is_dead and not p.is_hidden_now():
		return p
	return null


func ensure_edge_ray() -> void:
	if _edge_ray:
		return
	_edge_ray = RayCast2D.new()
	_edge_ray.target_position = Vector2(0, 70)
	_edge_ray.collision_mask = 1
	add_child(_edge_ray)


func at_edge() -> bool:
	return _edge_ray != null and is_on_floor() and not _edge_ray.is_colliding()


func take_hit(amount: int, from_position: Vector2, attacker: Node = null, kind: String = "melee") -> void:
	if disabled:
		return
	_flash = 0.15
	if invulnerable:
		Sfx.play("block")
		_on_blocked_hit(attacker, kind)
		return
	health -= amount
	Sfx.play("hit")
	damaged.emit(self, amount)
	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * 220.0
	if use_gravity:
		velocity.y = -180.0
	_on_hurt(amount, attacker, kind)
	if health <= 0:
		defeat()


func _on_blocked_hit(_attacker: Node, _kind: String) -> void:
	pass


func _on_hurt(_amount: int, _attacker: Node, _kind: String) -> void:
	say_line(lines_combat, "combat")


func defeat() -> void:
	if disabled:
		return
	disabled = true
	health = 0
	say_line(lines_defeat, "defeat", 2.0, true)
	collision_layer = 0
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	Sfx.play("defeat")
	defeated.emit(self)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func check_contact() -> void:
	if contact_damage <= 0 or hurtbox == null:
		return
	for body in hurtbox.get_overlapping_bodies():
		var p := body as PlayerBase
		if p and can_damage_player(p):
			if p.take_damage(contact_damage, global_position, contact_knockback, enemy_type):
				_on_hit_player(p)


func can_damage_player(_p: PlayerBase) -> bool:
	return true


func _on_hit_player(_p: PlayerBase) -> void:
	pass


func say_line(lines: PackedStringArray, pool: String, duration: float = 2.2, force: bool = false) -> void:
	if lines.is_empty():
		return
	if not force and _bark_cd > 0.0:
		return
	_bark_cd = 2.8
	SpeechBubble.say(self, _picker.pick(pool, lines), duration, bubble_height)


func face(dir: int) -> void:
	if dir == 0:
		return
	facing = 1 if dir > 0 else -1
	if sprite:
		var flip := (facing < 0) if sprite_faces_right else (facing > 0)
		sprite.set("flip_h", flip)


func _update_flash(delta: float) -> void:
	if sprite == null:
		return
	if _flash > 0.0:
		_flash -= delta
		sprite.modulate = Color(1.0, 0.35, 0.35)
	else:
		sprite.modulate = tint
