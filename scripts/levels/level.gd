class_name Level
extends Node2D
## Root script for every checkpoint scene. Each checkpoint has one objective;
## completing it shows the banner and moves to the next story beat.
## Failing restarts the checkpoint (not the story).

enum ObjectiveType { COINS, EXIT, COINS_OR_EXIT, COINS_AND_EXIT, SURVIVE, DEFEAT_COUNT, EVENT }

signal enemy_defeated(enemy: EnemyBase)
signal goal_touched

@export var checkpoint_number: int = 1
@export var checkpoint_name: String = "Checkpoint"
@export_multiline var trigger_line: String = ""
@export var objective_type: ObjectiveType = ObjectiveType.COINS
@export var coin_target: int = 0
@export var survive_seconds: float = 0.0
@export var defeat_target: int = 0
@export var objective_text_override: String = ""
@export_group("Rules")
## Camera limits for this checkpoint.
@export var level_bounds: Rect2 = Rect2(0, -800, 4000, 1520)
## Falling below this y counts as a fall (restart).
@export var kill_y: float = 1000.0
## Checkpoint 06: a knockback off the edge ends the checkpoint as a scripted fall.
@export var knockback_fall_completes: bool = false
@export var knockback_fall_source: String = "horn"
@export_group("Nodes")
@export var player_path: NodePath = ^"Player"
@export var tracker_path: NodePath

var player: PlayerBase = null
var hud: GameHUD = null
var pause_menu: PauseMenu = null
var complete_banner: CheckpointCompleteBanner = null
var tracker: ObjectiveTracker = null
var time_left: float = 0.0
var elapsed: float = 0.0
var defeats: int = 0
var reached_goal: bool = false
var finished: bool = false


func _enter_tree() -> void:
	add_to_group("level")


func _ready() -> void:
	get_tree().paused = false
	GameState.current_checkpoint = checkpoint_number
	GameState.reset_coins()
	if not GameState.coins_changed.is_connected(_on_coins_changed):
		GameState.coins_changed.connect(_on_coins_changed)
	player = get_node_or_null(player_path) as PlayerBase
	hud = get_node_or_null("HUD") as GameHUD
	pause_menu = get_node_or_null("PauseMenu") as PauseMenu
	complete_banner = get_node_or_null("CheckpointComplete") as CheckpointCompleteBanner
	if not tracker_path.is_empty():
		tracker = get_node_or_null(tracker_path) as ObjectiveTracker
	time_left = survive_seconds
	if player:
		player.died.connect(_on_player_died)
		player.health_changed.connect(_on_player_health_changed)
		_setup_camera()
	if hud:
		hud.pause_pressed.connect(_on_hud_pause_pressed)
		if player:
			hud.set_health(player.health, player.max_health)
	if tracker:
		tracker.setup(self)
	_refresh_hud()
	if trigger_line != "" and player:
		_say_trigger_line.call_deferred()


func _say_trigger_line() -> void:
	if player and not finished:
		player.say(trigger_line, 3.5)


func _setup_camera() -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_left = int(level_bounds.position.x)
	cam.limit_top = int(level_bounds.position.y)
	cam.limit_right = int(level_bounds.end.x)
	cam.limit_bottom = int(level_bounds.end.y)
	cam.reset_smoothing.call_deferred()


func _physics_process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	if objective_type == ObjectiveType.SURVIVE:
		time_left = maxf(time_left - delta, 0.0)
		if time_left <= 0.0:
			complete()
			return
	if player and player.global_position.y > kill_y:
		handle_fall()
		return
	_check_objective()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event.is_action_pressed("restart"):
		fail("")


# --- Objective ---------------------------------------------------------------

func _check_objective() -> void:
	if finished:
		return
	var coins: int = GameState.coins
	var done := false
	match objective_type:
		ObjectiveType.COINS:
			done = coin_target > 0 and coins >= coin_target
		ObjectiveType.EXIT:
			done = reached_goal
		ObjectiveType.COINS_OR_EXIT:
			done = reached_goal or (coin_target > 0 and coins >= coin_target)
		ObjectiveType.COINS_AND_EXIT:
			done = reached_goal and coins >= coin_target
		ObjectiveType.SURVIVE:
			done = reached_goal
		ObjectiveType.DEFEAT_COUNT:
			done = defeat_target > 0 and defeats >= defeat_target
		ObjectiveType.EVENT:
			done = tracker != null and tracker.is_complete()
	if done:
		complete()


func get_coin_target() -> int:
	match objective_type:
		ObjectiveType.COINS, ObjectiveType.COINS_OR_EXIT, ObjectiveType.COINS_AND_EXIT:
			return coin_target
		ObjectiveType.EVENT:
			return tracker.get_coin_target() if tracker else 0
	return 0


func get_objective_text() -> String:
	var text := ""
	match objective_type:
		ObjectiveType.COINS:
			text = "Collect %d coins" % coin_target
		ObjectiveType.EXIT:
			text = "Reach the exit"
		ObjectiveType.COINS_OR_EXIT:
			text = "Collect %d coins or reach the exit" % coin_target
		ObjectiveType.COINS_AND_EXIT:
			text = "Collect %d coins and reach the exit" % coin_target
		ObjectiveType.SURVIVE:
			text = "Survive %d s" % int(survive_seconds)
		ObjectiveType.DEFEAT_COUNT:
			text = "Defeat %d" % defeat_target
		ObjectiveType.EVENT:
			text = tracker.get_objective_text() if tracker else ""
	if objective_text_override != "":
		text = objective_text_override
	if objective_type == ObjectiveType.DEFEAT_COUNT:
		text += " (%d/%d)" % [mini(defeats, defeat_target), defeat_target]
	return text


func get_timer_value() -> float:
	if objective_type == ObjectiveType.SURVIVE:
		return time_left
	if objective_type == ObjectiveType.EVENT and tracker:
		return tracker.get_timer_value()
	return -1.0


func on_goal_reached() -> void:
	if finished:
		return
	if not reached_goal:
		reached_goal = true
		goal_touched.emit()
	if objective_type == ObjectiveType.COINS_AND_EXIT and GameState.coins < coin_target and player:
		player.say("Need %d more coins!" % (coin_target - GameState.coins), 2.0)
	_check_objective()


func register_enemy(enemy: EnemyBase) -> void:
	if not enemy.defeated.is_connected(_on_enemy_defeated):
		enemy.defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated(enemy: EnemyBase) -> void:
	if enemy.counts_for_objective:
		defeats += 1
	enemy_defeated.emit(enemy)
	_check_objective()


# --- Results -----------------------------------------------------------------

func handle_fall(message: String = "") -> void:
	if finished:
		return
	if knockback_fall_completes and player and player.was_recently_knocked_by(knockback_fall_source):
		if player:
			player.say("AAAAAH!", 1.5)
		complete()
		return
	fail(message if message != "" else "Waaah!")


func fail(message: String = "") -> void:
	if finished:
		return
	finished = true
	if player:
		player.set_controls_enabled(false)
		player.invincible = true
		player.shake_camera(10.0, 0.3)
		if message != "":
			player.say(message, 1.5)
	if hud:
		hud.announce("Restarting...")
	Sfx.play("hurt")
	await get_tree().create_timer(0.9).timeout
	GameState.restart_checkpoint()


func complete() -> void:
	if finished:
		return
	finished = true
	if player:
		player.set_controls_enabled(false)
		player.invincible = true
	Sfx.play("complete")
	if hud:
		hud.announce("Checkpoint complete!")
	_refresh_hud()
	await get_tree().create_timer(1.0).timeout
	if complete_banner:
		complete_banner.open(checkpoint_number, checkpoint_name, GameState.coins, get_coin_target())
	else:
		GameState.complete_checkpoint(GameState.coins)


func announce(text: String) -> void:
	if hud:
		hud.announce(text)


# --- HUD -----------------------------------------------------------------------

func _refresh_hud() -> void:
	if hud == null:
		return
	hud.set_coins(GameState.coins, get_coin_target())
	hud.set_objective(get_objective_text())
	hud.set_timer(get_timer_value())
	if player:
		hud.set_overlap_fade(player.get_global_transform_with_canvas().origin)


func _on_coins_changed(_value: int) -> void:
	_check_objective()
	_refresh_hud()


func _on_player_died() -> void:
	fail(player.death_message if player else "")


func _on_player_health_changed(current: int, maximum: int) -> void:
	if hud:
		hud.set_health(current, maximum)


func _on_hud_pause_pressed() -> void:
	if pause_menu and not finished:
		pause_menu.open()
