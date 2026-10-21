extends Control
## Main menu: continue, new game, level select, controls, quit.

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var select_button: Button = %SelectButton
@onready var controls_button: Button = %ControlsButton
@onready var quit_button: Button = %QuitButton
@onready var main_buttons: Control = %MainButtons
@onready var select_panel: Control = %SelectPanel
@onready var controls_panel: Control = %ControlsPanel
@onready var grid: GridContainer = %LevelGrid
@onready var select_info: Label = %SelectInfo
@onready var end_card: Label = %EndCard
@onready var select_back_button: Button = %SelectBackButton
@onready var controls_back_button: Button = %ControlsBackButton
var _difficulty_button: Button = null


func _ready() -> void:
	get_tree().paused = false
	select_panel.visible = false
	controls_panel.visible = false
	end_card.visible = GameState.show_end_card
	GameState.show_end_card = false
	continue_button.text = "Continue  (Level %02d)" % GameState.unlocked_level
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	select_button.pressed.connect(_open_select)
	controls_button.pressed.connect(_open_controls)
	quit_button.pressed.connect(_on_quit_pressed)
	select_back_button.pressed.connect(_close_panels)
	controls_back_button.pressed.connect(_close_panels)
	var n := 0
	for child in grid.get_children():
		var b := child as Button
		if b == null:
			continue
		n += 1
		var info := StoryData.get_level(n)
		b.disabled = n > GameState.unlocked_level
		b.tooltip_text = "%02d - %s" % [n, str(info["name"])]
		b.pressed.connect(_on_level_pressed.bind(n))
		b.focus_entered.connect(_show_info.bind(n))
		b.mouse_entered.connect(_show_info.bind(n))
	_difficulty_button = Button.new()
	_difficulty_button.name = "DifficultyButton"
	_difficulty_button.pressed.connect(_on_difficulty_pressed)
	main_buttons.add_child(_difficulty_button)
	main_buttons.move_child(_difficulty_button, select_button.get_index())
	_refresh_difficulty_button()
	continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (select_panel.visible or controls_panel.visible):
		_close_panels()
		get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
	Sfx.play("select")
	GameState.continue_game()


func _on_new_game_pressed() -> void:
	Sfx.play("select")
	GameState.new_game()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _open_select() -> void:
	Sfx.play("select")
	main_buttons.visible = false
	select_panel.visible = true
	_show_info(GameState.unlocked_level)
	var first := grid.get_child(GameState.unlocked_level - 1) as Button
	if first:
		first.grab_focus()


func _open_controls() -> void:
	Sfx.play("select")
	main_buttons.visible = false
	controls_panel.visible = true
	controls_back_button.grab_focus()


func _close_panels() -> void:
	select_panel.visible = false
	controls_panel.visible = false
	main_buttons.visible = true
	continue_button.grab_focus()


func _show_info(n: int) -> void:
	var info := StoryData.get_level(n)
	var locked := n > GameState.unlocked_level
	var text := "%02d  %s" % [n, str(info["name"])]
	if locked:
		text += "\n(locked)"
	else:
		text += "\n\"%s\"" % str(info["trigger"])
		var best := GameState.get_best_coins(n)
		if best > 0:
			text += "\nBest: %d coins" % best
	select_info.text = text


func _on_level_pressed(n: int) -> void:
	Sfx.play("select")
	GameState.start_level(n)


func _on_difficulty_pressed() -> void:
	Sfx.play("select")
	GameState.cycle_difficulty()
	_refresh_difficulty_button()


func _refresh_difficulty_button() -> void:
	if _difficulty_button:
		_difficulty_button.text = "Difficulty: %s" % GameState.difficulty_name()
