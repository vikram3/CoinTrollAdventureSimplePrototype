class_name PinkGirl
extends CharacterBody2D
## Pink Girl: duels Big Boss on her own. Blocks his telegraphed attacks with
## her shield (which staggers him) and attacks between them. Never targets CT.

@export var boss_path: NodePath
@export var speed: float = 170.0
@export var attack_range: float = 120.0
@export var attack_damage: int = 1
@export var attack_interval: float = 1.1
@export var block_duration: float = 1.1
## Shield toss: when she blocks, she throws a friendly projectile back at Big Boss.
@export var shield_throw_scene: PackedScene
@export var shield_throw_damage: int = 2
@export var shield_throw_cooldown: float = 1.5
@export var gravity: float = 1900.0
@export var min_x: float = -100000.0
@export var max_x: float = 100000.0
@export var bubble_height: float = 70.0
@export_group("Lines")
@export var lines_block: PackedStringArray = ["Blocked.", "Not today.", "Is that all?"]
@export var lines_attack: PackedStringArray = ["Hah!", "Too slow, big guy.", "My turn."]
@export var lines_win: PackedStringArray = ["And stay down."]

var blocking: bool = false
var boss: BigBoss = null
var _block_timer: float = 0.0
var _attack_cd: float = 0.8
var _hurt_timer: float = 0.0
var _won: bool = false
var _talk_cd: float = 0.0
var _throw_cd: float = 0.0
var _picker := SpeechPicker.new()

@onready var sprite: Sprite2D = $Sprite
@onready var shield: Node2D = $Shield


func _ready() -> void:
	add_to_group("pink_girl")
	boss = get_node_or_null(boss_path) as BigBoss
	if boss:
		boss.defeated.connect(_on_boss_defeated)
	shield.visible = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 1100.0)
	_attack_cd -= delta
	_block_timer -= delta
	_hurt_timer -= delta
	_talk_cd -= delta
	_throw_cd -= delta
	var boss_alive := is_instance_valid(boss) and not boss.disabled
	if _won or not boss_alive:
		velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
		blocking = false
	elif _hurt_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		var dx := boss.global_position.x - global_position.x
		var dir := signf(dx)
		sprite.flip_h = dir < 0.0
		if boss.is_telegraphing():
			blocking = true
			_block_timer = block_duration
		if _block_timer <= 0.0:
			blocking = false
		if blocking:
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
		elif absf(dx) > attack_range:
			velocity.x = dir * speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
			if _attack_cd <= 0.0:
				_attack(dir)
	shield.visible = blocking
	var side := -1.0 if sprite.flip_h else 1.0
	shield.position.x = absf(shield.position.x) * side
	global_position.x = clampf(global_position.x, min_x, max_x)
	move_and_slide()


func _attack(dir: float) -> void:
	_attack_cd = attack_interval
	velocity.x = dir * 160.0
	boss.take_hit(attack_damage, global_position, self, "ally")
	Sfx.play("swing")
	if _talk_cd <= 0.0 and randf() < 0.4:
		_say(_picker.pick("attack", lines_attack))


## Called by Big Boss's waves. Returns true when the attack is blocked.
func receive_attack(_damage: int, from_position: Vector2) -> bool:
	if blocking:
		Sfx.play("block")
		if _talk_cd <= 0.0:
			_say(_picker.pick("block", lines_block))
		_throw_shield()
		return true
	_hurt_timer = 0.5
	var dir := signf(global_position.x - from_position.x)
	velocity = Vector2((dir if dir != 0.0 else -1.0) * 260.0, -200.0)
	sprite.modulate = Color(1.0, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	return false


## Shield toss: after a block, the shield flies back at Big Boss as a friendly shot.
func _throw_shield() -> void:
	if shield_throw_scene == null or _throw_cd > 0.0 or not is_instance_valid(boss):
		return
	_throw_cd = shield_throw_cooldown
	var shot := shield_throw_scene.instantiate() as Projectile
	if shot == null:
		return
	shot.hostile = false
	shot.damage = shield_throw_damage
	shot.shooter = self
	shot.direction = (boss.global_position - global_position + Vector2(0.0, -40.0)).normalized()
	shot.global_position = global_position + Vector2(0.0, -40.0)
	get_parent().add_child(shot)
	Sfx.play("swing")


func _on_boss_defeated(_enemy: EnemyBase) -> void:
	_won = true
	_say(_picker.pick("win", lines_win))


func _say(text: String) -> void:
	_talk_cd = 3.0
	SpeechBubble.say(self, text, 2.2, bubble_height)
