extends Control
## Main menu: continue, new game, checkpoint select, controls, quit.

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var select_button: Button = %SelectButton
@onready var controls_button: Button = %ControlsButton
@onready var quit_button: Button = %QuitButton
@onready var main_buttons: Control = %MainButtons
@onready var select_panel: Control = %SelectPanel
@onready var controls_panel: Control = %ControlsPanel
@onready var grid: GridContainer = %CheckpointGrid
@onready var select_info: Label = %SelectInfo
@onready var end_card: Label = %EndCard
@onready var select_back_button: Button = %SelectBackButton
@onready var controls_back_button: Button = %ControlsBackButton


func _ready() -> void:
	get_tree().paused = false
	select_panel.visible = false
	controls_panel.visible = false
	end_card.visible = GameState.show_end_card
	GameState.show_end_card = false
	continue_button.text = "Continue  (Checkpoint %02d)" % GameState.unlocked_checkpoint
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
		var info := StoryData.get_checkpoint(n)
		b.disabled = n > GameState.unlocked_checkpoint
		b.tooltip_text = "%02d - %s" % [n, str(info["name"])]
		b.pressed.connect(_on_checkpoint_pressed.bind(n))
		b.focus_entered.connect(_show_info.bind(n))
		b.mouse_entered.connect(_show_info.bind(n))
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
	_show_info(GameState.unlocked_checkpoint)
	var first := grid.get_child(GameState.unlocked_checkpoint - 1) as Button
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
	var info := StoryData.get_checkpoint(n)
	var locked := n > GameState.unlocked_checkpoint
	var text := "%02d  %s" % [n, str(info["name"])]
	if locked:
		text += "\n(locked)"
	else:
		text += "\n\"%s\"" % str(info["trigger"])
		var best := GameState.get_best_coins(n)
		if best > 0:
			text += "\nBest: %d coins" % best
	select_info.text = text


func _on_checkpoint_pressed(n: int) -> void:
	Sfx.play("select")
	GameState.start_checkpoint(n)
