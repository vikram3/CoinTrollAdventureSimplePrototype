extends Node
## Global game state: level progress, coin count and scene flow.
## Autoloaded as "GameState".

signal coins_changed(value: int)
signal ability_unlocked(ability: String)

const SAVE_PATH := "user://coin_troll_levels.cfg"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CINEMATIC_SCENE := "res://scenes/cinematics/cinematic.tscn"

var current_level: int = 1
var coins: int = 0
var unlocked_level: int = 1
var best_coins: Dictionary = {}
var pending_cinematic: String = ""
var cinematic_next_level: int = 0
var show_end_card: bool = false
var coin_streak: int = 0
var difficulty: int = 1
## Moves CT has learned. Chapter 1 starts with none; the Chapter 2 tutorial and later levels grant them.
var abilities: Dictionary = {}

enum Difficulty { EASY, MEDIUM, HARD }
const DIFFICULTY_NAMES := ["Easy", "Medium", "Hard"]
var _last_pickup_ms: int = -100000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	load_progress()


# --- Abilities -------------------------------------------------------------

func has_ability(ability: String) -> bool:
	return abilities.has(ability)


func unlock_ability(ability: String) -> void:
	if abilities.has(ability):
		return
	abilities[ability] = true
	ability_unlocked.emit(ability)


# --- Coins -----------------------------------------------------------------

func reset_coins() -> void:
	coins = 0
	coin_streak = 0
	coins_changed.emit(coins)


## Counts coins picked up in a row (a gap of over 1.5 s starts a new run).
func next_coin_streak() -> int:
	var now := Time.get_ticks_msec()
	if now - _last_pickup_ms > 1500:
		coin_streak = 0
	_last_pickup_ms = now
	coin_streak += 1
	return coin_streak


func add_coins(amount: int = 1) -> void:
	coins += amount
	coins_changed.emit(coins)


## CT was hit: he loses 10% of his coins, rounded up so small purses still lose one. Returns how many were lost.
func lose_share_of_coins() -> int:
	if coins <= 0:
		return 0
	var lost := maxi(1, ceili(coins * 0.10))
	coins -= lost
	coins_changed.emit(coins)
	return lost


# --- Difficulty --------------------------------------------------------------

func difficulty_name() -> String:
	return DIFFICULTY_NAMES[difficulty]


func cycle_difficulty() -> void:
	difficulty = (difficulty + 1) % DIFFICULTY_NAMES.size()
	save_progress()


## Enemy movement speed multiplier.
func speed_mult() -> float:
	return [0.85, 1.0, 1.15][difficulty]


## Coin targets on coin-based levels.
func coin_target_mult() -> float:
	return [0.8, 1.0, 1.2][difficulty]


## Time limits and survive timers (Easy gets more time).
func timer_mult() -> float:
	return [1.3, 1.0, 0.8][difficulty]


## Hazard respawn and emitter intervals (Hard is busier).
func hazard_timer_mult() -> float:
	return [1.5, 1.0, 0.7][difficulty]


func enemy_health(base: int) -> int:
	match difficulty:
		Difficulty.EASY:
			return maxi(1, base - 1) if base >= 3 else base
		Difficulty.HARD:
			return base + 1
	return base


func enemy_contact_damage(base: int) -> int:
	if base <= 0:
		return base
	match difficulty:
		Difficulty.EASY:
			return maxi(1, base - 1) if base >= 2 else base
		Difficulty.HARD:
			return base + 1
	return base


# --- Flow ------------------------------------------------------------------

func new_game() -> void:
	unlocked_level = 1
	best_coins.clear()
	save_progress()
	# The intro plays first and then continues into level 01.
	pending_cinematic = "intro"
	cinematic_next_level = 1
	Transition.change_scene(CINEMATIC_SCENE, "")


func continue_game() -> void:
	start_level(unlocked_level)


func start_level(number: int) -> void:
	current_level = clampi(number, 1, StoryData.count())
	Transition.change_scene(_level_scene(current_level), _level_title(current_level))


func restart_level() -> void:
	Transition.change_scene(_level_scene(current_level), _level_title(current_level))


func complete_level(collected: int) -> void:
	var key := str(current_level)
	best_coins[key] = maxi(int(best_coins.get(key, 0)), collected)
	unlocked_level = clampi(maxi(unlocked_level, current_level + 1), 1, StoryData.count())
	save_progress()
	var cinematic: String = StoryData.cinematic_after(current_level)
	if cinematic != "":
		pending_cinematic = cinematic
		cinematic_next_level = current_level + 1
		Transition.change_scene(CINEMATIC_SCENE, "")
	else:
		_go_to_level_or_end(current_level + 1)


func cinematic_finished() -> void:
	pending_cinematic = ""
	_go_to_level_or_end(cinematic_next_level)


func go_to_main_menu() -> void:
	Transition.change_scene(MAIN_MENU_SCENE, "")


func _go_to_level_or_end(number: int) -> void:
	if number > StoryData.count():
		show_end_card = true
		go_to_main_menu()
	else:
		start_level(number)


func _level_scene(number: int) -> String:
	var info: Dictionary = StoryData.get_level(number)
	return str(info["scene"])


func _level_title(number: int) -> String:
	var info: Dictionary = StoryData.get_level(number)
	return "Level %02d\n%s" % [number, str(info["name"])]


# --- Save ------------------------------------------------------------------

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked_level)
	cfg.set_value("progress", "best_coins", best_coins)
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked_level = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, StoryData.count())
	difficulty = clampi(int(cfg.get_value("settings", "difficulty", 1)), 0, 2)
	var saved: Variant = cfg.get_value("progress", "best_coins", {})
	if saved is Dictionary:
		best_coins = saved


func get_best_coins(number: int) -> int:
	return int(best_coins.get(str(number), 0))


# --- Debug shortcuts (editor and debug builds only) ------------------------
## F3 skips the current level without completing it. F4 unlocks every level
## so any of them can be picked from the level select. Release builds ignore both.

## _input runs before any UI or gameplay node, so no other script can swallow these keys.
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F3:
		debug_skip_level()
	elif key.keycode == KEY_F4:
		debug_unlock_all()
	else:
		return
	get_viewport().set_input_as_handled()


## Short on-screen message so the shortcut is visible without the Output panel.
func _debug_toast(text: String) -> void:
	print("[debug] ", text)
	var layer := CanvasLayer.new()
	layer.layer = 100
	var label := Label.new()
	label.text = "DEBUG: " + text
	label.position = Vector2(24, 24)
	label.add_theme_font_size_override("font_size", 28)
	layer.add_child(label)
	get_tree().root.add_child(layer)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(layer.queue_free)


func debug_skip_level() -> void:
	var level := get_tree().get_first_node_in_group("level") as Level
	if level == null or level.finished:
		_debug_toast("F3 only works inside a level")
		return
	_debug_toast("skipping level %d" % current_level)
	level.finished = true
	complete_level(coins)


func debug_unlock_all() -> void:
	unlocked_level = StoryData.count()
	save_progress()
	_debug_toast("all levels unlocked")


# --- Input fallback --------------------------------------------------------
## The actions also live in project.godot. This only fills in anything missing,
## so the game still works if the input map gets reset in the editor.

func _ensure_input_actions() -> void:
	var defaults := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_K],
		"attack": [KEY_J, KEY_X, KEY_ENTER],
		"pause": [KEY_ESCAPE, KEY_P],
		"restart": [KEY_R],
	}
	for action: String in defaults.keys():
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for code in defaults[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_add_event(action, ev)
