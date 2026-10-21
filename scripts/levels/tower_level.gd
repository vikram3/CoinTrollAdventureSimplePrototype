class_name TowerLevel
extends Level
## Chapter 1 tower climb. When CT reaches the top ledge, the fat skull guard reaches down,
## pulls him onto the top platform, and once he reaches the top the tower crumbles before the level completes.

const HELP_RANGE_X := 460.0
const HELP_LINES := ["Need a hand? Come on, up you go!", "Hmph. Fine, grab on."]

var _helped: bool = false
var _collapsing: bool = false

@onready var _top: Node2D = get_node_or_null("Environment/TopPlatform") as Node2D
@onready var _guard: EnemyBase = get_node_or_null("Enemies/FatSkull") as EnemyBase


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _helped or _collapsing or finished or player == null or _top == null:
		return
	var p := player.global_position
	var near_top := absf(p.x - _top.global_position.x) < HELP_RANGE_X and p.y < _top.global_position.y + 60.0 and p.y > _top.global_position.y - 160.0
	if near_top and player.velocity.y >= -100.0:
		_helped = true
		_grab()


## The guard reaches down, CT grabs on, and he is hauled onto the top platform.
func _grab() -> void:
	var px := clampf(player.global_position.x, _top.global_position.x - 380.0, _top.global_position.x + 380.0)
	var landing := Vector2(px, _top.global_position.y - 50.0)
	var guard_rest := Vector2.ZERO
	player.set_controls_enabled(false)
	player.velocity = Vector2.ZERO
	Sfx.play("swing")
	if _guard and is_instance_valid(_guard):
		guard_rest = _guard.global_position
		_guard.disabled = true
		_guard.say_line(HELP_LINES, "help", 2.6, true)
		var reach := create_tween()
		reach.tween_property(_guard, "global_position", Vector2(px, landing.y - 90.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var pull := create_tween()
	pull.tween_property(player, "global_position", landing, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await pull.finished
	player.velocity = Vector2.ZERO
	if player and is_instance_valid(player) and not _collapsing and not finished:
		player.set_controls_enabled(true)
	if _guard and is_instance_valid(_guard):
		var back := create_tween()
		back.tween_interval(0.4)
		back.tween_property(_guard, "global_position", guard_rest, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await back.finished
		_guard.disabled = false


func on_goal_reached() -> void:
	if finished or _collapsing:
		return
	_collapse()


func _collapse() -> void:
	_collapsing = true
	if player:
		player.set_controls_enabled(false)
		player.invincible = true
		player.say("The tower is coming down!", 2.0)
		player.shake_camera(14.0, 1.6)
	Sfx.play("crash")
	var env := get_node_or_null("Environment")
	if env:
		var pieces: Array[Node2D] = []
		for c in env.get_children():
			if c is Node2D and (String(c.name).begins_with("Ledge") or String(c.name) == "TopPlatform" or String(c.name).begins_with("Wall")):
				pieces.append(c as Node2D)
		pieces.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y < b.position.y)
		var delay := 0.0
		for piece in pieces:
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_property(piece, "position:y", piece.position.y + 1000.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(piece, "modulate:a", 0.0, 1.0)
			delay += 0.05
	await get_tree().create_timer(1.6).timeout
	# CT ends up on the ground below the collapsed tower.
	if player and is_instance_valid(player):
		player.global_position = Vector2(800, 380)
		player.velocity = Vector2.ZERO
		player.set_controls_enabled(false)
		player.invincible = false
	await get_tree().create_timer(0.6).timeout
	super.on_goal_reached()
