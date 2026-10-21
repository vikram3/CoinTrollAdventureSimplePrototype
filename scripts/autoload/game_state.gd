extends Node
## Global game state: checkpoint progress, coin count and scene flow.
## Autoloaded as "GameState".

signal coins_changed(value: int)

const SAVE_PATH := "user://coin_troll_save.cfg"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CINEMATIC_SCENE := "res://scenes/cinematics/cinematic.tscn"

var current_checkpoint: int = 1
var coins: int = 0
var unlocked_checkpoint: int = 1
var best_coins: Dictionary = {}
var pending_cinematic: String = ""
var cinematic_next_checkpoint: int = 0
var show_end_card: bool = false
var coin_streak: int = 0
var _last_pickup_ms: int = -100000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	load_progress()


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


# --- Flow ------------------------------------------------------------------

func new_game() -> void:
	unlocked_checkpoint = 1
	best_coins.clear()
	save_progress()
	# The intro plays first and then continues into checkpoint 01.
	pending_cinematic = "intro"
	cinematic_next_checkpoint = 1
	Transition.change_scene(CINEMATIC_SCENE, "")


func continue_game() -> void:
	start_checkpoint(unlocked_checkpoint)


func start_checkpoint(number: int) -> void:
	current_checkpoint = clampi(number, 1, StoryData.count())
	Transition.change_scene(_checkpoint_scene(current_checkpoint), _checkpoint_title(current_checkpoint))


func restart_checkpoint() -> void:
	Transition.change_scene(_checkpoint_scene(current_checkpoint), _checkpoint_title(current_checkpoint))


func complete_checkpoint(collected: int) -> void:
	var key := str(current_checkpoint)
	best_coins[key] = maxi(int(best_coins.get(key, 0)), collected)
	unlocked_checkpoint = clampi(maxi(unlocked_checkpoint, current_checkpoint + 1), 1, StoryData.count())
	save_progress()
	var cinematic: String = StoryData.cinematic_after(current_checkpoint)
	if cinematic != "":
		pending_cinematic = cinematic
		cinematic_next_checkpoint = current_checkpoint + 1
		Transition.change_scene(CINEMATIC_SCENE, "")
	else:
		_go_to_checkpoint_or_end(current_checkpoint + 1)


func cinematic_finished() -> void:
	pending_cinematic = ""
	_go_to_checkpoint_or_end(cinematic_next_checkpoint)


func go_to_main_menu() -> void:
	Transition.change_scene(MAIN_MENU_SCENE, "")


func _go_to_checkpoint_or_end(number: int) -> void:
	if number > StoryData.count():
		show_end_card = true
		go_to_main_menu()
	else:
		start_checkpoint(number)


func _checkpoint_scene(number: int) -> String:
	var info: Dictionary = StoryData.get_checkpoint(number)
	return str(info["scene"])


func _checkpoint_title(number: int) -> String:
	var info: Dictionary = StoryData.get_checkpoint(number)
	return "Checkpoint %02d\n%s" % [number, str(info["name"])]


# --- Save ------------------------------------------------------------------

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked_checkpoint)
	cfg.set_value("progress", "best_coins", best_coins)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked_checkpoint = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, StoryData.count())
	var saved: Variant = cfg.get_value("progress", "best_coins", {})
	if saved is Dictionary:
		best_coins = saved


func get_best_coins(number: int) -> int:
	return int(best_coins.get(str(number), 0))


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
